# Code Review Override Log

This file records **overrides** of the code-review pipeline's verdicts.
An override is any case where a human reviewer or author downgraded a
🔴 Must-Fix to 🟢/Won't-Fix, promoted a 🟢 Consider (Nit) to 🟡/🔴, or
otherwise contradicted the automated rubric. One row kind is machine-written:
an `Accepted-immutable` row, which the `code-review` orchestrator appends
without a human decision when a fact-check finds a claim wrong in history no
new commit can edit (see *Accepted-immutable rows* below). The point of
capturing these is twofold:

1. **Calibration.** Over time the entries here reveal where the pipeline is
   too noisy (frequent Must-Fix → Won't-Fix on a particular finding category)
   or too lenient (frequent Nit → Must-Fix). That feeds critic skill tuning.
2. **Consistency.** Future runs of `code-review` MUST consult this log
   before rendering findings. If a prior override applies to a finding in
   the current diff (same location, same category, or substantively the
   same claim), the orchestrator surfaces the considered override in its
   output so reviewers see the history rather than re-arguing the same
   call.

## Capture format

Each override is one row in the table below. Required fields:

| Field | Meaning |
|---|---|
| `Date` | ISO date the override was applied (YYYY-MM-DD). |
| `PR ref` | PR number, commit hash, or branch where the override originated. Use `#N` for GitHub PRs, short SHA otherwise. |
| `Finding` | One-line summary of the finding. Include `path/to/file:line` location so future matches can be detected by file/line proximity. Quote the original wording where possible. |
| `Original verdict` | What the pipeline produced — `🔴 Must-Fix`, `🟡 Must-Address`, `🟢 Consider`, or `Nit` (informal Consider-tier wording). For an `Accepted-immutable` row only: `Fact-check Incorrect` (the finding never received a tier). |
| `Override verdict` | What the human decided — `Won't-Fix`, `Defer`, `🟡 Must-Address`, `🔴 Must-Fix`, etc. — or `Accepted-immutable` for the machine-written kind. Use the same vocabulary as `Original verdict` where applicable. |
| `Reason` | Why the human deviated. Be specific enough that a future reader can decide whether the reasoning still applies (e.g., "test-only file, internal-use", "deprecated module — rewrite scheduled in #482", "stylistic Nit; team prefers verbose form here"). |

**`Accepted-immutable` rows (machine-written).** A fact-check Incorrect about
a claim in an already-merged commit message, or any artifact no new commit can
edit, is not tiered (the immutable-history exception in
`skills/code-review/references/rubric.md`, *Unified Severity Mapping*). The
orchestrator appends a row with `Original verdict: Fact-check Incorrect` and
`Override verdict: Accepted-immutable` during the run; it is the only row kind
written without a human decision, and no other verdict is ever written
automatically. The `Reason` cell starts with `[auto: code-review]` followed by
the immutable artifact, and `PR ref` names the run's PR or branch. Step 3.5
treats these rows like a settled `Won't-Fix`: the same immutable claim is not
re-raised. Older `Accepted-immutable` rows below that lack the `[auto: …]`
prefix were written by hand before the kind was formalized. The canonical
definition is `skills/code-review/references/override-log.md#capture-format`.

Keep rows short. If a rationale needs more than ~30 words, link to a PR
comment, decision record, or `docs/decisions/NNN-*.md` from the `Reason`
cell rather than expanding the row.

## How `code-review` uses this log

On every run, the `code-review` skill scans this file as part of its
preamble (see `skills/code-review.md` Step 3.5 — "Scan the override log
for prior decisions matching the current diff"). Any entry whose
`Finding` location or category overlaps the current diff is held as a
*considered override* and surfaced in both the chat synthesis (under
`### Considered overrides`) and the structured rubric (in the affected
row's `Author note` / `Considered overrides` column). This prevents the
log from being write-only and forces reviewers to engage with prior
calls rather than silently re-arguing them.

If no prior override matches, the rendered output explicitly states so —
silent absence is not allowed, otherwise readers cannot distinguish
"checked and found nothing" from "forgot to check."

## Entries

<!--
Add new entries at the top so the most recent decisions are easiest to
scan. Preserve the column order. If a finding came from a critic other
than the core trio (e.g., ui-visual-review), name the critic in the
`Finding` cell so domain filters work later.
-->

| Date | PR ref | Finding | Original verdict | Override verdict | Reason |
|---|---|---|---|---|---|
| 2026-09-21 | `answers-2026-09-20` | iter2 N2: `hooks/guard-trusted-writes.py:190-205` Bash writes still ungated for bare `cd; echo > CLAUDE.md`, `/home/$USER/CLAUDE.md`, globbed/quoted `.claude` names, `/opt/claude-workflows/hooks/…`, whole-tree `cp -r …/. ~/.claude/` and `rsync` (security; predates this branch). | 🟡 Must-Address | Defer | Pre-existing, outside the Q-026/Q-035 scope. Discoverable TODO: `# TODO(N2)` block beside the Bash indicators (a577546) lists each shape and the suggested direction. Revisit trigger: the next change to the Bash tiers, or Q-048's answer. |
| 2026-09-21 | `answers-2026-09-20` | iter2 N3: deny rules in `hooks/wiring.json:120-127` render as `Edit(/home/node/.claude/…)`; if Claude Code reads a single leading `/` as settings-relative, they match nothing (security; unverified; predates this branch). | 🟡 Must-Address | Defer | Needs a host check the sandbox can't run. Tracked as Q-049 in `docs/working/questions.md` with a paste. Revisit trigger: Q-049's answer. |
| 2026-09-21 | `answers-2026-09-20` | iter2 A6 remainder: the run-id charset `^[A-Za-z0-9._-]+$` is copied in `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh` and `scripts/lib/si-morning-summary.sh` `_valid_run_id` (architecture/tech-debt). | 🟡 Must-Address | Defer | All three copies are identical and tested; the collision and traversal halves of A6 are fixed (14bfbdd, efd66e4, 818c568). Revisit trigger: any change to the run-id format, or a fourth reader of the Run cell. |
| 2026-09-21 | `answers-2026-09-20` | Commit `c5a7c96` message: "Tests: 18 new bats cases … every new R-test fails against the pre-fix hook" — fact-check Incorrect (high), iter2 Claims 2–3, k=3 unanimous. Real: 14 new `@test` blocks; 4 (tests 39, 40, 43, 49) pass on `c5a7c96^` (`test/hooks/guard-trusted-writes.bats:301-456`). | Fact-check Incorrect | Accepted-immutable | [auto: code-review] commit c5a7c96 (merged into the branch via 1759fc8) miscounts its tests and overstates their pre-fix failure; cannot be edited without a history rewrite. |
| 2026-09-21 | `answers-2026-09-20` | Commit `c5a7c96` message: R1 "no longer depends on exact path spellings" and "The residual: shell obfuscation of the file name itself … and A8 primitives" — fact-check Incorrect (high), iter2 Claim 1, k=3 unanimous; code `hooks/guard-trusted-writes.py:190-205`. | Fact-check Incorrect | Accepted-immutable | [auto: code-review] commit c5a7c96 understates the residual (bare `cd`, `/home/$USER`, obfuscated `.claude` dir, quoting inside names, `/opt` payload); cannot be edited. Live gap is N2 in `code-review-rubric-2026-09-21-answers-2026-09-20-iter2.md`. |
| 2026-09-21 | `answers-2026-09-20` | A8: `hooks/guard-trusted-writes.py` WRITE_PRIMITIVE does not recognise `ln -sf`, `curl -o`, `wget -O`, `tar -C`, `unzip -d`, `sponge`, `python3 script.py`, `git checkout`, `git config --global` as writes (security, predates the diff). | 🟡 Must-Address | Defer | Pre-existing gap outside this branch's scope (the Q-026/Q-035 answers). Discoverable TODO: `# TODO(A8)` at WRITE_PRIMITIVE lists every command. Revisit trigger: the next change to WRITE_PRIMITIVE, or any live bypass seen via one of these commands. |
| 2026-09-21 | `answers-2026-09-20` | A7: `~/.claude/scripts/` exposes all of `scripts/`, which mixes four ways of locating the repo root; only `lite-review.py` and `questions.sh` are meant to run from other projects (architecture). | 🟡 Must-Address | Defer | Linking the whole directory matches how `link-claude-home.sh` already installed it; the two helpers meant for other projects are the ones fixed and tested (questions.sh resolves from `$PWD`, lite-review takes `--repo`). Revisit trigger: a third `scripts/` helper is documented for use from other projects, or a script run from `~/.claude/scripts` is found writing into claude-workflows instead of the calling project. |
| 2026-09-21 | `answers-2026-09-20` | Commit `4c7a2bb` message: "Global paths are unchanged" (and "matching wiring.json") — fact-check Incorrect (high), Claim 6, r1+r2 Incorrect, r3 Mostly accurate. Refuted at `hooks/guard-trusted-writes.py:56-132` as of `4c7a2bb`: the Bash HARD tier for the global CLAUDE.md now matches only literal spellings, and nested/`..`/symlinked global paths moved HARD→SOFT. | Fact-check Incorrect | Accepted-immutable | [auto: code-review] merged commit 4c7a2bb message misstates that global path handling is unchanged; cannot be edited. The defects it hid were R1/R4 in `code-review-rubric-2026-09-21-answers-2026-09-20.md`, fixed in `c5a7c96`. |
| 2026-09-12 | `cb5351d` | `skills/ui-visual-review/SKILL.md:58` kept a `## Mandatory Execution Rules` block after prompt-audit F3 rewrote the same-named blocks in the three orchestrators — flagged by api-consistency (naming table) and test-strategy (G13/T9). | 🟢 Consider | Heading renamed; rule body exempt from F3 | Critic, not orchestrator: the five rules are distinct domain guidance, not one contract inflated into MUST-rules, and the block carries none of F3's markers (no absolute-rules preamble, no MUST/No-exceptions, no later restatement). Heading renamed to `## Execution rules` for consistency; prose rewrite declined. |
| 2026-09-12 | `59ca38f` | "All 85 tests across the code-review suites pass" — fact-check Incorrect (high), k=3 unanimous. Real count: 97 across the seven `test/skills/code-review-*.bats` suites, 53 across the four this commit modified. | 🟡 Must-Address | Accepted-immutable | Claim lives in a merged commit message; no new commit can edit it. The editable copy at `docs/reviews/prompt-audit-2026-09-11.md` was corrected. Logged so the miscount is not re-raised as a live finding. |
| 2026-09-12 | `c56be81` | "health-check failures are identical to the pre-change baseline (four, all pre-existing)" — fact-check Incorrect (high), r1+r3. Real count: six (four shellcheck + two MD-consistency). The identity and all-pre-existing halves are both confirmed. | 🟡 Must-Address | Accepted-immutable | Same reason: immutable commit message. The two omitted failures were fixed on 2026-09-12, so the number is now moot as well as unfixable. |
| 2026-06-23 | `feat/batch-feedback-subagent-routing` (#35) | Hook fires on every UserPromptSubmit incl. agent/tool notifications (`hooks/batch-feedback-routing-reminder.sh`, whole script) — security-reviewer Low + orchestrator observation (C1) | 🟢 Consider | Won't-Fix (intended) | Reminder targets the model not the human (no alert-fatigue); non-human submits are valid fan-out points; cost ~85 tok/firing. Broad firing preferred. |
| 2026-09-24 | `skill-fixtures` | CLAUDE_FLAGS/CLAUDE_MODEL passed word-split and unvalidated into claude argv (`test/skills/generate-reports.bash:201-202`) — security-reviewer F5 (C4) | 🟢 Consider | Won't-Fix (intended) | Operator-controlled env on the operator's own machine; the allowlist governs runners, not the person running the script. Revisit if generate-reports ever runs from CI or another untrusted caller. |
| 2026-09-24 | `skill-fixtures` | Eval check-name drift: `subagents_min` vs `min_claims`, two meanings of `_match`, leading-word vs whole-line matching, `None`/`none` placeholder case (`test/skills/eval-helpers.bash`) — api-consistency #2-#5 (C5) | 🟢 Consider | Deferred | Renames touch 22 expected-verdicts files and no report has been generated yet; do it with the first calibration pass (plan-skill-fixtures.md), when a mismatch would actually misscore. |
| 2026-09-24 | `skill-fixtures` | Fixture sets depend on live repo files (workflows/divergent-design.md, docs/evaluation-rubric.md, personas.md) with no declared dependency or provenance hash (`test/skills/divergent-design/runner.bash:19`) — architecture-review F3 (C7) | 🟢 Consider | Deferred | Live-file coupling is intended (fixtures test the current rubric/workflow). Revisit when reports are first compared across time: record the file hashes next to each report then. |
| 2026-09-24 | `skill-fixtures` | `generate_one` width (three modes + transcript) — tech-debt-triage D2 (C8) | 🟢 Consider | Partially fixed | The duplicated claude pipeline and the fact-check-only summary line were fixed in a75ba3e; the remaining ~90-line function is left as is. Revisit if a fourth mode is added. |
| 2026-09-24 | `skill-fixtures` | Once any report exists, all 22 eval suites join the --fast gate and each format_check spawns a nested bats, ~20 s extrapolated (`test/skills/eval-helpers.bash:134-137`) — performance-reviewer F2 (C9) | 🟢 Consider | Deferred | Unmeasured; no reports exist yet. Revisit trigger: the first --fast run with reports present exceeds the current 128 s by more than 15 s. |
| 2026-09-24 | `skill-fixtures` | Misc minors: format defined in three places, 22 near-duplicate runners, overlapping assert helpers, hard-coded title windows, redundant `${REPORT_PATH:-}`, field_values loosening assert_verdict — architecture F4, tech-debt D4-D6, api #10-#11 (C11) | 🟢 Consider | Won't-Fix (carry) | Each critic itself rated these carry/defer; none misscores a fixture today. |
| 2026-09-24 | `skill-fixtures` | Runners are sourced into the generator's global scope and could overwrite OUTPUT_DIR/FIXTURE_DIR (`test/skills/generate-reports.bash`) — architecture-review F2, remainder after a75ba3e (C6) | 🟡 Must-Address | Acknowledged | a75ba3e moved runners onto REPO_ROOT and validates every committed runner in a fast test; subshell isolation of `source` was not done because fixture_base/fixture_prompt must run in the generator's scope. Revisit if a runner ever needs to set a variable the generator also uses. |
| 2026-09-24 | `skill-fixtures` | `trap ... RETURN` does not run when set -e aborts inside generate_one, so the temp dir is left behind (`test/skills/generate-reports.bash:161`) — pass-2 fact-check finding 2 / security note | 🟢 Consider | Won't-Fix (intended) | The leftover dir holds only fixture copies under /tmp, and an abort already fails the run loudly. Revisit if fixtures ever hold anything sensitive. |
| 2026-09-24 | `skill-fixtures` | `--tools` is variadic, so a bare word right after it in CLAUDE_FLAGS would be read as a tool name (`test/skills/generate-reports.bash:152`) — pass-2 fact-check finding 3 | 🟢 Consider | Won't-Fix (intended) | Operator-controlled input, same call as the C4 row above. |
| 2026-09-24 | `skill-fixtures` | `RUNNER_ALLOWED_TOOLS` and `*_runner_settings` govern the `FIXTURE_*` variables, a naming mismatch (`test/skills/runner-contract.bash`) — pass-2 api-consistency #5 | 🟢 Consider | Won't-Fix | The contract file's name scopes it; a rename would churn 22 runners for no behavior change. |
| 2026-09-25 | `ans/copy-install` (q058 re-review) | fa69656 commit Notes: a vis failure at the other `\| vis` sites "fails in review_diff too" — only the MODE lines reach review_diff; the host MOVE/REPLACE/ADD lines exit silently via set -e/pipefail (`devcontainer-config/install.sh:600-654`), still fail-closed — merged fact-check Claims 10a/10b | Fact-check Incorrect | Accepted-immutable | [auto: code-review] commit fa69656 message misstates where non-review_diff vis failures are caught; merged into answers-2026-09-20 and skill-fixtures, cannot be edited. The behavior itself is tracked as rubric C3. |
| 2026-09-25 | `skill-fixtures` (q058 re-review pass 4) | f5e3029 commit body: a find failure in links_in is turned by "every caller … into the existing symlink refusal, with its message" — at `$DEST` with a non-empty unreadable dir, `dc_unwind`'s own `rm -rf` failed under set -e and the run exited with no ERROR line (`devcontainer-config/install.sh:437`) — pass-4 fact-check Claim 14b | Fact-check Incorrect | Accepted-immutable | [auto: code-review] commit f5e3029 message overstates the refusal path; cannot be edited. The behavior is fixed by the best-effort dc_unwind (T86). |
| 2026-09-27 | `integrate/q077-q078-q080` | Hook treats `Bash(*)` and `Bash(**)` the same (`hooks/auto-approve-allowed-commands.sh` add_deny_rule) although Claude Code distinguishes them (log 56) — api-consistency F2 | 🟢 Consider | Won't-Fix (intended) | On the deny side both mean "deny everything"; treating them alike only errs toward prompting. |
| 2026-09-27 | `integrate/q077-q078-q080` | `--deny` pairs with `--permissions`, and an empty value means "none" for `--deny` but "read settings" for `--permissions` (`hooks/auto-approve-allowed-commands.sh` option parsing) — api-consistency F3/F4 | 🟢 Consider | Won't-Fix | Both options are test-only; renaming would churn every test for no production effect. |
| 2026-09-27 | `integrate/q077-q078-q080` | The "not this — use X" line is phrased five different ways across `skills/*/SKILL.md` descriptions; some pointers are one-way — api-consistency F5/F7 | 🟢 Consider | Defer | Q-073 answer [1] excluded de-overlap; unifying phrasing is follow-up polish. Revisit with any de-overlap pass. |
| 2026-09-27 | `integrate/q077-q078-q080` | pre-mortem and what-if-analysis keep `## When to Use This Skill (vs. …)` so `grep '^## When to use'` misses them (`skills/pre-mortem/SKILL.md`, `skills/what-if-analysis/SKILL.md`) — api-consistency F8 | 🟢 Consider | Defer | Cosmetic; nothing greps for the heading today. |
| 2026-09-27 | `integrate/q077-q078-q080` | The new description shape (purpose first, routing line by char 250, 364–426 chars) is not enforced by `scripts/health-check.sh:132`; `when:` is a stale third copy — architecture-review 7; tech-debt 3 (no check that description trigger phrases also appear in the body) | 🟢 Consider | Defer | Worth a health-check warning in a follow-up; not needed for this merge. |
| 2026-09-27 | `integrate/q077-q078-q080` | No pinning test for the documented `Bash(rm *)` vs bare `rm` divergence (`hooks/auto-approve-allowed-commands.sh` header KNOWN DIVERGENCE) — tech-debt, api-consistency | 🟢 Consider | Defer | No deny rule in the repo uses that form; add the test when Q-082 settles Claude Code's semantics. |
| 2026-09-27 | `integrate/q077-q078-q080` | A FIFO or /dev/zero at a settings path hangs the hook until timeout (`hooks/auto-approve-allowed-commands.sh` read_settings_rules, `-e` test) — security re-review F3 (Informational) | 🟢 Consider | Won't-Fix (intended) | A hung hook never approves, so it fails safe. |
| 2026-09-27 | `integrate/q077-q078-q080` | The hook re-implements part of Claude Code's permission engine, justified only if a hook `allow` overrides `permissions.deny` (#39344 shows it for `ask`) — architecture-review 1 | 🟡 Must-Address | Acknowledged | Header now calls the deny check load-bearing in cc-isolated until the host check in Q-082 settles it; if deny wins, delete the hook's deny reader. |
| 2026-09-27 | `integrate/q077-q078-q080` | In cc-isolated a determined injection still spells past the credentials rule (glob `.cred*`, earlier-set variable, brace/ANSI-C forms) — security review F5 | 🟡 Must-Address | Acknowledged | Documented as residuals in the hook header and log 53; the real fix is the sandbox half, filed as Q-081. |
| 2026-09-27 | `01c40eb` | Commit message: "8 edits in 30 days staled every skill's reports" — fact-check Mostly accurate: stamps only arrived with 48680e2, the last of the 8 | 🟡 Must-Address | Accepted-immutable | [auto: code-review] Commit message; history not rewritten. |
| 2026-09-27 | `integrate/q076` | With `--yes` and no `--branch`, the checkout's HEAD picks the pushed branch (`devcontainer-config/cc-push.sh` main) — security confirm N2 | 🟢 Consider | Won't-Fix (documented) | Requiring --branch broke six tests that exercise HEAD selection; the preview is still printed and the guide's limits list says to pass --branch when scripting. |
| 2026-09-27 | `integrate/q076` | A bare-layout repository in a working-tree directory not named `.git` is not walked by the exit scan (`devcontainer-config/cc-exit-scan.sh` embedded-repo search) — fact-check r3 C10a | 🟢 Consider | Defer (documented limit) | Discovery by looks_like_gitdir adds per-repo cost and raises how global config applies to bare dirs; the scan is a tripwire, cc-push is the safe path. |
| 2026-09-27 | `integrate/q076` | Scan cost grows with embedded repos/hooks (~29 ms each) and one unlistable directory blocks the scan (`devcontainer-config/cc-exit-scan.sh`) — performance 3, 4 | 🟢 Consider | Defer (documented limit) | Fail-closed by design; numbers are in the guide. Revisit if a real checkout exceeds ~10 s per snapshot. |
| 2026-09-27 | `integrate/q076` | The scan reads `commondir`'s first line itself instead of via cc-gitdir.sh (`devcontainer-config/cc-exit-scan.sh`) — architecture 2 remainder, security confirm N4 | 🟡 Must-Address | Acknowledged | Only matters for a state already present at launch, which launch_gitdir_ok now refuses; fold into cc-gitdir.sh at the next scan change. |
| 2026-09-27 | `integrate/q076` | Host-only tools are hashed as container-boundary enforcement files (manifest, live-verify gate) — architecture 3 | 🟡 Must-Address | Defer | User deferred at the fix batch; tracked as Q-083. |
| 2026-09-28 | `feat/u4-code-review-skill` | A second standalone review of a branch finds a canonical rubric with no `Loop closed at` line and is classed as a loop final pass, so it runs k=1 instead of k=3 (`skills/code-review/SKILL.md` Stage 1 replication) — fact-check iter3 claim 10 | 🟢 Consider | Defer | Standalone re-reviews of a branch that already has a rubric are rare, and k=1 is the value decision 031 already accepts for loop passes. Revisit if Q-087 raises the final pass to k=3. |
