# Running questions — archive

Answered entries, moved out of `docs/working/questions.md` by
`scripts/questions.sh archive` so the live file stays short enough to read in
full. IDs are stable forever: `Q-014` means the same thing here as it did there.

## Index

<!-- index:start -->
| ID | Question | Opened |
|---|---|---|
| [Q-001](#q-001--install-sh-missing-payload-fatal) | Should a missing `install.sh` payload source be **fatal** rather than warn-and-continue? **Answered 2026-09... | 2026-09-12 |
| [Q-002](#q-002--install-sh-bless-prompt-eof) | Should `install.sh`'s bless prompt survive a closed stdin? **Answered 2026-09-12: yes — shipped as the on... | 2026-09-12 |
| [Q-003](#q-003--ui-visual-review-mandatory-rules) | Was the surviving `## Mandatory Execution Rules` block at `skills/ui-visual-review/SKILL.md:58` left out of... | 2026-09-12 |
| [Q-004](#q-004--code-review-reference-split) | Re-cut the reference split — `severity.md` (read at Stage 1.5/2.5) vs `rubric.md` (template, read at Stag... | 2026-09-12 |
| [Q-005](#q-005--bats-skill-content-helper) | Should the `.bats` `SKILL_CONTENT` concat idiom move into `test/skills/helpers.bash`? **Done 2026-09-12** ... | 2026-09-12 |
| [Q-006](#q-006--openrouter-sonnet5-judge-pin) | Confirm `anthropic/claude-sonnet-5` resolves on OpenRouter before the next cross-model run. **Answered 2026... | 2026-09-12 |
| [Q-007](#q-007--cross-model-judge-unpriced-abort) | Should an unpriced/unknown `--judge` id **abort** `cross-model-review.py` pre-flight, the way an unpriced `... | 2026-09-12 |
| [Q-008](#q-008--findings-grammar-ownership) | Make `lite-review.py` the definition of the FINDINGS grammar rather than a copy of it, before `cross-model-... | 2026-09-12 |
| [Q-009](#q-009--live-verify-gate-not-installed) | The installed-ness pin is a new test in `test/hooks/live-verify-gate.bats` that reads | 2026-09-12 |
| [Q-010](#q-010--elan-release-host) | Which host does elan actually fetch toolchains from — `release.lean-lang.org` or `releases.lean-lang.org`? | 2026-09-12 |
| [Q-011](#q-011--mathlib-cache-host) | What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.) | 2026-09-12 |
| [Q-012](#q-012--elan-sha256-pins) | Pin the per-arch SHA-256 of the elan release as build ARGs | 2026-09-12 |
| [Q-013](#q-013--elan-version-to-ship) | Is `ELAN_VERSION=v3.1.1` the version to ship? **ANSWERED 2026-09-15: no — `v4.2.4`, taken from the GitHub... | 2026-09-12 |
| [Q-014](#q-014--profile-replace-only) | Should `--profile` stay replace-only, or grow `--add-profile`/`--remove-profile`? | 2026-09-15 |
| [Q-015](#q-015--scholar-hostnames) | Confirm the three `scholar` hostnames that no search summary covered — `pmc.ncbi.nlm.nih.gov`, `api.biorx... | 2026-09-17 |
| [Q-016](#q-016--scholar-oa-escape-hatch) | Does `scholar` need a companion escape hatch for publisher-hosted OA PDFs? | 2026-09-17 |
| [Q-017](#q-017--rpi-doc-zero-reads) | `workflows/research-plan-implement.md` — the documented default — was opened **0 times in 49 days** (27... | 2026-09-17 |
| [Q-018](#q-018--failure-patterns-backfill) | `docs/thoughts/failure-patterns.md`: backfill from the 104 eligible `fix(...)` commits, or delete the file? | 2026-09-17 |
| [Q-019](#q-019--worktree-cleanup) | Reclaim the 231 MB under `.claude/worktrees/` — the git half is done, the disk half is a plain `rm -rf` I... | 2026-09-17 |
| [Q-020](#q-020--asks-unit-weighting) | Is `asks` (triage §3.3) the right unit, or does it undercount one hard judgment against several easy ones? | 2026-09-17 |
| [Q-021](#q-021--drop-delete-or-archive) | Should DROP items be deleted or archived? | 2026-09-17 |
| [Q-022](#q-022--lite-review-findings-invariant) | ~nothing.** Read as: A5 is not a defect worth a fix — a clean lite review's only | 2026-09-17 |
| [Q-023](#q-023--health-check-bats-scope) | Should `health-check.sh` gate 5 run all bats suites, not just `test/skills/` and `test/hooks/`? | 2026-09-18 |
| [Q-024](#q-024--draft-review-market-sizing) | `business-plan-critique-market-sizing` says draft-review typically invokes it, but draft-review never selec... | 2026-09-18 |
| [Q-025](#q-025--lite-review-install-path) | pr-prep and review-fix-loop tell agents to run `scripts/lite-review.py`, which does not exist in projects t... | 2026-09-18 |
| [Q-026](#q-026--guard-project-claude-dir) | `hooks/guard-trusted-writes.py` treats any `.claude/settings*.json` or `.claude/hooks/**` as HARD and defer... | 2026-09-18 |
| [Q-027](#q-027--readme-wire-docs) | `README.md` (lines 27-149) and `guides/claude-config-security-checkup.md:47` point at `docs/working/wire-*.... | 2026-09-18 |
| [Q-028](#q-028--onboarding-trigger-never-clears) | Decision-tree row 1 fires onboarding when a project has "no `docs/thoughts/`", but onboarding only writes `... | 2026-09-18 |
| [Q-029](#q-029--perf-cold-path-severity) | performance-reviewer gives two defaults for an algorithmic (macro) problem on a cold path: the hot-path gat... | 2026-09-18 |
| [Q-030](#q-030--arch-review-stale-security-input) | architecture-review reads "the most recent" `docs/reviews/security-review-*.md` for trust boundaries and ne... | 2026-09-18 |
| [Q-031](#q-031--draft-review-unmapped-verdicts) | draft-review's rubric tier rules place Inaccurate, Mostly Accurate, Unverified and Accurate, but fact-check... | 2026-09-18 |
| [Q-032](#q-032--self-eval-rubric-outside-repo) | self-eval requires `docs/evaluation-rubric.md`, which exists only in this repo; `link-claude-home.sh` doesn... | 2026-09-18 |
| [Q-033](#q-033--claude-api-flat-file) | `skills/claude-api.md` is a flat file, so the harness never loads it as a skill (skills load from `skills/<... | 2026-09-18 |
| [Q-034](#q-034--agents-gemini-debug-defaults) | AGENTS.md:17 and GEMINI.md:17 send readers to "global-instructions/CLAUDE.md's Debugging defaults section",... | 2026-09-18 |
| [Q-035](#q-035--guard-bash-claude-md-overblock) | In Bash, `guard-trusted-writes.py` hard-denies any command that has a write primitive AND mentions `CLAUDE.... | 2026-09-18 |
| [Q-036](#q-036--si-review-archive-untracked) | `self-improvement.sh` copies each task's code-review rubric into `docs/working/reviews/round-N/<task>/` in ... | 2026-09-18 |
| [Q-037](#q-037--si-survivors-parser-dead) | The self-improvement loop feeds round N+1 a list of surviving ideas that were never tried, but it only pars... | 2026-09-18 |
| [Q-038](#q-038--dd-path-c-no-consumer) | DD's Path C (tradeoff unclear, nobody present) says the round claim surfaces the unresolved choice to you t... | 2026-09-18 |
| [Q-039](#q-039--fact-check-abstract-floor) | fact-check contradicts itself on whether abstract-only sources can support a Medium confidence. One rule do... | 2026-09-18 |
| [Q-040](#q-040--dd-misframing-hook) | When DD's constraints contradict, DD sends you into its Double Diamond variant, while design-space-situatin... | 2026-09-18 |
| [Q-041](#q-041--code-review-merge-rule-gap) | The code-review next-action ladder has no rule for 0 🔴 with 3+ 🟡 where at most 2 lack author notes, w... | 2026-09-18 |
| [Q-042](#q-042--code-review-contextual-severity) | The executable-defect channel maps a confirmed contextual-critic finding "as if filed by a core critic", bu... | 2026-09-18 |
| [Q-043](#q-043--code-review-arch-skip-blocks) | When code-review auto-selects architecture-review but the critic's own scope check skips ("implementation-o... | 2026-09-18 |
| [Q-044](#q-044--override-log-immutable-rows) | For an Incorrect fact-check about an already-merged commit message, rubric.md tells the orchestrator to wri... | 2026-09-18 |
| [Q-045](#q-045--sni-proxy-domain-fronting) | The SNI proxy checks only the ClientHello SNI and splices the encrypted stream, so a client can send an all... | 2026-09-18 |
| [Q-046](#q-046--failure-analysis-fix-or-delete) | `scripts/failure-analysis.sh` computes its re-attempt pass rate against its own definition (it counts attem... | 2026-09-18 |
| [Q-047](#q-047--hypothesis-log-run-id) | Hypothesis-log rows record only a round number, and round numbers restart every self-improvement run, so th... | 2026-09-18 |
| [Q-048](#q-048--guard-cooccurrence-overblock) | Closing the review's bypasses of Q-035 needed a broader Bash rule, applied only to commands that contain a ... | 2026-09-21 |
| [Q-049](#q-049--deny-rule-absolute-path-form) | Do the live deny rules match at all? `link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings... | 2026-09-21 |
| [Q-050](#q-050--guard-resolved-path-policy) | When a file-tool edit reaches a protected global file through its real path rather than through `~/.claude/... | 2026-09-21 |
| [Q-051](#q-051--lean-fronting-entries) | Two `lean` names front to tenants nobody listed (Q-045): `elan.lean-lang.org` reaches any GitHub Pages site... | 2026-09-23 |
| [Q-052](#q-052--android-google-fronting) | `dl.google.com` and `maven.google.com` front to Google-hosted tenants (Q-045: Host www.google.com got Googl... | 2026-09-23 |
| [Q-053](#q-053--azure-blob-fronting-probe) | Does the Azure Blob front end behind `lakecache.blob.core.windows.net` route a different storage account's ... | 2026-09-23 |
| [Q-054](#q-054--copy-install-approach) | Approve the plan that replaces the bare-host symlink install with blessed copies (your Q-050 direction), an... | 2026-09-23 |
| [Q-055](#q-055--gemini-install-target) | Do you still use Gemini (CLI or Antigravity)? The README symlinks six entries into `~/.gemini`, and the cop... | 2026-09-23 |
| [Q-056](#q-056--host-install-tty-only) | Should the host install targets refuse `--yes` and require an interactive terminal? The agent runs on the s... | 2026-09-23 |
| [Q-057](#q-057--host-install-foreign-files) | When a directory the install owns (for example `~/.claude/skills`) holds files the repo does not have, shou... | 2026-09-23 |
| [Q-058](#q-058--installer-trust-model) | The copy-based bare-host install (`ans/copy-install`, parked at 9ae6e46) runs as your user, the same user a... | 2026-09-23 |
| [Q-059](#q-059--arith-eval-bash-grant) | Should arithmetic-eval's LLM fixture runs get a restricted Bash tool so the model can actually run the eval... | 2026-09-24 |
| [Q-060](#q-060--orchestrator-fixture-depth) | How far should batch 4 go for code-review and draft-review? | 2026-09-24 |
| [Q-061](#q-061--host-stage-review-copies) | The host target's stage can be swapped for the review and swapped back before y (the re-review's R2, 6/6 ru... | 2026-09-25 |
| [Q-062](#q-062--leftover-helper-is-agent) | Under Q-058 [2], does a background process an agent session left running (a detached helper, a loop driver ... | 2026-09-25 |
| [Q-063](#q-063--arith-eval-evaluator-check) | How should arithmetic-eval's LLM fixtures check that the model uses the evaluator? (Replaces Q-059, per you... | 2026-09-25 |
| [Q-064](#q-064--unreadable-cwd-gate) | The Q-062 detector skips a same-uid process whose cwd it cannot read. Should it refuse instead? | 2026-09-25 |
| [Q-065](#q-065--si-input-rejected-history-dead-code) | `prepend_si_input_rejected_history` (`scripts/lib/si-input.sh:214`) has had no caller since it landed in 06... | 2026-09-26 |
| [Q-066](#q-066--sandbox-tool-map-host-drift-run) | The permission allow list exists only on your host, so the two drift checks in `test/sandbox-tool-map-drift... | 2026-09-26 |
| [Q-068](#q-068--si-loop-retire-or-resume) | Should `scripts/self-improvement.sh` be retired or resumed? **Answered 2026-09-27: [3] resume — this has ... | 2026-09-26 |
| [Q-069](#q-069--host-git-on-container-checkout) | cc-isolated's recommended workflow is "commit in the container, push from the host with your keys". But the... | 2026-09-26 |
| [Q-070](#q-070--auto-approve-backstops-in-cc-isolated) | `hooks/auto-approve-allowed-commands.sh` accepts its known bypasses because "permissions.deny plus the sand... | 2026-09-26 |
| [Q-071](#q-071--skill-eval-suite-design) | The 50 `@needs-reports` suites can't stay green under this repo's editing rate. Their freshness stamp hashe... | 2026-09-26 |
| [Q-072](#q-072--living-ledger-not-fed) | The review-eval goal is "recall against the living issue ledger", but `docs/working/canon-issue-ledger.md` ... | 2026-09-26 |
| [Q-073](#q-073--skill-descriptions-truncated) | Skill descriptions run 957–2973 characters, and the live skill listing truncates them. In this session 7 ... | 2026-09-26 |
| [Q-076](#q-076--cc-isolated-git-exit-scan) | - **Interim:** the guide's documented caveat only. | 2026-09-27 |
| [Q-077](#q-077--cc-isolated-auto-approve-backstops) | Implement Q-070 [1]. The cc-isolated settings merge gains Bash deny rules for the credentials path and a sa... | 2026-09-27 |
| [Q-078](#q-078--narrow-skill-report-stamp) | - **Interim:** the suites print NOT RUN. | 2026-09-27 |
| [Q-080](#q-080--front-load-skill-descriptions) | - **Interim:** 7 skills still show no description in the listing. | 2026-09-27 |
| [Q-081](#q-081--cc-isolated-sandbox-half) | Q-070 [1] asked for Bash deny rules *and* a sandbox config in cc-isolated. Only the deny half was built (Q-... | 2026-09-27 |
| [Q-082](#q-082--auto-approve-host-checks) | Does a PreToolUse hook `allow` override a matching `permissions.deny` rule? That decides whether the auto-a... | 2026-09-27 |
| [Q-083](#q-083--host-tools-trust-category) | The trust manifest's rule "every shipped file is hashed" puts host-only tools (`cc-push.sh`, and soon `cc-e... | 2026-09-27 |
| [Q-085](#q-085--review-unit-size-budget) | What size cap should a review unit have before the review-fix loop starts (proposal A4)? Over the cap, the ... | 2026-09-27 |
| [Q-086](#q-086--install-gnu-parallel) | `bats --jobs` needs GNU `parallel`, which is not in the image. The full suite runs serially in 742 s on a 1... | 2026-09-27 |
| [Q-087](#q-087--final-confirming-pass-replicates) | Should the final confirming pass of a review-fix loop run the fact-check at k=3 instead of decision 031's k... | 2026-09-28 |
| [Q-091](#q-091--cc-push-self-commondir) | `cc-push` refuses your main checkout because `.git/commondir` holds `.` (see Q-084). Remove the file, or te... | 2026-09-28 |
<!-- index:end -->

## Answered

### Q-001 · install-sh-missing-payload-fatal
**Needs:** you: judgment · **Opened:** 2026-09-12 · **Status:** ANSWERED

Should a missing `install.sh` payload source be **fatal** rather than warn-and-continue? **Answered 2026-09-12: yes, fatal.** None of the seven `CLAUDE_HOME_SRC` entries is optional, and the warning scrolled off above the payload diff and the `[y/N]` prompt — the one gate the human actually reads. The loop now collects every miss and exits 1 once (a reorganization is reported in full rather than one rerun per renamed path). Three cases landed in `test/cc-isolated-functions.bats` (next to the existing `install.sh` assertions, not `link-claude-home-wiring.bats`): one missing source, several missing sources, and the all-present complement. Original entry:

- **Context:** code review 2026-09-12 A13 — a payload with no global instructions file is currently assembled, blessed and linked at exit 0, and the failure is silent-and-total; it got likelier when the source path became a directory deep
- **Interim:** left as warn-and-continue, unchanged
- **If the answer differs:** if fatal, `install.sh:51-57` gets an `exit 1` and `test/link-claude-home-wiring.bats` gains a missing-source case (test-strategy's T3).

### Q-002 · install-sh-bless-prompt-eof
**Needs:** you: judgment · **Opened:** 2026-09-12 · **Status:** ANSWERED

Should `install.sh`'s bless prompt survive a closed stdin? **Answered 2026-09-12: yes — shipped as the one-line `read -r reply || reply=""`.** An EOF stdin now falls through to the existing abort case, so a piped or non-tty run still exits 1 but prints `Aborted. Nothing was changed.` first instead of dying silently at the prompt under errexit. The all-present test in `test/cc-isolated-functions.bats` now asserts on that line; the exit status alone does not discriminate (both old and new behavior exit 1), so the message is the assertion that has teeth. Original entry: · Should `install.sh`'s bless prompt survive a closed stdin?

- **Context:** noticed while writing the A13 tests — under `set -e`, `read -r reply` at EOF kills the script before the `Aborted. Nothing was changed.` line prints, so a piped or non-tty run exits 1 with no explanation
- **Interim:** left alone; non-interactive callers are expected to pass `--yes`
- **If the answer differs:** `read -r reply || reply=""`, one line, and the all-present test can assert on `Aborted` instead of the prompt text.

### Q-003 · ui-visual-review-mandatory-rules
**Needs:** you: judgment · **Opened:** 2026-09-12 · **Status:** ANSWERED

Was the surviving `## Mandatory Execution Rules` block at `skills/ui-visual-review/SKILL.md:58` left out of audit finding F3 deliberately? **Answered 2026-09-12: correctly out of scope on substance — heading renamed for consistency, rule body exempt.** It is a critic, not an orchestrator: the five rules are distinct domain guidance rather than one contract inflated into MUST-rules, and the block carries none of F3's three markers (no absolute-rules preamble, no `MUST`/`No exceptions.`, no restatement 600 lines later; rule 5 is explicitly self-calibrating). The plain-contract rewrite would have flattened five separate rules for no gain. Heading renamed to `## Execution rules` — nothing bound it (no `#mandatory-execution-rules` anchors, no test assertions, and api-consistency's Finding 2 dangling references were already closed in `3255f9b`). Exemption recorded in `docs/reviews/override-log.md` and as a scope note under F3, so test-strategy's T9 third case can encode a decision. **Note for any regression test:** assert on the *heading*, not the substring — `mandatory-execution rule` in `skills/code-fact-check/SKILL.md:330` is an unrelated and load-bearing concept (an executable claim must be run before it can be Verified). Original entry:

- **Context:** F3 covered the three orchestrators (draft-review, code-review, matrix-analysis); api-consistency and test-strategy both flagged this fourth one
- **Interim:** left untouched — F3's scope named three files
- **If the answer differs:** if unintentional, it gets the same plain-contract rewrite.

### Q-004 · code-review-reference-split
**Needs:** you: judgment · **Opened:** 2026-09-12 · **Status:** ANSWERED

Re-cut the reference split — `severity.md` (read at Stage 1.5/2.5) vs `rubric.md` (template, read at Stage 3)? **Won't fix, 2026-09-12 (user's call).** A10's finding stands on the facts — the cut line is not respected and the deferral saves nothing outside a fact-check short-circuit — but the cost is real churn across 19 links at 17 sites for a saving that only lands on one path, and the split as shipped is not wrong, only mis-described. Re-open only if the token cost of the Stage-1.5/2.5 reads becomes a measured problem; if so the fix is the second F8 pass below. Original entry: · Re-cut the reference split — `severity.md` (read at Stage 1.5/2.5) vs `rubric.md` (template, read at Stage 3)?

- **Context:** code review A10 — architecture found the stated cut line ("run a stage" vs "write a deliverable") is not respected: severity semantics moved out but are consulted by the running pipeline from 19 links across 17 sites, so the deferral saves nothing except on a fact-check short-circuit
- **Interim:** split left as shipped
- **If the answer differs:** a second F8 pass moves the severity sections into their own reference file.

### Q-005 · bats-skill-content-helper
**Needs:** agent · **Opened:** 2026-09-12 · **Status:** ANSWERED

Should the `.bats` `SKILL_CONTENT` concat idiom move into `test/skills/helpers.bash`? **Done 2026-09-12** — `load_code_review_skill()` now owns it and the four suites call it; the three narrow-definition suites were left alone (they bind only SKILL.md-resident anchors, which test-strategy verified). Original entry:

- **Context:** code review A9 — the block is copy-pasted byte-identically into four suites, its `cat` order is load-bearing but enforced only by a comment, and three sibling suites still use the one-file definition
- **Interim:** four copies left in place
- **If the answer differs:** one helper function, four call sites, and a comment in the three suites saying why they keep the narrow definition.

### Q-006 · openrouter-sonnet5-judge-pin
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** ANSWERED

Confirm `anthropic/claude-sonnet-5` resolves on OpenRouter before the next cross-model run. **Answered 2026-09-12: moot by scope — this repo should not be calling OpenRouter at all.** The diff-only headless review already runs on the Claude subscription via `scripts/lite-review.py` (decision log 37, wired into `workflows/pr-prep.md` Step 3 and `workflows/review-fix-loop.md`); a Sonnet 5 pass there is `--model claude-sonnet-5`, a flag, not a build. The consumers of the pin are the benchmark harness `scripts/cross-model-review.py` (its `--judge` default, `:378`) and `archive/benchmark/scripts/review-arms.py` (`:69,73`), a wrapper that loads the harness as a module and would follow it to the fork; neither is on the production path, and benchmark work belongs in the SWRBench fork. (`scripts/dd-cross-model-sweep.py` is an OpenRouter script but *not* a consumer of this pin — its `MODELS` list at `:30` is Kimi/GPT/Gemini with no judge concept. The 2026-09-12 code review caught this enumeration as Incorrect, unanimously across three fact-check replicates; the original wording named that file and omitted `review-arms.py`.) The pin is therefore left unverified and the harness is not to be run from here — see the new grammar-ownership entry below, which blocks actually moving it out. Original entry: · Confirm `anthropic/claude-sonnet-5` resolves on OpenRouter before the next cross-model run

- **Context:** audit F10 re-baselined the judge pin; this sandbox has no egress so all three fact-check replicates left it unverifiable
- **Interim:** pin shipped unverified, flagged at both sites
- **If the answer differs:** nothing if it resolves; if not, the pin needs the correct slug and `main()`'s unpriced-model guard should be extended to cover `--judge` (code review C1).

### Q-007 · cross-model-judge-unpriced-abort
**Needs:** you: judgment · **Opened:** 2026-09-12 · **Status:** ANSWERED

Should an unpriced/unknown `--judge` id **abort** `cross-model-review.py` pre-flight, the way an unpriced `--models` entry does? **Answered 2026-09-12: moot by scope, same reasoning as the judge-pin question above.** The pre-flight WARNING shipped in `cb5351d` stands as the final state: hardening a cost guard on a harness this repo is not to run would be work spent on the wrong side of the fork boundary. If the harness moves to the SWRBench fork, this question moves with it and is re-opened there against a funded account that can actually test the abort path. Original entry: · Should an unpriced/unknown `--judge` id **abort** `cross-model-review.py` pre-flight, the way an unpriced `--models` entry does?

- **Context:** code review C1 — the judge is pinned rather than passed in `--models`, so the fail-closed cost guard never sees it and a bad slug surfaces only as a stage-2 API error, after stage 1 has been paid for
- **Interim:** it now prints a pre-flight WARNING naming the judge, because the judge is consulted only when stage-2 matching runs and that is not knowable at guard time
- **If the answer differs:** if it should abort, the `unpriced` list gains `args.judge` and the stage1-only path needs an explicit opt-out flag.

### Q-008 · findings-grammar-ownership
**Needs:** agent · **Opened:** 2026-09-12 · **Status:** ANSWERED

Make `lite-review.py` the definition of the FINDINGS grammar rather than a copy of it, before `cross-model-review.py` leaves this repo. **Done 2026-09-12 — resolved rather than left pending, so the harness can move whenever you want it to.** `lite-review.py`'s header now states ownership outright (and that the two were byte-identical at the moment ownership moved, which is what preserves E2/E3 lite-arm comparability); `cross-model-review.py`'s `FINDING_RE` carries a comment naming itself the copy and telling the fork not to silently re-fork it; and `test/lite-review-grammar.bats` pins the shape with 7 contract tests over `parse_findings` — keyless and offline, since the parser is pure. Original entry: · Make `lite-review.py` the definition of the FINDINGS grammar rather than a copy of it, before `cross-model-review.py` leaves this repo

- **Context:** closing the two OpenRouter questions above scoped the benchmark harness out of this repo, but `scripts/lite-review.py:24-26` documents its grammar and regex as copied from `cross-model-review.py` and names itself only the *surviving* owner "if that harness is retired" — moving the harness out without promoting the grammar first leaves the live path's output format defined by a file in another repo
- **Interim:** both files unchanged; the copy is still byte-compatible, so nothing is broken today
- **If the answer differs:** if promoted, `lite-review.py` gets the grammar as a documented contract with its own test, and `cross-model-review.py`'s header is reworded to point at it as the source before the move.

### Q-010 · elan-release-host
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** ANSWERED

Which host does elan actually fetch toolchains from — `release.lean-lang.org` or `releases.lean-lang.org`?

- **Context:** decision log 51 added the Lean toolchain to the image; elan's changelog (via search summaries, this sandbox has no egress) says releases and assets come from `release.` singular, while `egress/lean.txt` has carried `releases.` plural, unexercised, since decision 016
- **Interim:** both are listed, because a name that fails to resolve warns-and-skips rather than failing the container, and the SNI proxy matches exactly so a near-miss would be silently rejected
- **If the answer differs:** delete the loser from `egress/lean.txt` once a real toolchain fetch has been watched succeed; if pre-4.x elan is kept, note that it resolves via GitHub (already admitted by CIDR) and neither name is load-bearing.

**Answered 2026-09-17 (probe, `docs/human-author/answers-9-17-26.txt`): keep both — neither is wrong.**
`release.lean-lang.org` returns `HTTP/2 200` and `releases.lean-lang.org` returns
`HTTP/2 302`. Both resolve, so the premise that one of them is a dead entry to be
pruned is false. `release.` is canonical for the 4.x line that ships (Q-013); the
plural name redirects, and since the SNI proxy admits a 443 name only on an exact
match, a redirect target must itself be listed for the hop to survive. Keeping
both is therefore the correct end state, not a hedge. `egress/lean.txt`'s VERIFY
comment is updated to record the measurement instead of asking for it again.

### Q-013 · elan-version-to-ship
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** ANSWERED

Is `ELAN_VERSION=v3.1.1` the version to ship? **ANSWERED 2026-09-15: no — `v4.2.4`, taken from the GitHub release list on the host. Bumped in `devcontainer.json`; a live `elan toolchain install` succeeded in-container on 2026-09-15, so the 4.x line is confirmed working. This also settles the elan major version that the release-host question below turns on (4.0.0+ resolves releases and assets from `release.lean-lang.org`).**

- **Context:** pinned from memory because the release list is unreachable from here; a newer 4.x is likely current and is the line that resolves toolchains via `release.lean-lang.org` rather than GitHub
- **Interim:** v3.1.1, which fails loudly (wget 404) at build time if wrong rather than silently degrading
- **If the answer differs:** bump `ELAN_VERSION` in `devcontainer.json`, and re-check the release-host question above, which the elan major version decides.

### Q-015 · scholar-hostnames
**Needs:** you: terminal · **Opened:** 2026-09-17 · **Status:** ANSWERED

Confirm the three `scholar` hostnames that no search summary covered — `pmc.ncbi.nlm.nih.gov`, `api.biorxiv.org`, `www.medrxiv.org`

- **Context:** `egress/scholar.txt` (decision log 52) was authored from a sandbox with no egress; the other nine names (OpenAlex, Crossref, Semantic Scholar, Unpaywall, export.arxiv.org/arxiv.org, eutils, www.ebi.ac.uk, api2/api.openreview.net) came from search summaries of the providers' own API docs, but PMC's current OA host and the bioRxiv/medRxiv API split did not
- **Interim:** all three listed; a name that does not resolve warns-and-skips at container start, so a wrong entry degrades to "stays blocked", never to a wider allowlist
- **If the answer differs:** delete or correct the losers in `egress/scholar.txt`, re-install, re-bless. One `curl -sI` per host from inside a `--profile scholar` container settles all three.

**Answered 2026-09-17 (probe, `docs/human-author/answers-9-17-26.txt`): all three resolve — keep all three, with one caveat that matters.**
`pmc.ncbi.nlm.nih.gov`, `api.biorxiv.org` and `www.medrxiv.org` each return
`HTTP/2 200`. The caveat, surfaced in the same session and worth carrying: a 200
on the PMC *host* does not mean article pages are fetchable — they serve a
reCAPTCHA interstitial ("Checking your browser"), so `eutils` remains the only
PMC route that yields bodies. The allowlist entry is correct; the expectation of
what it buys is narrower than the hostname suggests.

### Q-017 · rpi-doc-zero-reads
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** ANSWERED

`workflows/research-plan-implement.md` — the documented default — was opened **0 times in 49 days** (2749 logged events, 20+ projects) while `divergent-design` was opened 15 times. Is RPI being followed without the doc being read, or not followed?

- **Context:** `docs/working/triage-2026-09-17-backlog.md` §2.2; `hooks/log-usage.sh:61-63` logs a `workflow` event on any Read under `*/workflows/*`, so the claim is precisely "the doc is not opened", not "the process is not followed"
- **Interim:** nothing changed; H-01 left TRACKING rather than expired, now with its first real evidence attached
- **If the answer differs:** if the routing table in the core instruction set is carrying the process, RPI's doc is redundant detail and should shrink or merge; if the process is genuinely unused, that is a much larger subtraction and it bears on the §4 decision.

**Answered 2026-09-17: the measurement is not trustworthy, so the finding is withdrawn as evidence.**
Per the user: some setups — notably creating a subagent with skill text already in
its context — trigger no hooks at all, so usage would go unrecorded [their
confidence: low on that specific mechanism]. More decisively, hook measurement
problems have recurred often enough that they lost faith in the numbers generally
[confidence: high], including after fixes shipped.

This retires the claim rather than answering it. **0 reads of
`workflows/research-plan-implement.md` in 49 days is consistent with the doc being
unused *and* with the instrument not seeing it, and the data cannot separate
those.** H-01 and H-07 in `docs/working/hypothesis-backlog.md` rest on the same
instrument and inherit the same defect. Note this also weakens the 15:0 contrast
drawn in `docs/working/triage-2026-09-17-backlog.md` §2.2 — divergent-design's 15
reads are a lower bound on a floor, not a comparable measurement.

The reusable lesson is about triage, not about RPI: **an instrument with a known
history of silent under-counting should not generate attention asks at all until
it is re-validated.** Routing a number to `you: judgment` presumes the number is
real. That belongs in the route criteria.

### Q-018 · failure-patterns-backfill
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** ANSWERED

`docs/thoughts/failure-patterns.md`: backfill from the 104 eligible `fix(...)` commits, or delete the file?

- **Context:** 0 entries since 2026-05-18 despite `workflows/pr-prep.md` Step 0 saying "do not skip this step" — the third instance of "promoted to core instructions executes, left in a workflow doc does not"
- **Interim:** left as-is, routed to you as a one-bit call
- **If the answer differs:** backfill is an agent task of a few hours; delete also removes the read-side grep from RPI research.

**Answered 2026-09-17: backfill. Done.** 164 entries (FP-008..FP-171) harvested
from the 105 eligible `fix(...)` commits; commits naming several distinct root
causes got one entry each. Numbering starts at FP-008 because FP-007 is the
schema example in the file's own prose.

Two things the backfill produced beyond the entries. First, a first pass gave
almost every entry its own `cause:` token — 154 distinct over 164 entries, which
defeats the schema's point, since a category that appears once is a label rather
than an index. Collapsed to **23 causes and 16 fix shapes**, with the
specificity left in `symptom:` where the grep-able detail belongs.

Second, the distribution is itself a finding: `fail-open` (25),
`guard-misses-subject` (17) and `vacuous-assertion` (16) are **58 of 164** — more
than a third — and they are one failure wearing three hats, *a check that reports
success without having established it*. The most-repeated concrete shape is a
bare `! grep` or unanchored pattern in a bats test, now fixed three times in
three different files (FP-060, FP-156, FP-168). The read-side (RPI research greps this file by symptom keyword) is the
half that has never been exercised, and it cannot be until entries exist.
### Q-009 · live-verify-gate-not-installed
**Needs:** you: judgment · **Opened:** 2026-09-12 · **Status:** ANSWERED

**Answered 2026-09-17: [2] — "option 2 seems good and easy". Both halves shipped.**
The installed-ness pin is a new test in `test/hooks/live-verify-gate.bats` that reads
the live `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`, resolves the expected
command out of `hooks/wiring.json` the same way `scripts/health-check.sh`'s
`check_hook_wiring` does, and asserts it by exact name — so a silent uninstall turns
the suite red instead of leaving a warning nobody reads. It ran (did not skip) in this
container, which is a second, independent confirmation that the gate is installed.
The narrowing is `comment_only_diff()` in `hooks/live-verify-gate.sh`: the gate now
exits 0 when every added and removed line across the touched enforcement files is
blank or a comment (`#` or `//`). Per your caveat the rule is **"no change to any
non-comment line"**, never "no change to hostnames" — commenting out a live allowlist
entry removes a non-comment line and is still gated — and a rename, mode change, file
addition or deletion, a binary diff, or an empty/failed diff all fall through to the
gate rather than through the shortcut. Seven narrowing cases were added alongside;
suite is 19/19 green, `shellcheck` clean, `test/link-claude-home-wiring.bats` 13/13
still green. Original entry:

Review finding A7 said `live-verify-gate.sh` is declared but not installed — **it is now demonstrably installed**, so what remains is whether to keep it and whether to test that it stays installed.

- **New evidence 2026-09-17, unplanned:** the gate blocked a commit of mine in this session. It fired as a `PreToolUse:Bash` hook error from the installed copy of `live-verify-gate.sh`, on a commit touching `devcontainer-config/egress/`, demanded a `Live-verified:` trailer, and refused the commit until it got one. **That is stronger evidence than reading the settings file** — the finding's claim ("every `devcontainer-config/` change is currently committable with no live-verification question asked") is false as of today. A7 is stale on its central fact.
- **Why it's still yours:** two things the evidence does not settle. (a) The gate is correct but coarse — it blocked a **comment-only** diff that added and removed no hostname, so the admitted set was byte-identical and no probe was possible or useful. (b) The finding's *other* half stands: eleven bats tests exercise the script and **nothing tests that it is installed**, so it can silently fall out again exactly as it apparently fell in.
- **Read:** `docs/reviews/code-review-rubric-2026-09-12-main-questions-closeout.md` (finding A7, row 28) · `hooks/wiring.json:62-72` · `hooks/live-verify-gate.sh` · `docs/decisions/035-install-sh-gating.md` · this session's blocked commit, now `e96912d`, and its trailer

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Add the installed-ness test, leave behaviour alone** | A test asserts the live settings carry the `wiring.json:62-72` entry, so a silent uninstall fails the suite | None — I can write it if you say go | Nothing; this is the cheap half and closes the half of A7 that is still true |
| **[2] [1] plus narrow the trigger** | Skip the gate when a `devcontainer-config/` diff changes only comments | One review of the narrowing rule | A comment that *is* load-bearing (an allowlist entry commented out) would slip — so the rule must be "no change to any non-comment line", not "no change to hostnames" |
| **[3] Leave entirely as-is** | Gate installed, untested, coarse | None | It falls out again and nothing notices — the original A7 state, re-entered silently |

- **Blocks:** R1's fix. Decision 035 chose option [3], the commit-time regex, and named A7 a prerequisite — which is now satisfied in fact, if not in test.
- **Interim:** [3]. The gate works today; nothing is burning.
- **If the answer differs:** [1] is a small test against the live settings file, which is deny-listed to me for *writing* — confirm whether a test may *read* it, or the assertion has to run host-side.
- **Note:** re-scoped 2026-09-17 from "install it" to "keep and test it" after the gate fired. The original three options are in `git log -p` for `e96912d`.


### Q-022 · lite-review-findings-invariant
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** ANSWERED

**Answered 2026-09-17: [2], on your reasoning that a lite-review attestation means
~nothing.** Read as: A5 is not a defect worth a fix — a clean lite review's only
consequence is "proceed to the full review", which is also the right next step when
the lite review is broken, so a refusal parsing as 0 rows costs nothing downstream.
[1] was rejected for the reason you gave: it adds a failure condition the review-fix
loop must handle, and that loop is the only thing lite review exists to make cheaper.
That leaves A6, which is a real hang regardless of who supplies the input, and [2]
closes it: `parse_findings` now skips any line inside the block that contains no `|`
(`scripts/lite-review.py:109-123`). Measured before the fix, a numbered line followed
by a whitespace run took 0.32 s at 1 kB and 2.3 s at 2 kB, ~7.3x per doubling — the
original A6 number reproduces. Two tests added to `test/lite-review-grammar.bats`: a
20-second time bound on an 8 kB whitespace run (which would have taken minutes), and
a pin that skipping pipe-less lines changes no row that used to survive. Suite 13/13
green; tests 6 and 7 keep their current meaning, which [1] would have required
re-pinning. X1's "no invariant" stands as a known, accepted gap. Original entry:

Review findings A5 + A6 + X1 — `parse_findings` has no invariant that a line inside the FINDINGS block is either a well-formed row or the `NONE` sentinel. Add one, or patch the two symptoms separately?

- **Why it's yours:** the two obvious one-liners pull in opposite directions, so this cannot be fixed one finding at a time. Which way it resolves is a call about how much a clean review is allowed to mean.
- **Read:** `docs/reviews/code-review-rubric-2026-09-12-main-questions-closeout.md` (rows 26, 27, 36 — A5, A6, X1) · `scripts/lite-review.py:86-108,196` · `test/lite-review-grammar.bats:94-95`
- **The two symptoms, one root:** A5 — a model refusal (`"I cannot emit FINDINGS for this diff."`) parses as `parse_ok=True`, 0 rows, so `main()` prints `FINDINGS: NONE`, exit 0, and the review-fix loop reads it as a clean pass. A6 — `FINDING_RE` backtracks catastrophically on a solid whitespace run inside the block: 16,000 chars took **877 s** measured, ~7.9× per doubling, a hang rather than a slow parse. X1 — both exist because unmatched lines are silently skipped.

| Option | What it means | Consequence |
|---|---|---|
| **[1] Reject the block** *(closes all three)* | A line inside FINDINGS that matches neither a row nor the sentinel makes the parse fail | A refusal stops reading as clean; prose never reaches the regex, so A6's input is gone too. Strictest, and the only one X1 endorses. |
| **[2] Performance's one-liner** | `if "\|" not in line: continue` | Fixes A6 by skipping non-row lines *more* silently — which makes A5 worse. |
| **[3] Security's one-liner** | Reject unparseable lines | Fixes A5; leaves the regex reachable by anything containing a pipe. |
| **[4] Leave it** | Tests 6/7 currently pin the present behaviour as normative | The hang is unreachable on this cold, single-call, self-fed path today — which is why it is Medium and not High. |

- **Interim:** [4]. The path no attacker supplies and no caller feeds cold input to, so nothing is burning.
- **If the answer differs:** [1] needs tests 6/7 in `test/lite-review-grammar.bats` re-pinned, since they currently assert the behaviour it removes.
- **Note:** this was bundled with A7 in a single entry until 2026-09-17; splitting it is why it now has its own ID.


### Q-014 · profile-replace-only
**Needs:** trigger · **Opened:** 2026-09-15 · **Status:** ANSWERED

Should `--profile` stay replace-only, or grow `--add-profile`/`--remove-profile`?
**Answered 2026-09-17: replace-only stands — "if egress is constantly changing we
have other problems".** No code change; the interim below is now the decision. The
loud transition print stays, since it is what makes a dropped profile visible at the
moment it happens.

- **Context:** `register_project` overwrites the stored grant, so re-registering a project to add `lean` silently dropped the `dotnet` it already had; found while trying to get the `lean` profile into a live container
- **Interim:** kept replace (a grant you can only widen is not a grant) and made it loud instead — the transition and any dropped profile are printed, `--list` already showed the current grant, and the line-10 comment no longer says "widen"
- **If the answer differs:** if you find yourself re-typing the full list often, add the two additive flags rather than changing what `--profile` means.


### Q-016 · scholar-oa-escape-hatch
**Needs:** trigger · **Opened:** 2026-09-17 · **Status:** ANSWERED

Does `scholar` need a companion escape hatch for publisher-hosted OA PDFs?
**Answered 2026-09-17: yes, shape (b) — "fine to use a workaround that accumulates
papers for human retrieval, since that fully covers proxies, CAPTCHA, inconsistent
paywalls, etc."** Built as `scripts/paper-queue.sh` (`add` · `list` · `done` ·
`status`), which is reachable in any wired container as
`~/.claude/scripts/paper-queue.sh` because `link-claude-home.sh` links `scripts/`.
A session that hits a rejected host records the identifier and keeps going; the
queue is a five-column TSV at `papers/requests.tsv` (override `$PAPER_QUEUE`),
idempotent on the identifier so a loop that rediscovers the same DOI does not pile
up duplicates; `status` detects a PDF the human has dropped into `papers/` by
matching the identifier's slug, so a forgotten `done` surfaces as a nudge rather
than as a lost paper. 26 tests in `test/paper-queue.bats`, green; `shellcheck`
clean; hermeticity gates green. Shape (a) — a `scholar-extra` profile — was **not**
built and the boundary is unchanged: your reasoning is exactly why, since one human
retrieval step covers the whole tail at once where each allowlist entry buys one
publisher and leaves a permanent hole. `guides/cc-isolated-usage.md`'s scholar
section now documents the queue in place of the dead end.

- **Context:** the profile's honest limit is that Unpaywall/Crossref routinely return full-text URLs on hosts the SNI proxy rejects (publisher domains, institutional repositories, S3 buckets), so a literature-review session gets metadata for everything and bytes for the arXiv/PMC/bioRxiv subset only
- **Interim:** no escape hatch — documented as a failure mode in `guides/cc-isolated-usage.md` rather than widened, since the alternative is a per-paper, per-publisher allowlist churn that nobody will maintain
- **If the answer differs:** if this bites in practice, the shapes are (a) a narrow `scholar-extra` profile listing the two or three publishers you actually read, or (b) fetching those PDFs on the host and dropping them into the workspace, which needs no boundary change at all.


### Q-020 · asks-unit-weighting
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** ANSWERED

Is `asks` (triage §3.3) the right unit, or does it undercount one hard judgment against several easy ones?
**Answered 2026-09-17: the unit stands, and the presentation is promoted.** You
answered the larger question rather than the unit one — "this example is a big
improvement, I'm happy with the pattern so far and would like it in the global
instructions" — so `asks` keeps counting items (no S/M/L weighting, which would be a
judgment to assign and therefore itself an ask), and the decision-card format that
makes the count mean something is now in `global-instructions/CLAUDE.md`: the four-column options
table (**Option · What it means · Cost to you · If it's wrong**) is stated as the
format rather than a suggestion, with the `you: terminal` one-paste variant, the
one-line answering protocol, and a new rule that an entry whose options split along
two independent axes is two entries (which is what made Q-009 and Q-022 answerable at
all). Re-open the unit question only if a cycle's alarm fires on five trivial items,
or stays silent through one crushing one.

- **Context:** today's 5 asks range from a one-bit call to a four-part review decision
- **Interim:** counting items, not weight, because assigning weight is itself a judgment and therefore itself an ask
- **If the answer differs:** entries carry a coarse S/M/L and the alarm threshold becomes a sum.


### Q-021 · drop-delete-or-archive
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** ANSWERED

Should DROP items be deleted or archived?
**Answered 2026-09-17: archive — "archive is usually preferred over delete".**
The route is rewritten in `docs/working/triage-2026-09-17-backlog.md` §3.1: it is
named ARCHIVE, its destination is `archive/docs/YYYY-MM-DD-<name>.md` in the tracked top-level
`archive/` tree — **not** `docs/working/archive/`, which is gitignored and would
have made this answer a delete in disguise, and §3.2's recoverability bullet
now says the artifact stays in the tree rather than only in history. As the card
predicted, the route stops being free: it costs one move commit per item instead of
one line of your reading, which is the price of the asymmetry (a needless archive
costs a `git mv`; a needless delete costs whoever next wants the schema an
archaeology dig). Applied to L2, the first item it governs: the incident journal is
now `archive/docs/2026-09-17-incident-journal.md`, dropped from
`archive-working-docs.sh`'s PERMANENT list, and `guides/skill-recovery.md` step 4
tells its next writer to copy the archived file back rather than treating the
mechanism as gone.

- **Context:** `docs/working/incident-journal.md` is dormant-because-unfed rather than wrong — deleting it loses a schema someone designed
- **Interim:** propose deletion, do not delete
- **If the answer differs:** if archive, DROP needs a destination and the route stops being free.

### Q-012 · elan-sha256-pins
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** ANSWERED

Pin the per-arch SHA-256 of the elan release as build ARGs
**Answered 2026-09-18 (`docs/human-author/answers-9-18-26.txt`):** v4.2.4 digests are `42b94d42…31f63` (x86_64) and `05febd12…72bf9` (aarch64). Both are real assets, not error pages: the two differ, and a GitHub 404 body would hash the same for both targets. Applied: `ELAN_SHA256_AMD64` / `ELAN_SHA256_ARM64` build ARGs plus a `sha256sum -c` in the elan layer (shfmt's shape), passed from `devcontainer.json` next to `ELAN_VERSION` so a bump moves all three together. The Dockerfile's stale `ELAN_VERSION=v3.1.1` fallback moved to `v4.2.4` as well; leaving it would make a build without the devcontainer args fail the new check. Takes effect at the next `install.sh` → rebuild. If the digests were wrong, that build fails at the checksum step; it does not install anything unverified.

- **Answering "I don't see what action" (2026-09-17):** my entry was wrong to imply a container. No Lean, no egress profile and no container are involved — the two files are ordinary GitHub release assets, so **any machine with plain internet** produces the digests, including the host you are reading this on. The reason it is yours at all is only that this authoring environment has no egress; that is the whole blocker. Route corrected from `deferred` to `you: terminal`.
- **Context:** the Dockerfile's elan layer fetches `elan-<target>.tar.gz` from the GitHub release with no checksum, following the rustup layer's documented deferral. `ELAN_VERSION` ships as `v4.2.4` (`devcontainer-config/devcontainer.json:42`; the `Dockerfile:446` default is a stale fallback).
- **The paste:**

```bash
V=v4.2.4
for t in x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu; do
  printf '%s  ' "$t"
  curl -sL "https://github.com/leanprover/elan/releases/download/$V/elan-$t.tar.gz" | sha256sum | cut -d' ' -f1
done
```

- **What I do with it:** add `ELAN_SHA256_AMD64` / `ELAN_SHA256_ARM64` build ARGs and a `sha256sum -c` to the elan layer, matching the shfmt and .NET layers (`devcontainer-config/Dockerfile:165-176` is the shape).
- **Interim:** version-pinned, unverified — bounded by running at build time, but this layer installs into a node-writable tree, so the pin is worth more here than in the rustup layer.
- **If the answer differs:** if you would rather not run it, this stays as-is until the next `ELAN_VERSION` bump, which is the natural moment to collect both digests anyway.


### Q-019 · worktree-cleanup
**Needs:** you: terminal · **Opened:** 2026-09-17 · **Status:** ANSWERED

Reclaim the 231 MB under `.claude/worktrees/` — the git half is done, the disk half is a plain `rm -rf` I am not allowed to run.
**Answered 2026-09-18 (`docs/human-author/answers-9-18-26.txt`):** done, and I observed the result. Your run showed the host clone listing only its main checkout (`788d46a [main]`) and `du -sh .claude/worktrees` at `4.0K`. I checked in-container this session too: `git worktree list` shows only `/workspace`, and `du` reports `4.0K`. All 14 directories are gone, including the three owned by the host clone. Nothing was kept as a reference checkout.

- **Your run worked; my paste was incomplete (2026-09-17).** `git worktree list` now shows only `/workspace` and `.git/worktrees/` is gone entirely, so the `remove`/`prune` half succeeded — the registrations are all cleared. `du` still reports 231 MB because **`git worktree prune` deletes registrations, not directories**: what is left under `.claude/worktrees/` is 14 ordinary directories that git no longer knows about. That is my omission, not a failure of yours.
- **Nothing unique is in them, checked this session.** Against `main`'s tree, the files each directory holds that `main` does not are all *historical* paths (old `docs/working/` drafts, `scripts/review-arms.py` and friends now under `archive/benchmark/`) — i.e. stale bases, recoverable from `git log`. No directory holds work that exists only there.
- **One wrinkle:** three of them — `agent-a4569e6741d6f71c8`, `agent-ae5933c7c8f651ef7`, `agent-af8ebf915c7a1c66d` — carry a `.git` file pointing at `/home/magfrump/claude-workflows/.git`, not `/workspace/.git`. They belong to the **host** clone, so if that clone still lists them, remove them there with git rather than by hand.
- **The paste** (run where `.claude/worktrees` lives):

```bash
cd /path/to/claude-workflows          # the host clone
git worktree list                     # expect: only the main checkout
rm -rf .claude/worktrees/*            # the 14 orphaned directories
du -sh .claude/worktrees              # expect ~0
```

- **Interim:** the 231 MB stays. It is inert — no registration, no ref, nothing reads it — so this is disk, not risk.
- **If the answer differs:** if you would rather keep a couple as reference checkouts, keep `agent-af8ebf915c7a1c66d` (the widest set of historical paths of the fourteen) and delete the rest, which are older checkouts of the same tree at various points.


### Q-027 · readme-wire-docs
**Needs:** agent · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Done 2026-09-18.** New tracked guide `guides/bare-host-hook-wiring.md` holds what the three wire docs carried and `hooks/wiring.json` does not: symlink-vs-copy install rules, a `jq` one-liner that prints `wiring.json` resolved for hand-merging, the manual hardening (allow-list pruning, sandbox block, WSL2 prerequisite, auditor location), verify steps (run as printed; the audit step needed a `${TMPDIR:-/tmp}` fix), and accepted gaps. README, the checkup guide and decision 023's two "remains the procedure" bullets now point there. Also fixed on the way: the README's bare-host install never installed `live-verify-gate.sh`, which `wiring.json` wires — a hand-merged setup would error on every Bash call. Original entry:

`README.md` (lines 27-149) and `guides/claude-config-security-checkup.md:47` point at `docs/working/wire-*.md`, archived 2026-08-06 (9b0f583). Repoint them at `hooks/wiring.json` (decision 023) and move the bare-host and WSL2 notes somewhere tracked.

- **Interim:** links dangle in fresh clones. Not restored on 2026-09-18, because the wire docs predate `hooks/wiring.json` and would reintroduce stale steps.


### Q-024 · draft-review-market-sizing
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: fix — it was a logical gap.** draft-review's description, known-critics block and business-plan row never listed market-sizing, so it could not be selected. Added to all three (business-plan drafts now get all three business critics); `guides/skill-trigger-guide.md` updated to match. (8d61ee7)

`business-plan-critique-market-sizing` says draft-review typically invokes it, but draft-review never selects it. Which side changes?

- **Read:** `skills/business-plan-critique-market-sizing/SKILL.md:36`, `skills/draft-review/SKILL.md` (description, known-critics block, business-plan row ~90)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Add it to draft-review** | Business-plan drafts get a third critic | One more critic's tokens per business-plan review | Extra noise if market sizing rarely matters to your drafts |
| **[2] Fix the market-sizing claim** | It stays standalone-only, and says so | none | Business-plan reviews keep missing market-sizing critique |

- **Interim:** unchanged.


### Q-025 · lite-review-install-path
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: re-implement/install, and consolidate.** `scripts/lite-review.py` already existed as a subscription `claude -p` call. It stays **without `--bare`**, because `--bare` ignores subscription login and fails silently with "Not logged in", exit 0 (verified 2026-08-15); the docstring and review-fix-loop now say so. The real gap was install: the README's bare-host setup never linked `scripts`, so it now adds `ln -s ~/claude-workflows/scripts ~/.claude/scripts`. Workflows call `~/.claude/scripts/lite-review.py … --range …`. `questions.sh` resolves `docs/working/` from the git toplevel of `$PWD` and gains `init`. pr-prep / review-fix-loop / code-review now have one owner per rule, and pr-prep has a local-merge default with the GitHub-PR path kept as the collaborative variant. (aa9a5a0, 665faeb, 6eb89cd)

pr-prep and review-fix-loop tell agents to run `scripts/lite-review.py`, which does not exist in projects these workflows are installed into. How should installed projects reach it?

- **Read:** `workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69` (also omits the required `--range`), `README.md:14-23` (install links; no `scripts`), `devcontainer-config/link-claude-home.sh:47` (links `scripts` to `~/.claude/scripts`)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Use `~/.claude/scripts/lite-review.py`** | Docs use the installed path; README install adds `scripts` | none | Bare-host installs that skip the link still fail |
| **[2] Mark the step optional** | "If available" wording; skip when absent | none | Fix-drift checks silently stop outside this repo |

- **Interim:** unchanged; the command works only inside this repo.
- **Same class:** `global-instructions/CLAUDE.md` (the running-questions section) has every project run `scripts/questions.sh next-id|index|archive|check`, "gated by `scripts/health-check.sh`", but both exist only here. The installed copy doesn't help either: `questions.sh:44-46` resolves `docs/working/` from the script's own location, not `$PWD`. Under [1], `questions.sh` would also need to default to `$PWD/docs/working/`. Under [2], the section would say that outside this repo the file is kept by hand to the grammar.


### Q-026 · guard-project-claude-dir
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** File tools: only the global config dir (`~/.claude` or `$CLAUDE_CONFIG_DIR`) is HARD; a project's `.claude/settings*.json` and `.claude/hooks/**` are SOFT (ask when tainted). Bash still denies any `.claude/settings|hooks` fragment, because command text can't tell project from global. That is stricter, not looser. (4c7a2bb)

`hooks/guard-trusted-writes.py` treats any `.claude/settings*.json` or `.claude/hooks/**` as HARD and defers to `permissions.deny`, but the deny rules cover only `~/.claude`. A project's own `.claude/settings.local.json` (which can add Bash allow rules) therefore gets no ask, even in a web-tainted session. Close it?

- **Read:** `hooks/guard-trusted-writes.py:51-53,123-126`, `hooks/wiring.json` deny rules. Reproduced by the 2026-09-18 scripts defect hunt.
- **Related:** decision log row 53 (auto-approve gaps accepted as risk; the sandbox is the boundary)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Project `.claude/` falls to SOFT** | Tainted sessions get an "ask" on project settings/hooks writes | An occasional extra prompt | Little |
| **[2] Add project paths to deny** | Hard-block writes to project `.claude/settings*` | Claude can't edit project settings at all | Blocks legitimate `update-config` use |
| **[3] Accept, like row 53** | Record as accepted risk | none | A tainted session can widen its own allow list |

- **Interim:** unchanged.


### Q-028 · onboarding-trigger-never-clears
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: either.** Row 1 now fires only when the project has neither `docs/thoughts/` nor `docs/working/onboarding-*.md`. (f8aa39d)

Decision-tree row 1 fires onboarding when a project has "no `docs/thoughts/`", but onboarding only writes `docs/working/onboarding-{project}.md` and never creates `docs/thoughts/`. So row 1 fires again every session in an onboarded project. Which side changes?

- **Read:** `global-instructions/CLAUDE.md:19` (row 1), `workflows/codebase-onboarding.md:18` ("Not a trigger: from-scratch projects") and step 12 (orientation doc)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Key row 1 on the orientation doc** | Trigger is "no `docs/working/onboarding-*.md`" | none | Projects onboarded by hand (no doc) get re-onboarded once |
| **[2] Onboarding creates `docs/thoughts/`** | Step 12 also seeds a thoughts file | One more file per onboarded project | Empty thoughts dirs that nobody updates |

- **Interim:** unchanged. The row keeps over-firing; in practice agents skip it when the repo is already familiar.


### Q-029 · perf-cold-path-severity
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** Macro × Cold → Low; escalate when the cold path runs over large data or blocks something latency-sensitive. (40f21fc)

performance-reviewer gives two defaults for an algorithmic (macro) problem on a cold path: the hot-path gate says "Low or Informational"; the calibration matrix says "Medium". Under code-review's mapping, Medium is 🟡 Must Address and Low is 🟢 Consider, so the same finding either blocks or doesn't. Which wins?

- **Read:** `skills/performance-reviewer/SKILL.md:46` (gate) vs `:280` (Macro × Cold row), `skills/code-review/references/rubric.md:270-271`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Macro × Cold → Low** | Matrix follows the gate; cold-path N+1s become Consider | none | A cold path that runs at scale (a nightly batch) slips through as optional |
| **[2] Keep Medium; narrow the gate** | Gate only blocks escalation to Critical/High; micro issues stay Low | More Must-Address rows on startup/migration code | Review noise on code that runs once |

- **Interim:** unchanged; agents get whichever paragraph they weigh more.


### Q-030 · arch-review-stale-security-input
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [2].** architecture-review records the security review's `Commit:` and cites it on every finding that uses its boundaries, labelled "may be stale" when not HEAD/base. (789d186)

architecture-review reads "the most recent" `docs/reviews/security-review-*.md` for trust boundaries and never checks its `Commit:` line, so a security review of an older diff or another branch is treated as authoritative. Gate it?

- **Read:** `skills/architecture-review/SKILL.md:191-209`, `skills/security-reviewer/SKILL.md:554` (writes `Commit: <hash>`). `docs/reviews/` here holds 10+ security reviews from different branches.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Require a matching commit** | Use the file only if its `Commit:` is HEAD or the review base; otherwise skip the step | none | Standalone arch reviews lose the trust-boundary input more often |
| **[2] Use it, label its commit** | Any recent file is used; the finding cites the commit it came from | You judge staleness when reading findings | A stale boundary still shapes the finding |

- **Interim:** unchanged.


### Q-031 · draft-review-unmapped-verdicts
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** Disputed and Secondary-only → 🟡. (603b0d1)

draft-review's rubric tier rules place Inaccurate, Mostly Accurate, Unverified and Accurate, but fact-check also emits `Disputed` and `Secondary-only`, which have no tier. Where do they go?

- **Read:** `skills/draft-review/SKILL.md:460-480` (tier rules), `skills/fact-check/SKILL.md:163,172` (verdict definitions)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Both → 🟡 Amber** | Disputed and Secondary-only need justification, like Unverified | none | A secondary-only claim that is actually wrong isn't flagged red |
| **[2] Disputed 🟡, Secondary-only 🔴** | Only-secondary sourcing must be fixed before publishing | More red rows on essays citing news coverage | Red becomes noisy and you start ignoring it |

- **Interim:** unchanged; the orchestrating agent picks a tier ad hoc.


### Q-032 · self-eval-rubric-outside-repo
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [2].** self-eval stops with a clear message without the rubric; the cross-project guide lists it as repo-only. (5910b69)

self-eval requires `docs/evaluation-rubric.md`, which exists only in this repo; `link-claude-home.sh` doesn't install `docs/`, and `guides/cross-project-setup.md` calls self-eval "standalone". In another project it has no rubric. Ship it or scope it?

- **Read:** `skills/self-eval/SKILL.md:50`, `devcontainer-config/link-claude-home.sh:47`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Ship the rubric with the skill** | Move it to `skills/self-eval/references/` | One copy must stay canonical (the SI loop reads `docs/`) | Two copies drift if both are kept |
| **[2] Declare self-eval repo-only** | Skill stops with a clear message when the rubric is missing; the guide stops calling it standalone | none | You lose self-eval in other projects |

- **Interim:** unchanged.


### Q-033 · claude-api-flat-file
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** Moved to `archive/docs/2026-09-21-claude-api.md`. (5928c47)

`skills/claude-api.md` is a flat file, so the harness never loads it as a skill (skills load from `skills/<name>/SKILL.md`), and its body is four lines with none of the reference material its description promises. Archive or build?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Archive it** | Move to `archive/` per the archive-don't-delete rule | none | You wanted the supplement and it's gone from view |
| **[2] Make it a real skill** | `skills/claude-api/SKILL.md` with real content | Content to write and keep current against the bundled skill | It shadows or conflicts with the bundled `claude-api` skill |

- **Interim:** unchanged; it is inert.


### Q-034 · agents-gemini-debug-defaults
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [2].** README AGENTS/Gemini/Antigravity setups link `global-instructions` (AGENTS also `skills`, `patterns`, `guides`). (8dfb0c3)

AGENTS.md:17 and GEMINI.md:17 send readers to "global-instructions/CLAUDE.md's Debugging defaults section", but the README's AGENTS and Gemini setups never install that file, so the debugging loop can't be reached there. How should those tools get it?

- **Read:** `AGENTS.md:17`, `GEMINI.md:17`, `README.md:44-52,82-87` (setup links). AGENTS.md:24 (`skills/`) and :63 (`guides/doc-freshness.md`) also point at directories the AGENTS setup never links.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Inline a short Debugging defaults section** | AGENTS.md and GEMINI.md carry the loop themselves; the sync test keeps them identical | A third copy to keep in step with global-instructions | Copies drift, as the commit rule did until this run |
| **[2] Link more in the README setups** | Add `global-instructions` (and `skills`, `guides`, `patterns` for AGENTS) to the link steps | A longer setup | Tools that don't follow file references still never see it |
| **[3] Point at the clone path** | Reference `~/claude-workflows/global-instructions/CLAUDE.md` | none | Breaks wherever the repo is cloned elsewhere |

- **Interim:** unchanged; non-Claude tools get the pointer, not the loop.


### Q-035 · guard-bash-claude-md-overblock
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** Bash HARD for CLAUDE.md only when qualified as global (`~/`, `$HOME/`, `${HOME}/`, literal home, `.claude/CLAUDE.md`, `global-instructions/CLAUDE.md`); a bare `CLAUDE.md` is SOFT. `install` stays a write primitive. Residual: `cd ~ && echo > CLAUDE.md` now gets an ask (when tainted), not a deny. Reopen if read-only `install` matches get annoying. (4c7a2bb)

In Bash, `guard-trusted-writes.py` hard-denies any command that has a write primitive AND mentions `CLAUDE.md` anywhere, even in a heredoc body, a comment or a quoted argument, and whether or not the session is tainted. The docstring says project CLAUDE.md is SOFT. Narrow it?

- **Why it's yours:** it is a security hook, and the extra blocking is the price of catching disguised writes. The 2026-09-12 security review endorsed "hard for Bash" for `global-instructions/CLAUDE.md`.
- **Read:** `hooks/guard-trusted-writes.py:10,16` (docstring) vs `:78-80` (`HARD_FRAG`). Observed in this run: a `cat > $SCRATCH/msg <<EOF` commit message that mentioned the file was denied, and so were `rg -n install CLAUDE.md` (`install` counts as a write) and `wc -l CLAUDE.md > out`. Edit/Write on the same file gets `ask` only when tainted, so Bash and the file tools disagree.
- **Related:** Q-026 (project `.claude/` gets *less* protection than intended; this entry is the opposite direction).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Narrow HARD to the global file** | HARD only for `~/`, `$HOME/`, `.claude/CLAUDE.md`; bare `CLAUDE.md` becomes SOFT (ask when tainted) | none | A disguised Bash write to a project CLAUDE.md in a tainted session gets an ask, not a deny |
| **[2] Keep it, fix the docstring** | The over-block is intended; the docs say so | Agents keep routing around it with Write + `git commit -F` | Agents learn to avoid Bash for anything that mentions the file |
| **[3] [1], and drop `install` as a write primitive** | Also stops read-only commands containing the word from matching | none | `install -m … src ~/.claude/…` is no longer caught by the keyword (the path check still applies to `>`) |

- **Interim:** unchanged. The workaround is to write the file with the Write tool and commit with `git commit -F`.


### Q-036 · si-review-archive-untracked
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [2].** `docs/working/reviews/round-*/` is gitignored; the comment calls it a local-only corpus. (ae19ab0)

`self-improvement.sh` copies each task's code-review rubric into `docs/working/reviews/round-N/<task>/` in the main tree, but that path is neither gitignored nor committed, so every run leaves untracked files behind. Commit or ignore?

- **Why it's yours:** the comment at `scripts/self-improvement.sh:~1405-1414` says the archive exists to build a review corpus for calibration, so ignoring it throws away what it was added for, and committing it grows the repo on every run.
- **Read:** `scripts/self-improvement.sh:1414-1443`; `require_clean_main` ignores untracked files, so this doesn't block the next run.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Commit it after each round** | The loop commits the archive with the round's other outputs | Repo grows by a few rubrics per task | Noise in `git log` if the corpus is never used |
| **[2] Gitignore it** | The archive stays local and out of `git status` | none | The corpus is lost with the checkout |

- **Interim:** unchanged; the directory accumulates untracked.


### Q-037 · si-survivors-parser-dead
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [3].** Survivors carry-over removed. (56b9883)

The self-improvement loop feeds round N+1 a list of surviving ideas that were never tried, but it only parses a `### Survivors` heading that divergent-design no longer produces, so the list is always empty. Revive, adapt or delete?

- **Read:** `scripts/self-improvement.sh:~500-510`. None of the 10 most recent archived `feature-ideas-round-*.md` has the heading; the latest writes `**Survivors for the tradeoff matrix:** #1, #2…`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Require the heading in the prompt** | The idea-generation prompt asks for `### Survivors` | none | The model drifts from the format again and it goes silently empty |
| **[2] Parse the current format** | Match the `Survivors for the tradeoff matrix` line | none | Breaks the next time divergent-design's output changes |
| **[3] Delete the feature** | Remove the carry-over block | none | Later rounds re-propose ideas that were never tried, as they do today |

- **Interim:** unchanged; the carry-over is silently empty, as it has been for at least 10 rounds.


### Q-038 · dd-path-c-no-consumer
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [2].** Path C files a `you: judgment` questions.md entry, and the round claim stays as the machine copy. Three more DD passages that promised morning-summary surfacing now point here, and decision 012 has a dated note. The other morning-summary references are per-task hypothesis surfacing, which is implemented, so they were left alone. (ebfdda8)

DD's Path C (tradeoff unclear, nobody present) says the round claim surfaces the unresolved choice to you through the morning summary, but decision 012 says nothing consumes round claims yet. The overnight choice is silently taken on the tentative pick. Where should it go?

- **Why it's yours:** option 1 is a feature build; option 2 adds entries to the queue you read.
- **Read:** `workflows/divergent-design.md` Path C (~:328); `docs/decisions/012-hypothesis-grammar-for-user-surfaced-evaluation.md:106` ("producer-only … not yet wired up"). Nothing under `scripts/` reads the `## Hypothesis: this round's claim` section.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Build the consumer** | Morning summary reads round claims and lists unresolved Path-C choices | none now; a feature to build and review later | A consumer for a path that fires rarely |
| **[2] Path C also files a questions.md entry** | The round claim stays as the machine copy; the choice reaches you through this file | One entry per unclear overnight decision | More entries in the queue |
| **[3] Leave it, fix the text** | DD stops claiming the choice reaches you | none | Overnight tradeoffs keep being decided without you |

- **Interim:** unchanged. Path C records the tentative pick and its axis of disagreement in the decision record only.


### Q-039 · fact-check-abstract-floor
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: pick one path.** High requires a `[deep-read]`. An all-`[abstract]` verdict caps at Medium, with no Medium→Low step. Deep-read instead of accepting the cap when the claim is load-bearing and could reach High, the verdict would otherwise be Inaccurate or Disputed, or the abstract is hedged or scoped differently. The "Low" verdict example is fixed. Never-read (`[inferred]`-only) sources still drop a tier, which your answer didn't cover. (be30668)

fact-check contradicts itself on whether abstract-only sources can support a Medium confidence. One rule downgrades every all-`[abstract]` verdict by a tier; other passages and two worked examples keep Medium. Which applies?

- **Read:** `skills/fact-check/SKILL.md:413-415` (the downgrade applies to every tier) vs `:177-180`, `:289` (deep-read is required for High only), `:375-376` (`[abstract]` is "sufficient for many Medium-confidence verdicts"), and examples `:440-441` (Medium on `[abstract]` only). Example `:442` also uses `Low` as a *verdict*, which is not one of the six verdicts. Fix that whichever option you pick.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] The deep-read floor applies to High only** | Drop the Medium→Low step from `:413-415`; the examples stand | none | Summary-only evidence keeps Medium ratings |
| **[2] The floor applies to every tier** | Keep `:413`; fix `:375` and re-rate examples `:440-442` | none | More Low/Unverified verdicts in draft-review rubrics |

- **Interim:** unchanged; agents get whichever paragraph they weigh.


### Q-040 · dd-misframing-hook
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [2] with escalation.** The Double Diamond owns misframing; if it also fails, run DSS. DSS's trigger now says so, and its "lean toward invoking when in doubt" line is removed. DD step 3 gained a "fewer than 3 survive" path. (2360a7e)

When DD's constraints contradict, DD sends you into its Double Diamond variant, while design-space-situating says to pause DD and run it instead. DD never mentions DSS. Which one owns misframing?

- **Read:** `workflows/divergent-design.md:~537` (misframing signal (c) → Double Diamond); `skills/design-space-situating/SKILL.md:38,~351` (the "Misframing signal from DD" trigger). Related: DD's step-3 gate requires 3-5 survivors, but `:198` expects "≤2 candidates survive" and gives no path for it.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] DSS is DD's misframing hook** | DD step 2(c)/3 call DSS; relax the 3-5 gate when DSS reframes | none | A heavier procedure for a signal that the Double Diamond already handles |
| **[2] The Double Diamond owns it** | DSS's trigger says "suggest DD's Double Diamond variant" instead | none | DSS loses its main automatic entry point |

- **Interim:** unchanged.


### Q-041 · code-review-merge-rule-gap
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1], conditioned.** Rules 4/5 count only ambers open without a qualifying note: a discoverable TODO (a code comment or a tracked follow-up) or a concrete revisit trigger. The Must Address definition in rubric.md and pr-prep's tier table require the same. (d659fa9, 6eb89cd)

The code-review next-action ladder has no rule for 0 🔴 with 3+ 🟡 where at most 2 lack author notes, which is normal after a review-fix iteration. Its required final line can't be derived. Does "merge" count every amber, or only unannotated ones?

- **Read:** `skills/code-review/references/chat-synthesis.md:146-152` (rule 4 needs >2 *un-noted* ambers; rule 5 needs ≤2 ambers *in total*).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Rule 5 counts unannotated ambers** | "0 🔴 AND ≤2 🟡 open without author notes" → merge | none | Heavily annotated reviews merge without a re-review |
| **[2] Rule 4 counts every amber** | ">2 🟡 total" → fix and re-review | More re-review rounds | Author notes stop being enough to reach merge |

- **Interim:** unchanged.


### Q-042 · code-review-contextual-severity
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** Contextual-critic mapping table added to rubric.md. (d659fa9)

The executable-defect channel maps a confirmed contextual-critic finding "as if filed by a core critic", but the severity table has columns only for the core critics. ui-visual's Critical/Major/Minor, test-strategy's Priority, and the critics with no per-finding scale (tech-debt-triage, dependency-upgrade) have no tier. What tier does each map to?

- **Read:** `skills/code-review/references/rubric.md:267-271` (mapping table), `:476-478` (channel rule); `skills/ui-visual-review/SKILL.md:382`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Explicit contextual row** | ui Critical→🔴, Major→🟡, else 🟢; test-strategy P1→🟡; scale-less critics→🟡 | none | A confirmed ui Major that breaks the layout only reaches 🟡 |
| **[2] Every confirmed executable defect is 🔴** | Execution proof overrides the native scale | none | Cosmetic but reproducible defects block the merge |

- **Interim:** unchanged; agents pick a core critic's column.


### Q-043 · code-review-arch-skip-blocks
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** A saved skip note satisfies 1(a). (d659fa9)

When code-review auto-selects architecture-review but the critic's own scope check skips ("implementation-only"), next-action rule 1(a) says "block on architectural review", overriding an otherwise clean rubric. Intended?

- **Read:** `skills/architecture-review/SKILL.md:107-142` (skip note); `skills/code-review/references/chat-synthesis.md:128-133` (rule 1(a)).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] A saved skip note satisfies 1(a)** | 1(a) fires only when the critic was excluded or failed | none | A wrongly-skipping critic hides a real structural issue |
| **[2] Keep the override, name the disagreement** | The synthesis states that the orchestrator and the critic disagree | A block to clear by hand each time | Clean diffs keep getting blocked |

- **Interim:** unchanged.


### Q-044 · override-log-immutable-rows
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** `Accepted-immutable` verdict; Reason starts `[auto: code-review]`; the only row the orchestrator may auto-append. Such rows also suppress later re-flags as settled (interim choice). (d659fa9)

For an Incorrect fact-check about an already-merged commit message, rubric.md tells the orchestrator to write an "accepted-immutable" row to `docs/reviews/override-log.md` mid-run. But the log is read-only during a run, and its required verdict fields have no valid value for such a row. May the orchestrator auto-append?

- **Read:** `skills/code-review/references/rubric.md:296-300`; `skills/code-review/SKILL.md:158`; `skills/code-review/references/override-log.md:20-37`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Yes, with a new verdict value** | Add `Accepted-immutable` to the override verdicts; the orchestrator may append only that kind | none | The log mixes human and machine rows |
| **[2] No — a rubric note instead** | Immutable findings go to a rubric "Accepted immutable" note, not the log | none | No cross-run record that the commit message is wrong |

- **Interim:** unchanged; the finding currently has nowhere valid to go.


### Q-046 · failure-analysis-fix-or-delete
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [2].** Moved to `archive/failure-analysis/` per the Q-021 archive-over-delete rule. Run `git rm -r archive/failure-analysis/` if you want it truly gone. (2cf5143)

`scripts/failure-analysis.sh` computes its re-attempt pass rate against its own definition (it counts attempts after approvals and null verdicts, and orders by a round number that restarts every run): it reports 16%, where the documented definition gives 39%. It also has no callers apart from its test, though the header says it is "for use in DD preambles". Fix or delete?

- **Read:** `scripts/failure-analysis.sh:95-130`; there are 59 null-verdict entries in the archived `round-*-report.json`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Fix the semantics** | Count only attempts after a rejection, skip null verdicts, order by timestamp | none | Maintaining a script nothing calls |
| **[2] Delete it and its test** | Remove the script | none | Re-deriving it if a DD preamble ever wants the number |

- **Interim:** unchanged; nothing consumes the wrong number.


### Q-047 · hypothesis-log-run-id
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: [1].** A `Run` column (last, so positional readers keep working) from `SI_RUN_ID`, defaulting to the run date. Lookups use it and fall back to newest-first. (a45f4a9)

Hypothesis-log rows record only a round number, and round numbers restart every self-improvement run, so the morning summary can't tell which run a row belongs to. This run's fix makes lookups scan newest-first (first archive containing the task id), which is right for current rows and wrong for a reused task id. Add a run id or date column?

- **Read:** `scripts/lib/si-morning-summary.sh` `_resolve_hypothesis_target`, `_days_since_round`; `docs/working/hypothesis-log.md` header.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Add a Run column** | The loop writes the run's date prefix; lookups use it | none | Old rows stay ambiguous (newest-first fallback) |
| **[2] Keep newest-first** | No schema change | none | A reused task id resolves to the wrong run |

- **Interim:** newest-first scan (si4/scripts).

### Q-023 · health-check-bats-scope
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** ANSWERED

**Answered 2026-09-20: fast first, block on red, then slow. Done.** Gate 5 runs `run-tests.sh --fast`; red fails the gate without running slow; green runs `--slow`. A `HEALTH_CHECK_SKIP_BATS` guard stops `health-check.bats` recursing (0ccbdb8). Runtime: fast ~103s, slow was ~441s, of which `health-check.bats` was 405s because its shared-output cache keyed on `$$` and never hit. It is now keyed on `BATS_FILE_TMPDIR`, so that file takes 42–60s depending on load and slow ~80–100s, with the same coverage (bd07c4e). Full health check measured 216s on the merged tip. `bats --jobs` isn't available (no GNU parallel), so parallelism is the next lever if it needs to be faster.

Should `health-check.sh` gate 5 run all bats suites, not just `test/skills/` and `test/hooks/`?

- **Why it's yours:** trades health-check runtime against coverage. A green health-check says nothing about 40 suites, including `link-claude-home-wiring.bats`, which a health-check comment claims hard-gates the wiring invariants.
- **Read:** `scripts/health-check.sh:336` (`check_bats`), `scripts/run-tests.sh --fast|--slow|--all`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Call `run-tests.sh --fast`** | Gate covers every `@category fast` suite | health-check slows by the fast-suite time | A slow-only regression still slips past |
| **[2] Call `run-tests.sh --all`** | Gate covers everything | health-check takes several minutes | You stop running it because it's slow |
| **[3] Leave it** | Only fix the misleading comment | none | A red suite sits unnoticed, as the format suites did until 2026-09-18 |

- **Interim:** unchanged; the full suite was run by hand in the 2026-09-18 improvement run.
- **Update (third 2026-09-18 run):** before ca04b98, `run-tests.sh` silently skipped untagged suites, and `link-claude-home-wiring.bats` was one of them, so [2] did not actually cover it. Both untagged suites are now tagged, and an untagged suite fails the runner. [2] now means what it says.


### Q-050 · guard-resolved-path-policy
**Needs:** you: judgment · **Opened:** 2026-09-21 · **Status:** ANSWERED

When a file-tool edit reaches a protected global file through its real path rather than through `~/.claude/…`, what should the guard hook do? On a bare-host install, `~/.claude/CLAUDE.md` links to your checkout's `global-instructions/CLAUDE.md`. Since a577546, Edit/Write on that checkout file is **denied**, with no approve option. Hook scripts linked one at a time get **no gate at all** at their checkout path (N12). The devcontainer is unaffected, because its targets are the read-only `/opt` payload.

- **Why it's yours:** it trades your ability to edit the global instructions in this repo on the host against how strongly the installed copy is protected.
- **Read:** `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter3.md` (R6, N12, and the iteration-4 gate at the end), `hooks/guard-trusted-writes.py:95-155`
- **Related:** Q-049. If deny rules turn out not to match, the "let the hook deny everything itself" redesign also applies.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Ask on real-path edits** | Real-path edits of protected files (the checkout CLAUDE.md and hook scripts) get an approve/deny prompt, whether or not the session is tainted. No deny rule names these paths, so the ask overrides nothing. | One prompt per edit to the global instructions or a hook in this repo | A prompt you approve by reflex |
| **[2] Deny (current branch)** | Keep a577546, document it, test it, and give hook scripts the same deny | You edit global instructions only outside Claude, or with the hook disabled | Blocks legitimate repo maintenance on the host |
| **[3] Defer, as before this branch** | No gate on real-path edits | none | A tainted session rewrites your global instructions through the checkout path |

- **Interim:** the branch holds [2]. It is not merged, so nothing on the host has changed. The review-fix loop is paused at its 3-iteration cap with decision `escalate`.
- **If the answer differs:** one change to the `hard-resolved` outcome in `classify_path`, plus tests, then a fourth review iteration that you authorize.

**Answered 2026-09-23: [2] is intended**, with this direction: "This repo's copy is the only global instruction file that should be editable, and the symlink connection should be deprecated in favor of edits getting checked in and propagated by copying after a human bless via install.sh."
Taken as two pieces of work. (a) Keep a577546's deny and extend it to per-file-symlinked hook scripts (N12), with tests and a note in `guides/bare-host-hook-wiring.md`, on branch `ans/guard-q048-q050`. (b) Replace the bare-host symlink install with copies that you bless through `install.sh`. Once `~/.claude` holds copies, the checkout files are no longer the live files, the deny stops firing on them, and the repo copy becomes the single editable source you described. (b) goes through RPI: a research doc and a plan, which you approve before any code changes.


### Q-048 · guard-cooccurrence-overblock
**Needs:** you: judgment · **Opened:** 2026-09-21 · **Status:** ANSWERED

Closing the review's bypasses of Q-035 needed a broader Bash rule, applied only to commands that contain a write (`>`, `tee`, `cp`, `mv`, `install`, an inline interpreter…). The literal fragments `.claude/hooks`, `.claude/settings`, `.claude/CLAUDE.md` and `managed-settings` are denied on their own. Beyond those: if the command names `CLAUDE.md`, it is denied when it also contains, anywhere, `~`, `$HOME`/`${HOME…}`, the home path, `.claude`, `global-instructions` or the config dir. If it names `settings*.json` or `hooks`, it is denied when it also contains `.claude`, `CLAUDE_CONFIG_DIR` or the literal config dir. False denies: a heredoc that writes a message file mentioning `CLAUDE.md` next to `HEAD~1`, and any Bash write into an agent worktree's `hooks/` (`/workspace/.claude/wt-*/hooks/…`). Keep it, or narrow it?

- **Why it's yours:** Q-035 asked to reconsider if the over-block got annoying. This trades catching disguised global writes for false denies.
- **Read:** `hooks/guard-trusted-writes.py` (c5a7c96), `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20.md` R1/A10

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep the co-occurrence rule** | Any indicator anywhere in the command → deny | Agents route those edits through Edit/Write and `git commit -F` | Occasional false denies in worktrees and commit messages |
| **[2] Exempt `.claude/wt-*` and `.claude/worktrees/`** | Worktree paths don't count as the `.claude` indicator | none | A worktree path used to smuggle a global write is missed |
| **[3] Narrow to path-position matches** | Only an indicator in the same shell word as the target counts | none | `H=~; … $H/CLAUDE.md`-style indirection gets through again |

- **Interim:** [1]. It is the fail-closed choice, and only takes effect once the hook is redeployed.
- **If the answer differs:** edit `_HOME_INDICATORS` / `_CFG_INDICATORS` and add tests for the exempted shape.

**Answered 2026-09-23: [2], exempt `.claude/wt-*` and `.claude/worktrees/`.** Implemented on branch `ans/guard-q048-q050`, with tests. The exemption does not cover a worktree segment followed by `..`, or a worktree under the home config dir. Two more false denies the same day fall outside [2]: a read-only `rg` whose regex contained `ln -s` next to `global-instructions/CLAUDE.md`, and a `python3` heredoc that edited this questions file because its text mentioned `.claude` and `hooks`.

**Withdrawn 2026-09-23 (user decision, review loop cap).** Three review passes on `ans/guard-q048-q050` each found new ways past the text-matched exemption into a `.claude` config dir:
- pass 1: quote-split `..`, and a symlinked `wt-*`;
- pass 2: `cd ..` / `../`, and same-command root swaps;
- pass 3: `-t..`, `.{,.}`, `env -C`, `cp -P`, `git checkout`, `tar -x`, `find -delete`.

The user chose fix-first, then the whole-command gate, then dropping the exemption. Commit 3e9e448 restores 970e525's Bash tier for worktree paths and keeps every bypass as a deny test. So the Q-048 false denies stand: in a worktree, agents write policy-named files with Edit/Write. Rubric: `docs/reviews/code-review-rubric-2026-09-23-ans-guard-q048-q050.md` on that branch. A real fix belongs to the file-identity guard redesign, not to more text matching.


### Q-011 · mathlib-cache-host
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** ANSWERED

What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.)

- **Attempt 2026-09-17 — your run was against the right file, and the answer is that the question's shape is wrong.** `rg -o 'https://[^"]*' .../mathlib/Cache/Requests.lean` returned exactly two strings: a bare `https://` and `https://github.com/leanprover-community/mathlib4.git`. A bare prefix means the cache URL is **assembled at runtime**, not written down as a constant — which is also what your sketched docstring describes (`MATHLIB_CACHE_GET_URL` → `--cache-from` → `MATHLIB_CACHE_FROM` → `defaultContainersForRepo repo`). So there may be no single hostname to list: the host comes from a per-repo container list, and an allowlist entry has to name whatever `defaultContainersForRepo` resolves to for mathlib4.
- **Attempt 2026-09-18: half answered, and the entry stays open.** Your paste (`docs/human-author/answers-9-18-26.txt`) settles which *kind* of host it is. `Cache/Marker.lean:34` builds URLs as `s!"{container.azureURL}/m/{normalizeRepo repo}/{sha}"`, so every container is an **Azure Blob** endpoint, not ghcr.io or another registry, and the registry branch of "What I do with it" is ruled out. It does not show the storage-account hostname. `head -60` cut the output off before the definitions of `defaultContainersForRepo` and `azureURL`, where that literal lives. I could guess `lakecache` from the old code, but the VERIFY comment asks for the name to be *seen*, so I am not closing on a guess. Also worth checking: "widens the lookup chain" suggests several containers. An Azure container is a path under one account, so they probably share one host. If they span accounts, the allowlist needs each account.
- **Read:** `devcontainer-config/egress/lean.txt` (the `lakecache.blob.core.windows.net` entry and its ACCEPTED RISK note)
- **The paste**, narrowed to the one missing literal:

```bash
M=verifier/lean-project/.lake/packages/mathlib     # any mathlib4 checkout works
rg -n 'blob\.core\.windows\.net|azureURL|def defaultContainersForRepo' -A6 "$M"/Cache/*.lean
```

- **What I do with it:** if every hostname it prints is `lakecache.blob.core.windows.net`, the VERIFY comment is discharged and the entry stays as it is. If it prints another account, `egress/lean.txt` swaps to it (or lists each one). The ACCEPTED RISK note holds either way, since every candidate is Azure Blob.
- **Interim:** `lakecache.blob.core.windows.net` stays listed, carrying its VERIFY comment. A wrong entry degrades to "stays blocked", never to a wider allowlist, so the cost of being wrong is a slow first build rather than an exposure.
- **If the answer differs:** correct `egress/lean.txt`, re-install, re-bless.

**Answered 2026-09-23 (`docs/human-author/answers-9-23-26.txt`): `lakecache.blob.core.windows.net`, one account.**
`Cache/Infra.lean:102-103` defines `azureURL c = "https://lakecache.blob.core.windows.net/{c.azureContainerName}"`,
so all five containers (master, forks, nightly-testing, pr-toolchain-tests,
legacy) are paths under that one storage account, and the "several accounts"
worry does not apply. `defaultContainersForRepo` (`:155-161`) gives mathlib4
`[.master, .legacy]`. Every hostname the rg printed is `lakecache`. The entry in
`egress/lean.txt` stays; its VERIFY comment now records the observation and the
re-check command. Its ACCEPTED RISK note now calls the cross-account fronting
question inconclusive (Q-045, followed up in Q-053).


### Q-045 · sni-proxy-domain-fronting
**Needs:** you: terminal · **Opened:** 2026-09-18 · **Status:** ANSWERED

The SNI proxy checks only the ClientHello SNI and splices the encrypted stream, so a client can send an allowlisted SNI with a different HTTP `Host` and reach another tenant on a CDN that routes by Host. The docs say exact-name entries have "no such residual". Accept and document it, or test the front ends first?

- **Why it's yours:** it is the egress-confinement threat model; closing it would need TLS interception, which the design rules out.
- **Read:** `devcontainer-config/cc-sni-proxy.py:19-29`; the SNI PROXY block's RESIDUAL text in `devcontainer-config/init-firewall.sh`. Reasoning only: the sandbox has no egress to test any CDN.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Document the residual** | Correct the "no such residual" claim and name domain fronting | none | The android/lean profiles may allow fronting to arbitrary tenants |
| **[2] Test first, then decide on the profiles** | Run `curl --connect-to` with a mismatched Host through the android and lean front ends on the host | ~10 min at your terminal | none — the answer then decides whether those entries stay |

- **Interim:** unchanged; the docs still over-claim.
- **Answered 2026-09-20: [2], test first.** Rerouted to `you: terminal`. Run this on the **host** (the sandbox has no egress). For each allowlisted android/lean name it sends that name as SNI with the `Host` header of a tenant on a large CDN, and prints the fronted response next to the tenant's own response. **Fronting works for a pair when the two lines carry the same title** (or the same non-error status and server). A 421, 403, 404 or a different title means the front end refuses. Paste the whole output back.

```bash
b=$(mktemp); probe() { r=$(curl -sS -m 10 -o "$b" -w '%{http_code} %header{server}' "$@" 2>&1); t=$(grep -o -i -m1 '<title>[^<]*' "$b" | head -c 50); echo "$r $t"; }
for sni in dl.google.com maven.google.com repo.maven.apache.org repo1.maven.org services.gradle.org plugins.gradle.org elan.lean-lang.org release.lean-lang.org releases.lean-lang.org reservoir.lean-lang.org lakecache.blob.core.windows.net; do
  for tgt in www.google.com www.python.org www.cloudflare.com github.com azureopendatastorage.blob.core.windows.net; do
    printf '%-32s Host:%-44s fronted=[%s] direct=[%s]\n' "$sni" "$tgt" "$(probe -H "Host: $tgt" "https://$sni/")" "$(probe "https://$tgt/")"
  done
done; rm -f "$b"
```

- **What I do with it:** every front end refuses → the docs name domain fronting as a residual that the tested profiles do not carry (with the test date). Any pair succeeds → that profile's entry gets an ACCEPTED RISK note or is removed, which is your call on the evidence, and the "no such residual" line is corrected either way.

**Answered 2026-09-23 (test output in `docs/human-author/answers-9-23-26.txt`): fronting works through four of the eleven names.**
Reading: a pair fronts when the fronted response matches the target's own
response, or when an error page shows the front end routed by Host to another
tenant. The `%header{server}` column printed literally (that curl predates
`%header{}`), so only the status and title count.

| SNI | Result | Evidence |
|---|---|---|
| `dl.google.com`, `maven.google.com` | **fronts to Google-hosted tenants** | Host www.google.com → `200 Google`, same as direct; non-Google hosts → Google's own 404 |
| `elan.lean-lang.org` | **fronts to GitHub Pages sites** | every non-Pages Host → "Site not found · GitHub Pages": routing is by Host |
| `reservoir.lean-lang.org` | **fronts to other tenants on its platform** | Host github.com → `200 "Appaji www.Ark Tech Infra"`, an unrelated third-party site |
| `repo.maven.apache.org`, `repo1.maven.org`, `services.gradle.org`, `plugins.gradle.org`, `release.lean-lang.org` | refuses | 403 for every target |
| `releases.lean-lang.org` | ignores Host | nginx default page for every target |
| `lakecache.blob.core.windows.net` | inconclusive | 400 for non-Azure hosts; for the other Azure account, 404 vs 400 direct. The responses differ, but neither shows a routing decision |

Five targets were tried. "Refuses" means the front end rejected a mismatched
SNI/Host for all five, not that it would for every tenant.
`storage.googleapis.com` was not probed; it is inferred reachable because the
Google front end served another Google property.

**Done (agent):** the "exact-name entries have no such residual" claim is
corrected in `init-firewall.sh` (the SNI proxy RESIDUAL comment) and in
`guides/cc-isolated-usage.md`, which also no longer says the proxy closes
`storage.googleapis.com` behind `dl.google.com`. `egress/android.txt` and
`egress/lean.txt` state the result beside each entry. All four edits are
comment or doc only, so the admitted set is unchanged. Per this entry's "What
I do with it", keeping or removing the fronting entries is your call: Q-051
(lean) and Q-052 (android). The Azure probe is Q-053.


### Q-051 · lean-fronting-entries
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** ANSWERED

Two `lean` names front to tenants nobody listed (Q-045): `elan.lean-lang.org` reaches any GitHub Pages site, and `reservoir.lean-lang.org` reached an unrelated third-party site. Keep them or drop them?

- **Why it's yours:** Q-045 left keeping or dropping a fronting entry to your judgment on the evidence.
- **Read:** `devcontainer-config/egress/lean.txt` (the header's DOMAIN FRONTING note and each entry's comment); Q-045's table in the archive
- **What each is for:** elan is baked into the image (log #51), and toolchains come from `release.lean-lang.org`, which refuses fronting. So `elan.` serves only elan's installer and self-update [inferred from lean.txt's comments, not tested]. `reservoir.` serves only a lakefile `require` by bare package name; mathlib's dependencies are git requires that resolve through GitHub.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Drop both** | Remove both lines from `lean.txt`, then install and re-bless | One install + bless | A bare-name `require`, or an elan self-update, fails loudly in-container until the line is restored |
| **[2] Drop `elan.`, keep `reservoir.`** | Keep the index for bare-name requires, with an ACCEPTED RISK note | One install + bless | A session can reach any tenant on reservoir's hosting platform, possibly one that runs server code |
| **[3] Keep both, accept the risk** | Only the ACCEPTED RISK notes change (comments, no re-bless) | none | Two open channels stay in the lean profile |

- **Interim:** both stay listed, with the residual written beside them. The profile is opt-in (`--profile lean`), so only lean sessions carry it.
- **If the answer differs:** a one-line removal per entry, then `install.sh` and a re-bless. The live-verify gate will ask for a trailer, because removing a line is a non-comment change.

**Answered 2026-09-23: [1], drop both.** `elan.lean-lang.org` and `reservoir.lean-lang.org` are removed from `egress/lean.txt`. The header records why, and the symptom to expect if one turns out to be needed. `guides/cc-isolated-usage.md` now tells a bare-name `require` to use a git URL. `test/cc-isolated-functions.bats` "profiles compose" now asserts `release.lean-lang.org` (90/90 pass). It takes effect after `install.sh` + re-bless + `cc-isolated --probe-only`; the commit carries `Live-verified: no`.


### Q-052 · android-google-fronting
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** ANSWERED

`dl.google.com` and `maven.google.com` front to Google-hosted tenants (Q-045: Host www.google.com got Google's home page), which probably includes writable `storage.googleapis.com`. Both are Google's Maven host (`google()`), which Android builds need. Accept the residual, or drop Google Maven from the profile?

- **Why it's yours:** it trades the egress threat model against a working Android profile. `android.txt` accepted "the whole GFE surface" when the firewall matched only IPs. The SNI proxy was expected to narrow that, and it does not.
- **Read:** `devcontainer-config/egress/android.txt` (ACCEPTED RISK block)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Accept and keep** | The ACCEPTED RISK note, updated today, stands | none | An android session has an outbound channel to any Google-hosted service |
| **[2] Drop both names** | `google()` artifacts must come from the Gradle cache baked in at image build | Android builds that resolve new Google artifacts fail until an image rebuild | The profile works only for projects whose Google dependencies are baked in |

- **Interim:** [1]. Only the comment changed. The profile is opt-in.
- **If the answer differs:** remove the two lines, install, re-bless (live-verify trailer).

**Answered 2026-09-23: [1], accept and keep.** `egress/android.txt`'s ACCEPTED RISK note records the decision.


### Q-053 · azure-blob-fronting-probe
**Needs:** you: terminal · **Opened:** 2026-09-23 · **Status:** ANSWERED

Does the Azure Blob front end behind `lakecache.blob.core.windows.net` route a different storage account's `Host`? Q-045's root-path probe was inconclusive because it compared two error pages. This probe compares real container listings. An attacker's own storage account with a SAS token would be a write sink, so the answer matters more here than for a read-only mirror.

- **Read:** `devcontainer-config/egress/lean.txt` (lakecache ACCEPTED RISK note); Q-045 in the archive
- **The paste** (on the host):

```bash
A=lakecache.blob.core.windows.net; B=azureopendatastorage.blob.core.windows.net
p1='/mathlib4-master?restype=container&comp=list&maxresults=1'   # lakecache's own public listing (Cache/Requests.lean:1242)
p2='/mnist?restype=container&comp=list&maxresults=1'             # a public Azure Open Datasets container
show() { curl -sS -m 10 -w ' [%{http_code}]' "$@" 2>&1 | tr -d '\n' | head -c 220; echo; }
echo "1 lakecache direct : $(show "https://$A$p1")"
echo "2 other acct direct: $(show "https://$B$p2")"
echo "3 fronted          : $(show -H "Host: $B" "https://$A$p2")"
```

- **How to read it:** line 1 must show an `<EnumerationResults` listing and `[200]`. Line 2 must as well; if it doesn't, the container name is wrong and the run proves nothing, so paste it back. If line 3 matches line 2 (a `mnist` listing), fronting works across accounts. If line 3 is an error (`ResourceNotFound`, `InvalidQueryParameterValue`, 400 or 404), the front end stays within the SNI's account.
- **What I do with it:** refuses → the lakecache ACCEPTED RISK note is confirmed as written, with the date. Fronts → a new judgment entry on keeping lakecache, which is the entry that makes the lean profile usable at all.
- **Interim:** lakecache stays listed; `lean.txt` calls it inconclusive.

**Answered 2026-09-23 (`docs/human-author/answers-9-23-26-2.txt`): the front end refused this account.** Line 3 returned `AccountNotFound`, while line 2 (the same request direct) listed `mnist`. So SNI lakecache does not reach `azureopendatastorage`. The error code means the front end looked up the Host's account and did not find it. That suggests the lookup is scoped to the storage cluster serving lakecache, so an account on that same cluster might resolve [inferred, not tested]. That residual is far narrower than a CDN front, and the lakecache note records it as accepted. Line 1 (the lakecache control) returned `ResourceNotFound`, so that container listing is not public under that name. It does not affect the reading, because line 2 is the control that mattered. No new judgment entry is needed, since the probe did not show fronting.


### Q-054 · copy-install-approach
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** ANSWERED

Approve the plan that replaces the bare-host symlink install with blessed copies (your Q-050 direction), and pick how `install.sh` exposes the host targets.

- **Why it's yours:** RPI's plan gate. No code is written until you approve. The shape is a design choice that the non-interactive run left tentative (Path C, 70%).
- **Read:** on branch `ans/copy-install-plan` (05f92e5): `docs/working/plan-copy-install-bare-host.md` (7 steps), `research-copy-install-bare-host.md` (the DD matrix), `checkpoint-copy-install-bare-host.md`
- **Common to every option:** existing symlinks show in the diff as `REPLACE symlink … with a copy` and are moved to `.claude-workflows-backup/<stamp>/`, never deleted. `hooks/` and `scripts/` are copied whole. `settings.json` is not touched; a reminder prints when `wiring.json` changed. Three hazards confirmed in scratch drove this design: `diff -ruN` through a symlink shows nothing, `cp -r` onto a directory symlink writes into the checkout, and `rm -rf link/` empties the checkout.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Target flags, one per run (A)** | `install.sh --claude-home` / `--gemini`; a plain run is unchanged | Remember the flag | Forgetting it leaves `~/.claude` stale, with no error |
| **[2] Plain run offers every target (D)** | One run, a separate y/N per target | A longer run each time | An existing command changes what it does |
| **[3] Separate host-install script (B)** | A new script beside `install.sh` | A second script, which needs its own commit gate (decision 035) | Two installers drift apart |
| **[4] Not yet** | Revise the plan; say what to change | none | none |

- **Interim:** nothing implemented. Both `/pre-mortem` and `/architecture-review` fire for this plan and have not run. I run them before implementation unless you say to skip them.
- **If the answer differs:** [2] or [3] changes steps 2-4 of the plan, not the tests' intent.

**Answered 2026-09-23: [2], a plain run offers every target.** Reason given: "I *will* forget to add flags to install.sh, and it already replaces some files in place instead of symlinks." Taken as plan approval with shape D in place of A. The plan is revised to D before implementation, and `/pre-mortem` and `/architecture-review` run on the revised plan.


### Q-055 · gemini-install-target
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** ANSWERED

Do you still use Gemini (CLI or Antigravity)? The README symlinks six entries into `~/.gemini`, and the copy-install plan has a step for them.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Yes, copy them too** | Plan step 4 stays; `~/.gemini` gets the same blessed copy | none | none |
| **[2] No, drop Gemini** | Step 4 is dropped and the README's Gemini block is removed | none | Re-adding it later is one plan step |

- **Interim:** step 4 is planned but can be dropped. Copying to Windows through `/mnt/c/Users/<you>/.gemini` is untested.

**Answered 2026-09-23: [2], drop Gemini.** Plan step 4 is dropped. The README's Gemini block is removed as part of the README step.


### Q-056 · host-install-tty-only
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** ANSWERED

Should the host install targets refuse `--yes` and require an interactive terminal? The agent runs on the same host as `~/.claude` and could run the installer itself.

- **Why it's yours:** it trades convenience against the one property that makes "bless" mean a human read the diff.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Refuse `--yes`, require a TTY (planned)** | The host targets run only interactively | No scripted installs | Claude Code's Bash tool may have a TTY after all [untested], so this check alone wouldn't stop an agent |
| **[2] Allow `--yes`, as the devcontainer path does** | Same behavior as today's install | none | An agent can bless its own edit into `~/.claude` |

- **Interim:** [1] is in the plan. A test step checks whether the Bash tool has a TTY before relying on it.

**Answered 2026-09-23: [1].** Host targets refuse `--yes` and require a TTY. The plan's test step checks whether Claude Code's Bash tool has a TTY before relying on that.


### Q-057 · host-install-foreign-files
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** ANSWERED

When a directory the install owns (for example `~/.claude/skills`) holds files the repo does not have, should the install move them to the backup, or leave them in place?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Move them to the backup (planned)** | `~/.claude/skills` matches the repo exactly after install; extras sit in `.claude-workflows-backup/<stamp>/` | Hand-installed skills disappear until you restore them | A skill you added outside the repo stops loading |
| **[2] Leave them** | The install adds and overwrites repo files only | none | Files deleted from the repo live on in `~/.claude` |

- **Interim:** [1], and the diff lists every file it would move.

**Answered 2026-09-23: [1].** Foreign files in install-owned directories move to `.claude-workflows-backup/<stamp>/`, and the diff lists each one.


### Q-049 · deny-rule-absolute-path-form
**Needs:** you: terminal · **Opened:** 2026-09-21 · **Status:** ANSWERED

Do the live deny rules match at all? `link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings*.json)`, with one leading slash. If Claude Code reads `/path` as relative to the settings file and needs `//path` for an absolute path (which is my recollection of its docs, unverified because the sandbox has no egress), every global-dir deny rule matches nothing. `guard-trusted-writes.py` then defers to rules that aren't there, so file-tool edits to global settings, hooks and CLAUDE.md get no gate. This predates this branch. The 2026-09-21 iteration-2 review raised it as N3.

- **Read:** `hooks/wiring.json` deny block, `devcontainer-config/link-claude-home.sh:137` (the `{{CLAUDE_DIR}}` substitution), `~/.claude/settings.json` (live rules)
- **Run 1 (2026-09-23): INCONCLUSIVE.** Untrusted project settings dropped the `allow` rule.
- **Run 2 (2026-09-23): `control`, `single` and `double` all wrote the file.** The control worked, so `--settings` loaded and the allow applied. But neither `Write(/abs)` nor `Write(//abs)` stopped a Write. There are two readings, and this run can't tell them apart: (a) `Write(<path>)` is not a path-matched rule, and file paths are matched only by `Edit(<path>)`, which is also the form the live rules use; or (b) deny rules from `--settings` are not applied. Run 2 therefore tested the wrong form. It says nothing yet about the live `Edit(...)` rules.
- **Run 3 paste** (on the host; five tiny headless calls). `denyall` denies Write outright, which proves deny rules from `--settings` apply at all. `edit1`/`edit2` are the live form, with one and two leading slashes:

```bash
for form in control denyall edit1 edit2 edithome; do
  d=$(mktemp -d); td=$(mktemp -d); t=$td/target.txt
  case $form in
    control) deny='' ;;
    denyall) deny='"Write"' ;;
    edit1) deny="\"Edit($t)\"" ;;
    edit2) deny="\"Edit(/$t)\"" ;;
    edithome) td=$(mktemp -d "$HOME/.q049.XXXXXX"); t=$td/target.txt; deny="\"Edit(~/${td#$HOME/}/target.txt)\"" ;;
  esac
  printf '{"permissions":{"allow":["Write"],"deny":[%s]}}\n' "$deny" > "$d/s.json"
  out=$(cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --settings "$d/s.json" --add-dir "$td" --output-format json 2>"$d/err")
  turns=$(printf '%s' "$out" | jq -r '.num_turns // 0' 2>/dev/null); turns=${turns:-0}
  if [ -e "$t" ]; then r="file written"; elif [ "$turns" -ge 2 ]; then r="not written (claude ran $turns turns)"; else r="INCONCLUSIVE, claude did not run: $(head -c 200 "$d/err")"; fi
  echo "$form: $r"
  case $form in edithome) rm -rf "$td" ;; esac
done
```

- **How to read it:** `control` must say "file written" and `denyall` "not written". Otherwise the run proves nothing, so paste it back. With those two good:
  - `edit1: not written` → the live single-slash rules work. N3 is closed.
  - `edit1: file written`, `edit2: not written` → only `//` is absolute, so the live rules match nothing today.
  - `edit1` and `edit2` both "file written" → no absolute form works in `--settings`. `edithome` (the `~/` form) is the fallback to try.
- **What I do with it:** single-slash works → close N3. Otherwise `link-claude-home.sh` emits the form that works, a test pins it, and you re-install and re-bless. **Whatever the result, I recommend the guard redesign the review proposed:** the hook returns `deny` itself for HARD paths instead of deferring to rules. Run 2 already shows how easily a rule can silently match nothing.
- **Interim:** unchanged. The devcontainer's `/opt` payload is read-only, which bounds the hooks and CLAUDE.md exposure there. `~/.claude/settings*.json` is not bounded that way.

**Answered 2026-09-23, run 3: single-slash rules match nothing; `//abs` and `~/rel` work.**

| Run | File | Reading |
|---|---|---|
| `control` (no deny) | written | allow applied |
| `denyall` (`Write`) | not written | deny rules from `--settings` are applied |
| `edit1` `Edit(/abs)` | **written** | single slash is not absolute: the live form matched nothing |
| `edit2` `Edit(//abs)` | not written | double slash is absolute |
| `edithome` `Edit(~/rel)` | not written | `~/` works |

The three "INCONCLUSIVE, claude did not run" labels are a bug in my classifier, not in the run. stderr was empty, so claude started cleanly. A denied Write evidently ends in fewer than two `num_turns`, and my rule read that as "did not run". The signal is the file: it appeared exactly where no rule, or a single-slash rule, stood.

**Consequence.** Every `{{CLAUDE_DIR}}` deny rule `link-claude-home.sh` has merged was a no-op: settings, hooks, `CLAUDE.md`, and `Read(.credentials.json)`. That means guard-trusted-writes' HARD tier, which defers to these rules for the file tools, gave no gate there (review N3, confirmed).

**Done (agent):**
- `hooks/wiring.json` now writes its config-dir rules as `/{{CLAUDE_DIR}}`, so they resolve to `//abs`.
- `link-claude-home.sh` prunes the legacy single-slash forms on merge.
- `test/link-claude-home-wiring.bats` asserts the `//` form, including the credentials rule, and adds a pruning test. The pruning test fails against the old linker. 159/159 pass across that file and `test/hooks/`.
- **Takes effect** after install, re-bless and a container start.
- **Bare host:** a hand-merged `~/.claude/settings.json` still holds the single-slash rules. Re-merge with the guide's `jq` one-liner (it reads the fixed `wiring.json`), or edit the slashes by hand.
- The guard redesign, where the hook returns `deny` itself for HARD paths, is still recommended: this bug went unnoticed for weeks.


### Q-058 · installer-trust-model
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** ANSWERED

The copy-based bare-host install (`ans/copy-install`, parked at 9ae6e46) runs as your user, the same user as the agent. Three review passes kept finding the same root: anything that uid can write between the review and the swap reaches `~/.claude` unreviewed. Which trust model should the installer be built on?

- **Why it's yours:** it decides what "bless" guarantees on a bare host, and what you must do at install time.
- **Read:** on `ans/copy-install`, `docs/reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md` (composition cluster 1 states the root), `docs/decisions/037-bare-host-copy-install.md`, `docs/decisions/035-install-sh-gating.md`.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Stage behind `denyWrite ~/.claude`** | Stage, review, hash and install only from copies under the destination, which a sandboxed agent cannot write; re-hash right before the swap; refuse without perl; harden git (no fsmonitor or hooks). | Relies on your sandbox config carrying `denyWrite ~/.claude` | An unsandboxed agent, or a missing deny, reopens every gap |
| **[2] Install only when no agent can run** | The installer refuses while any `claude` process is running for your user (or asks you to close them), then runs [1]'s checks. | Close sessions before each install | A process the check misses (another host, renamed binary) |
| **[3] Separate user** | The installed copies are owned by a second account (or root) that agents never run as; the install runs through `sudo -u` after the review. | One-time account setup; a sudo prompt per install | Setup friction; WSL/macOS differences |
| **[4] Keep the symlinks** | Drop the copy install; the guard's resolved-path deny (merged in 5bd5c66) protects the checkout copies of linked files. | Global files stay uneditable from Claude on the host | Your Q-050 goal (the repo copy is the editable source) is not met |

- **Interim:** nothing changed on your host. The bare host still uses the README's symlink install, and the merged guard denies Claude's file tools on the linked checkout files. The copy-install branch stays unmerged; its fixes for R1, R3, R4 and R5 are kept for reuse.
- **If the answer differs:** [1]–[3] restart from `ans/copy-install` with a plan revision and one full review; [4] retires the branch and decision 037.

**Answered 2026-09-23: [2], install only when no agent can run, and cc-isolated counts.** Agents in cc-isolated containers write the checkout, including `.git`, through the bind mount, so a running container is an agent that can act during the install window. The check therefore covers both host `claude` processes for your user and running cc-isolated containers. Implementation restarts from `ans/copy-install` with a plan revision.



### Q-059 · arith-eval-bash-grant
**Needs:** you: judgment · **Opened:** 2026-09-24 · **Status:** ANSWERED

Should arithmetic-eval's LLM fixture runs get a restricted Bash tool so the model can actually run the evaluator?

- **Why it's yours:** it's the first fixture run that can execute shell, which breaks the harness's "no Write" rule unless it's constrained. That's a trust-boundary call.
- **Read:** docs/working/plan-skill-fixtures-batch4.md step 5; research-skill-fixtures-batch4.md Gotchas

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Gate tests only** | Deterministic tests of the extracted Mode 1 evaluator and check.py (step 4). No LLM set, so "does the model use the evaluator" stays untested. | None | The skill's main risk (mental math instead of the evaluator) stays unmeasured |
| **[2] Restricted Bash set** | Adds step 5: repo mode, `--allowedTools` limited to python3 invocations, transcript check that python3 ran. A /pre-mortem runs first. | Review one pre-mortem | A too-loose allow pattern lets a fixture run write or read outside the temp repo |

- **Blocks:** step 5 only
- **Update 2026-09-24:** since a75ba3e, fixture runs pass `--restricted --safe-mode`, and runner-contract.bash allows only Read, Grep, Glob, WebSearch, WebFetch and Agent. [2] therefore also means adding a scoped Bash entry to that allowlist. `--restricted` confines the file tools to the temp dir, but per the CLI help it does not sandbox shell commands, so the pre-mortem in [2] still applies. [1] is unaffected.
- **Interim:** [1]. Step 4's gate tests land either way.
- **If the answer differs:** add step 5 after step 2; nothing is redone.

**Answered 2026-09-25: neither.** "This feels like a false dichotomy; can we not test via something like equivalence of the proposed command to some static script? Run divergent design on this." The divergent-design pass is in `docs/working/dd-arith-eval-bash-grant.md` (commit 3376144). Its options are re-asked as Q-063.


### Q-060 · orchestrator-fixture-depth
**Needs:** you: judgment · **Opened:** 2026-09-24 · **Status:** ANSWERED

How far should batch 4 go for code-review and draft-review?

- **Why it's yours:** it trades compute and your review time against coverage. Each fixture run costs about 8 (code-review) or 4-6 (draft-review) agent runs, and draft-review's fact-check needs web egress this sandbox lacks.
- **Read:** docs/working/plan-skill-fixtures-batch4.md step 9; research doc "Feasibility spike"

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Defer** | No sets. The parent plan records why. The existing contract/format suites stay the coverage. | None | Orchestration regressions (skipped stage, silent gap) stay invisible until a real review misfires |
| **[2] One smoke fixture each** | tree-mode repo with critic SKILL.md copies. Checks `subagents_min` and one planted defect surfacing in the rubric. draft-review's prompt says web is unavailable. | Generating costs ~15 agent runs total, when you choose to run it | Smoke passes while per-critic behavior regresses |
| **[3] Full sets (5-7 each)** | Batch 1-3 shape | ~80+ agent runs per full generation, plus longer review | Spend is out of proportion to the signal, since the critics already have their own sets |

- **Blocks:** step 9 only
- **Interim:** [1]
- **If the answer differs:** step 9 is built after step 3; nothing is redone.

**Answered 2026-09-25: [1].** Defer; the interim stands. The plan records step 9 as not built.


### Q-061 · host-stage-review-copies
**Needs:** you: judgment · **Opened:** 2026-09-25 · **Status:** ANSWERED

The host target's stage can be swapped for the review and swapped back before y (the re-review's R2, 6/6 runs). Do we move the review onto the copies under `~/.claude`, or accept this under your Q-058 answer?

- **Why it's yours:** Q-058 [2] made "no agent runs during the install" the trust model. [1] adds option [1] from Q-058 (sandbox-protected staging) on top of it for the host target. That goes past what you chose, even though it only adds protection.
- **Read:** `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md` R2; `docs/reviews/security-review-2026-09-24-copy-install-q058.md` F1 (with the SP1 probe) and F8

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Review the installed copies** | Stage into `~/.claude/.cw-new.*` (denyWrite) before the review, review those, then hash-check and swap them. The host target stops depending on the gate. | Nothing now. The review diff reads from a different path. | About 15 extra installer lines to maintain, guarding a case the gate is meant to prevent |
| **[2] Accept it; correct decision 037** | 037:66 is rewritten to say the hash only catches edits that persist, and a writer that swaps and restores is caught only if the gate sees it at y | None | An unsandboxed or unseen writer can get an unreviewed hook into `~/.claude`, which runs in every session |

- **Blocks:** merging `skill-fixtures` to main (you asked for merge after review; R2 is red until this is settled)
- **Interim:** [1] is implemented with the other review fixes, so the merge isn't blocked. It hardens the installer and doesn't loosen anything. 037 records it as provisional pending this answer.
- **If the answer differs:** [2] reverts that one commit and applies the 037:66 rewrite. Nothing else depends on it.

**Answered 2026-09-25: [1].** The interim stands. Decision 037 no longer marks it provisional.


### Q-062 · leftover-helper-is-agent
**Needs:** you: judgment · **Opened:** 2026-09-25 · **Status:** ANSWERED

Under Q-058 [2], does a background process an agent session left running (a detached helper, a loop driver between `claude` iterations) count as "an agent"?

- **Why it's yours:** it sets the scope of your own trust-model answer. The gate only recognizes Claude-shaped command lines, so "yes" needs a broader, noisier check.
- **Read:** the re-review's A2; security review F3 (SP2 and P4 probes)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] No; document it** | 037 lists leftover non-Claude processes as a residual. Stopping them before an install is on you. | Remember to kill loop drivers before installing | A leftover helper writes during the install, unseen |
| **[2] Yes; widen the gate** | Also refuse any other process of your uid whose working directory is inside the checkout, and name it | Occasional refusals naming an editor or shell sitting in the repo; close it and re-run | Nuisance refusals every time a terminal is open in the repo |

- **Blocks:** nothing (A2 carries this entry as its author note)
- **Interim:** [1]. The cheap fail-closed fixes land either way: a gate before host staging, and a wider regex covering the versioned native path and the Agent SDK CLI.
- **If the answer differs:** [2] adds one detector to `agent_gate` and a test. Nothing is redone.

**Answered 2026-09-25: [2].** `agent_gate` now also refuses any other process of your uid whose working directory is in the checkout, read from `/proc`. install.sh's own ancestors and children are exempt, and it refuses when `/proc` can't be read (T88–T90). Decision 037 is updated.


### Q-063 · arith-eval-evaluator-check
**Needs:** you: judgment · **Opened:** 2026-09-25 · **Status:** ANSWERED

How should arithmetic-eval's LLM fixtures check that the model uses the evaluator? (Replaces Q-059, per your equivalence suggestion.)

- **Why it's yours:** [2] adds a component that decides whether a shell command runs. [1] and [3] execute nothing.
- **Read:** `docs/working/dd-arith-eval-bash-grant.md` (13 candidates, matrix). Q-059's old [2] was pruned there: an allow rule loose enough for the Mode 1 command also allows any `python3 -c` program.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Deny-and-record + static equivalence** | Bash is listed, but every call is denied. The harness takes the denied command from the transcript, checks it is exactly SKILL.md's Mode 1 program, and runs the extracted expression through its own copy of the evaluator. If any Bash call actually executes, a tripwire fails the run. | None. No pre-mortem needed, since nothing runs. | What the model does after seeing a real result goes unmeasured. It rests on denied calls being recorded; if they aren't, it falls back to `permission_denials`, and if that fails too it drops to [3]. |
| **[2] Equivalence-gated live approval** | The same check runs live as the permission handler, so only an exact Mode 1 match on a numbers-only expression runs | One pre-mortem, about 2 days of work | A matching bug in the handler opens a shell. It is also unverified whether `--safe-mode` keeps the MCP server the handler needs. |
| **[3] Dry-run disclosure** | No Bash. The prompt asks the model to print the command it would run, and that command is checked for equivalence | None | It tests whether the model knows the procedure, not whether it reaches for the evaluator unprompted |

- **Blocks:** plan step 5 only
- **Interim:** nothing built. Step 4's gate tests already cover the evaluator itself.
- **Update 2026-09-25 ("Test [1]"):** two Haiku probes confirm [1] is feasible. Denied calls are recorded in the stream and in `permission_denials`, and nothing executed. Unprompted, the model reached for Mode 1. The check must be AST-level: Haiku stripped the comments, so a byte-exact match fails, while an `ast.dump` comparison passes and rejects a one-token tamper. After the denial, the model fell back to mental math, which a fixture can grade as its own assertion. Details: DD doc, "Probe results".
- **If the answer differs:** [2] can be added later on top of [1]; nothing is redone.

**Answered 2026-09-25: [1].** Built as `FIXTURE_BASH=deny-record` plus `mode1_equiv:` (decisions log #56). The first Haiku run routed all 4 arithmetic fixtures through Mode 1 (the no-arithmetic negative made no Bash call) but fell back to mental math 4 of 4 after the denial.


### Q-064 · unreadable-cwd-gate
**Needs:** you: judgment · **Opened:** 2026-09-25 · **Status:** ANSWERED

The Q-062 detector skips a same-uid process whose cwd it cannot read. Should it refuse instead?

- **Why it's yours:** it sets how far your Q-062 [2] answer reaches: leftover helpers only, or also a process that actively hides.
- **Read:** `docs/reviews/security-review-2026-09-25-q062-q063.md` F1; rubric `code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md` A1; decision 037 "What the gate does not see".
- **Context:** the cwd is unreadable for a process that calls `prctl(PR_SET_DUMPABLE, 0)` (reproduced), and also for ssh-agent. A leftover helper does not do this by accident. A process that does can also evade by sitting in `/` with an open handle on the checkout, which no cwd check sees.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Skip and document** | Unreadable cwds are skipped; 037 lists "a process that hides its cwd" as not seen | None | A deliberately evading same-uid process writes during the install, unseen (it could evade anyway via an open handle) |
| **[2] Refuse on unreadable cwd** | Any same-uid process whose cwd can't be read refuses the install, naming it | Kill ssh-agent (and any other non-dumpable process) before every install | Nuisance refusals every install while ssh-agent runs; spoofable if an allowlist is added to reduce them |
| **[3] Skip but name** | Unreadable-cwd processes are not refused, but a NOTE lists each one (PID and command line, which stay readable) at every check | Glance at the NOTE; ssh-agent will be on it | You skim past an unexpected name; the process still runs during the install |

- **Blocks:** nothing (A1's author note points here)
- **Interim:** [1]. The skip is commented at `procs_in_checkout` and listed in 037.
- **If the answer differs:** [2] or [3] need `procs_in_checkout` to report a second class of process (cwd unknown) and the gate to act on it: about five edit sites plus tests, not a one-line change (architecture review iteration 2, F4). Nothing already built is redone.

**Answered 2026-09-26: [2].** `procs_in_checkout` now tags each other same-uid process `in` (cwd in the checkout) or `unknown` (cwd unreadable), and the gate refuses on either, naming each one; a blind scan therefore refuses too. ssh-agent must be stopped before an install. Tests T91 (blind scan) and T92 (a non-dumpable process). Decision 037 is updated.

### Q-068 · si-loop-retire-or-resume
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** ANSWERED

Should `scripts/self-improvement.sh` be retired or resumed? **Answered 2026-09-27: [3] resume — this has been the intent all along.** The user has been working toward re-running it, but first needs to trust that the script will not break their setup, and that has taken time. So the loop stays dormant until that trust exists. The trust work is filed as Q-075. This answer overrides the triage's verdict ("keep as-is and resume" marked Drop). See decision log 57. Q-065 is un-deferred, since its deferral said "if it resumes, ask again". Original entry: The triage decided this was your call (D3), but it was never filed, and 17 commits have hardened the loop since.

- **Why it's yours:** it decides where the repo's maintenance effort goes. Four other items wait on it.
- **Read:** `docs/working/triage-2026-09-17-backlog.md` §4 (verdict: "#7 + #2 dominates"; "keep as-is and resume" marked Drop) · `archive/docs/2026-09-18-handoff-self-improvement-loop.md` §4–§5 (the three couplings any retirement must handle).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Retire, keep the carve-out, build the triage report** | The triage's pick (#7 + #2). The loop goes to `archive/`. The 25-line `tap_*` carve-out and its 11 tests stay. An attention-triage report replaces what the loop was kept for. | Review one retirement diff | The loop is gone. Reviving it is one `git mv` back from `archive/` |
| **[2] Retire entirely** | As [1] without the carve-out | Same | The `tap_*` helpers would have to be rewritten if something needs them |
| **[3] Resume as-is** | Run it again | Its morning summaries: the 50-question queue the triage calls the anti-pattern | Your attention budget, again |
| **[4] Leave dormant, stop maintaining it** | No runs and no more hardening commits | None | Code keeps drifting from the decisions that describe it |

- **Blocks:** Q-065 (dead helper) · reconciling decision 020 with Gate 1h's fail-closed behaviour · the planner prompts and morning-summary verdict gate that still treat usage.jsonl counts as evidence (Q-017)
- **Interim:** [4] in practice. Nothing runs it. The review found a stale comment and a stale header on it; I fixed only those.
- **If the answer differs:** nothing to undo.


### Q-069 · host-git-on-container-checkout
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** ANSWERED

cc-isolated's recommended workflow is "commit in the container, push from the host with your keys". But the container can write `.git`, so a plain host `git push` or `git status` runs whatever hooks and fsmonitor it planted, as you. How should the host touch a container-written checkout? **Answered 2026-09-27: [3] launcher-side scan.** `cc-isolated.sh` checks, at session exit, whether `.git` gained hooks, fsmonitor, filters or includes during the session, reusing install.sh's refusal list. It is a code change to an enforcement file, so it needs a live-verified commit. Filed as Q-076. Original entry:

- **Why it's yours:** it changes your daily push habit, and it weighs your time against how exposed your credentials are.
- **Read:** `guides/cc-isolated-usage.md` (the new caveat under "No credentials") · decision 015 H1 · decision 034 ("the host never reads a container-written `.git`", so far applied only to the benchmark harness) · decision 037 line 81.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Push from a separate host clone** | Keep a host-only clone. `git fetch` from the container checkout and push from there. Nothing reads the container's config. | One extra clone per project, plus a fetch before each push | Nothing |
| **[2] Guarded git for container checkouts** | A shell function that adds `-c core.hooksPath=/dev/null -c core.fsmonitor=false` in container-mounted paths | Setup once | Filter drivers and `include` keys are still exposed; an unguarded `git status` slips through |
| **[3] Launcher-side scan** | `cc-isolated.sh` refuses to exit cleanly (or warns) when `.git` gained hooks, fsmonitor, filters or includes during the session, reusing install.sh's refusal list | None day to day; I build it | A planted key added after the scan, or on a container that is never stopped |
| **[4] Accept the risk** | Keep the documented caveat only | None | An injected agent gets your ssh keys at your next push |

- **Interim:** the guide now documents the risk and the safer push command. Nothing is enforced.
- **If the answer differs:** [3] is a code change to an enforcement file, so it needs a live-verified commit.


### Q-070 · auto-approve-backstops-in-cc-isolated
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** ANSWERED

`hooks/auto-approve-allowed-commands.sh` accepts its known bypasses because "permissions.deny plus the sandbox are the boundary". Inside cc-isolated neither exists: no `sandbox` key and no Bash deny rules. The reviewer got it to auto-approve a `curl -d @…/.credentials.json` nested in `$(( ))`, which gets past the `Read(.credentials.json)` deny rule. What should auto-approve rest on there? **Answered 2026-09-27: [1] supply the backstops.** Add Bash deny rules for the credentials path, plus a sandbox config, to the cc-isolated settings merge. [2] (narrow the hook), which the entry recommended as a default alongside any choice, was not picked. It stays unbuilt unless asked for. Filed as Q-077. Original entry:

- **Why it's yours:** it trades prompt friction against what an injected agent can run without asking.
- **Read:** the hook's header, lines 25–35 · `hooks/wiring.json` permissions block · decision 023 ("widens nothing") · decision 015 (the container is low-stakes, but the credentials file is not). The global instructions' "Tool Preferences" section also assumes a bwrap sandbox that cc-isolated does not have.
- **Caveat:** I have relayed the reproduction; I have not re-run it.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Supply the backstops** | Add Bash deny rules for the credentials path, and a sandbox config, to the cc-isolated settings merge | Some new prompts where the sandbox blocks | Rules are string matches too, so obfuscation may still get through |
| **[2] Narrow the hook** | Refuse to auto-approve any command with `$(`, backticks, `$((`, redirections or env-assignment prefixes, whatever the allowlist says | More prompts on compound commands | Little: those fall back to a normal prompt |
| **[3] Unwire it in cc-isolated** | `CC_SKIP_HOOK_WIRING`-style opt-out for this one hook | Every piped command prompts | Friction only |
| **[4] Accept** | 015 calls the container low-stakes | None | The OAuth credential is exfiltrable without a prompt |

- **Interim:** nothing changed.
- **If the answer differs:** [2] is a small hook change plus tests. I'd recommend it as the default whichever else you pick.


### Q-071 · skill-eval-suite-design
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** ANSWERED

The 50 `@needs-reports` suites can't stay green under this repo's editing rate. Their freshness stamp hashes the skill dir, the per-skill runner and the shared `test/skills/runner-contract.bash`. That shared file changed 8 times in 30 days, and every change makes every skill's reports stale, which fails the suites. Keep the design, or change it? **Answered 2026-09-27: [1] narrow the stamp and commit the reports.** The stamp covers only the skill's own files and the fixture, not the shared `runner-contract.bash`, and `output/*.report.md` becomes tracked. This un-blocks Q-067, which now waits only on A8. Filed as Q-078. Original entry:

- **Why it's yours:** it decides whether skill-output testing costs quota on every skill edit, and whether it exists at all.
- **Read:** `docs/working/audit-test-constraint-2026-09-26.md` batch G · commit 48680e2 · `test/skills/runner-contract.bash` `report_stamp`. Reports are gitignored (`.gitignore:5`), so they also never survive a fresh clone.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Narrow the stamp, commit the reports** | Stamp the skill's own files and the fixture only (not the shared contract), and track `output/*.report.md` | One regeneration run, then only skills you edit | A contract change that alters output goes unnoticed until the next regeneration |
| **[2] Stale = skip, loudly** | Keep full stamps, but a stale report skips with a NOT RUN line instead of failing | None | The suites rarely run, as today |
| **[3] Retire them** | Delete the output-dependent suites and keep the prose-contract tests | None | Skill-output regressions stay invisible, as they are today |
| **[4] As is** | Strict stamps, reports gitignored | Regenerating everything after every contract edit | The suites are red whenever reports exist |

- **Blocks:** Q-067 (when to regenerate) matters only under [1], [2] or [4].
- **Interim:** [4]. The suites print NOT RUN, because no reports exist.
- **If the answer differs:** [1] and [2] are small edits to `runner-contract.bash` and its freshness tests.


### Q-072 · living-ledger-not-fed
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** ANSWERED

The review-eval goal is "recall against the living issue ledger", but `docs/working/canon-issue-ledger.md` hasn't changed since 2026-08-18. Since then, 112 September review artifacts have been written to `docs/reviews/`, and none feed back into it. Feed it, or restate the goal? **Answered 2026-09-27: between [1] and [2].** New reviews should not each add a canon entry. The canon's purpose is to stay compact, so that it can be evaluated more often than a larger and more reliable benchmark, while still covering a broad range of issue types. The user's first thought: a *script* converts a commit or commit sequence into a canon instance, but *proposing* instances needs higher-level heuristic filtering, not a simple trigger. Filed as Q-079 (design the proposal filter). Original entry:

- **Why it's yours:** you defined the metric (memory, 2026-08-14 correction). Whether the ledger stays living is a scope call, and it changes what the A8 measurement can claim.
- **Read:** `docs/working/canon-issue-ledger.md` header · `docs/thoughts/code-review-evaluation-state.md` (now marked stale).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Automate the feed** | A script lifts confirmed Must-Fix rows from new `docs/reviews/` rubrics into the ledger as candidates. It is a script, not a workflow step: steps in workflow docs don't run | Review candidate rows now and then | Noise in the ledger if the lifting is loose |
| **[2] Feed it at A8 time only** | One backfill pass when A8 runs | One review pass then | Recall numbers before A8 use a stale denominator |
| **[3] Freeze and rename** | Call it the 8-instance canon and drop "living" | None | The metric is the frozen benchmark you ruled out |

- **Interim:** no change. The ledger's header still says "living".
- **If the answer differs:** nothing to undo.


### Q-073 · skill-descriptions-truncated
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** ANSWERED

Skill descriptions run 957–2973 characters, and the live skill listing truncates them. In this session 7 skills (cowen, yglesias, the 3 business-plan critics, design-space-situating, self-eval) showed **no description at all**, and pre-mortem/what-if's disambiguation is cut mid-sentence. Separately, cowen and yglesias both call themselves "the DEFAULT critic", and "what am I missing" triggers three skills. Rewrite the descriptions? **Answered 2026-09-27: [1] front-load and trim.** In each description, the first ~250 characters carry the trigger phrases and the "not this, use X" line, and the rest moves to the body. No de-overlap: the cowen and yglesias "DEFAULT critic" claims, and the phrases that route to more than one skill, are left as they are. Filed as Q-080. Original entry:

- **Why it's yours:** descriptions are what triggers the skills. Rewriting them changes when each skill fires, and which critic is the default is a taste call.
- **Read:** `guides/skill-format-audit.md` F4 (open since April) · `guides/skill-trigger-guide.md`. I did not verify the cause; the listing's overall character budget is the likely one.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Front-load and trim** | First ~250 chars carry the trigger phrases and the "not this, use X" line; the rest moves to the body | Skim 25 diffs | Some long-tail trigger phrasing is lost |
| **[2] [1] plus de-overlap** | Also pick one default prose critic and give each overlapping phrase one owner | Plus: name the default critic | A phrase you liked routing two ways routes one way |
| **[3] Leave** | — | None | 7 skills stay effectively invisible to triggering |

- **Interim:** nothing changed. I removed only the health-check requirement for the unread `when:` field (F1).
- **If the answer differs:** n/a.


### Q-077 · cc-isolated-auto-approve-backstops
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** ANSWERED

Implement Q-070 [1]. The cc-isolated settings merge gains Bash deny rules for the credentials path and a sandbox config. Then re-run the reported `$(( ))` credentials reproduction against the result. **Done 2026-09-27, merged to main in b7fbb2a (deny half only).** The reproduction was re-run first-hand: the hook approved it before the change. The credentials deny rule is in `hooks/wiring.json`, and the hook now honours deny rules through a fail-closed parser, see its header. The sandbox half can't run in the current image, so it is filed as Q-081. The host checks for Claude Code's own deny behaviour are Q-082. Rubric: `docs/reviews/code-review-rubric-2026-09-27-integrate-q077-q078-q080.md`. Original entry:

- **Interim:** nothing changed. The reproduction has still not been re-run first-hand.


### Q-078 · narrow-skill-report-stamp
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** ANSWERED

**Done 2026-09-27, merged to main in b7fbb2a.** Stamps are now `format 2` and cover only the skill directory, its `runner.bash` and the fixture. The per-skill runner stayed in the stamp because it sets that skill's prompt, tools and mode. A change to the shared harness only warns. `.gitignore` admits reports and their `.stamp`, `.failed` and `.transcript.jsonl` sidecars. No reports are generated yet, and generating them still waits on A8 (Q-067). Original entry: Implement Q-071 [1]. `report_stamp` in `test/skills/runner-contract.bash` hashes only the skill dir and the fixture, `.gitignore:5` stops ignoring `output/*.report.md`, and the freshness tests are updated to match.

- **Interim:** the suites print NOT RUN.


### Q-080 · front-load-skill-descriptions
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** ANSWERED

**Done 2026-09-27, merged to main in b7fbb2a.** All 25 descriptions are 364–426 characters, and every "not this" line ends by character 250. Four skills (arithmetic-eval, matrix-analysis, self-eval, tech-debt-triage) have no such line, and never had one. Displaced phrases are kept in each body. No de-overlap was done. Whether the 7 previously blank skills now show a description in the live listing can only be seen in a fresh session. Original entry: Implement Q-073 [1] across the ~25 skills. The first ~250 characters of each description carry the trigger phrases and the "not this, use X" line, and the rest moves to the SKILL.md body. No de-overlap. The user skims the diffs.

- **Interim:** 7 skills still show no description in the listing.


### Q-076 · cc-isolated-git-exit-scan
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** ANSWERED

**Done 2026-09-27, merged to main in 7387d8f; not yet live-verified (Q-084).** Review showed that a `.git` scan can't be a guarantee, so on the user's decision it ships as a tripwire, `cc-exit-scan.sh`, alongside `cc-push`, which is now the safe way to push. Both use `cc-gitdir.sh` for git-dir validity. The guide's "Known routes it does not see" is the single list of what they miss. Rubric: `docs/reviews/code-review-rubric-2026-09-27-q076.md`. Follow-ups: Q-083 (host-tools trust category) and Q-084 (live checks). Original entry: Implement Q-069 [3]. At session exit, `cc-isolated.sh` warns about, or refuses, `.git` changes made during the session: new hooks, `core.fsmonitor`, filter drivers, `include`/`includeIf`. It reuses install.sh's refusal list.

- **Interim:** the guide's documented caveat only.
- **Blocks:** nothing. This is an enforcement file, so it needs a live-verified commit.


### Q-065 · si-input-rejected-history-dead-code
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** ANSWERED

**Answered 2026-09-28: [1] delete.** Done in d943e33: the function and its 12 tests are gone, and the two `parse_si_input` comment tests moved to `test/si-input-parse-comments.bats`. Original entry:

`prepend_si_input_rejected_history` (`scripts/lib/si-input.sh:214`) has had no caller since it landed in 06903d6 (2026-05-19). 12 of the 14 tests in `test/si-input-rejected-history.bats` exercise only this dead function. Should it be wired in or deleted?

- **Why it's yours:** whether the self-improvement loop should show recent rejections in si-input.md is a product call. The code can't tell whether leaving it unwired was deliberate.
- **Read:** `docs/working/audit-test-constraint-2026-09-26.md` batch D. The function's header comment describes it as the "new-cycle bootstrap".

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Delete** | Remove the function and its 12 tests. Keep the 2 `parse_si_input` tests. | None | The rejected-history preamble never appears. It never has so far. |
| **[2] Wire it in** | Call it at run start in `self-improvement.sh` and add a wiring test. | Review one behaviour change to si-input.md | Rejection rows appear in a file you edit, and may be noise |
| **[3] Leave as is** | The 12 tests keep constraining code that nothing runs | None | The suite overstates coverage |

- **Interim:** [3], nothing changed. No production path reaches it, so nothing is at risk.
- **Deferred 2026-09-26 behind Q-068:** if the loop is retired, this is moot; if it resumes, ask again.
- **Un-deferred 2026-09-27:** Q-068 was answered "resume". [2] now matters, because the preamble would show up in real runs. It is not urgent, since the loop won't run until Q-075 is settled.
- **If the answer differs:** [1] or [2] is a single small commit.


### Q-066 · sandbox-tool-map-host-drift-run
**Needs:** you: terminal · **Opened:** 2026-09-26 · **Status:** ANSWERED

**Answered 2026-09-28: 7 of 7 passed** with `REQUIRE_LIVE_SETTINGS=1` on the host, so `guides/sandbox-tool-map.md` matches the live allow list. Nothing to fix. Original entry:

The permission allow list exists only on your host, so the two drift checks in `test/sandbox-tool-map-drift.bats` always skip in the sandbox. Run them once on the host in strict mode, from the repo root:

```
REQUIRE_LIVE_SETTINGS=1 bats test/sandbox-tool-map-drift.bats
```

- **Interim:** the sandbox run proves only that the checks can fail (fixture tests), not that `guides/sandbox-tool-map.md` matches your live settings.
- **If the answer differs:** a red result lists the drifted `Bash(X:*)` entries. Fix the guide's table and markers to match.


### Q-081 · cc-isolated-sandbox-half
**Needs:** you: judgment · **Opened:** 2026-09-27 · **Status:** ANSWERED

**Answered 2026-09-28: [2] spike `enableWeakerNestedSandbox` first.** Filed as Q-088 (agent). Original entry:

Q-070 [1] asked for Bash deny rules *and* a sandbox config in cc-isolated. Only the deny half was built (Q-077): the image has no `bwrap`/`socat`, and Docker's default seccomp blocks user namespaces (`unshare -Ur` → EPERM). Build the sandbox, or accept the container plus `permissions.deny` as the boundary?

- **Why it's yours:** it trades kernel attack surface and image changes against how much a prompt-injected agent can do without asking. The deny rule alone does not stop a determined injection: a glob `.cred*`, a variable set earlier, and brace/ANSI-C spellings are pinned as accepted in `test/auto-approve-allowed-commands.bats`.
- **Read:** the `hooks/auto-approve-allowed-commands.sh` header (GUARANTEES / RESIDUALS) · decision log 53 · `docs/reviews/security-review-2026-09-27.md` F5.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Build the sandbox** | Add `bubblewrap` and `socat` to the Dockerfile, a seccomp/runArgs change allowing user namespaces, and a `sandbox` settings block (`autoAllowBashIfSandboxed` decided explicitly; `allowedDomains` matched to the egress allowlist) | Review an enforcement-file change and one live container check | Wider kernel surface; mismatched domains make `gh`/`git push` prompt |
| **[2] Spike `enableWeakerNestedSandbox` first** | Test whether the weaker nested mode avoids the user-namespace change, then do [1] or [3] | One spike | May cost a spike for nothing |
| **[3] Accept deny + container** | Record that in cc-isolated the boundary is the container plus `permissions.deny` | None | The OAuth credential stays reachable by a determined injection |

- **Interim:** [3] in practice. Nothing sandboxes Bash in cc-isolated.
- **If the answer differs:** [1]/[2] are new enforcement-file work with a live-verified commit.


### Q-083 · host-tools-trust-category
**Needs:** you: judgment · **Opened:** 2026-09-27 · **Status:** ANSWERED

**Answered 2026-09-28: [1] separate host-tools category.** Filed as Q-089 (agent). Original entry:

The trust manifest's rule "every shipped file is hashed" puts host-only tools (`cc-push.sh`, and soon `cc-exit-scan.sh` and `cc-gitdir.sh`) in the container-boundary enforcement category. Should host tools get their own category?

- **Why it's yours:** it amends decision log row 45's scope and changes what the live-verify gate demands of every commit to these files.
- **Read:** `docs/reviews/q076-architecture-review-2026-09-27.md` Finding 3 · decision log row 45 · `hooks/live-verify-gate.sh` · `enforcement_files` in `devcontainer-config/cc-isolated.sh`.
- **The problem, concretely:** host tools can't be live-probed, so every commit to them carries `Live-verified: no`, which dilutes row 45's debt list. `check_manifest` runs only when cc-isolated launches, so a changed `cc-push.sh` blocks every launch until re-blessed, while `cc-push` itself runs unchecked.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Separate host-tools category** | Its own manifest section and commit trailer (e.g. `Host-tool-tested:`); `cc-push` verifies its own hash before running; row 45 amended | Review one enforcement change | More machinery for two or three files |
| **[2] Keep as enforcement files** | Record in row 45 that host tools are deliberately in the enforcement set | None | Debt list stays diluted; a cc-push edit keeps blocking launches until re-bless |
| **[3] Unhash host tools** | Drop them from the manifest; rely on git review only | None | A tampered cc-push on the host goes unnoticed |

- **Interim:** [2] in practice (user deferred this at the Q-076 fix batch, 2026-09-27).
- **If the answer differs:** [1] is a small enforcement-file change with tests; [3] edits the manifest and the tests that pin it.


### Q-085 · review-unit-size-budget
**Needs:** you: judgment · **Opened:** 2026-09-27 · **Status:** ANSWERED

**Answered 2026-09-28: [3] ~400 code lines, every unit.** Done in 6a370cb: pr-prep step 1a is now a gate, counting changed lines outside `docs/`, and decision log 62 records it. In /away mode an oversized unit splits without asking. After the review loop you also chose (2026-09-28) to keep counting deletions and to keep the count a plain command that does not validate `BASE`. Original entry:

What size cap should a review unit have before the review-fix loop starts (proposal A4)? Over the cap, the unit must split into stacked units that merge in order, unless you waive it.

- **Why it's yours:** it sets how often work gets split, a trade between review quality and stacking overhead. Only you know how much stacking you'll tolerate.
- **Read:** `docs/working/proposal-2026-09-27-smaller-review-units.md` (A4) · decision log row 59 · Q-076 grew from +476 to +3,613 code lines under review.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] ~600 code lines, enforcement files only** | Cap applies when the diff touches a file the live-verify gate covers; reviews and docs excluded from the count | None; agents split | Non-security units can still balloon |
| **[2] ~600 code lines, every unit** | Same cap everywhere | Occasional stacked series to merge | More splitting on routine work that would have reviewed fine |
| **[3] ~400 code lines, every unit** | Closer to the usual human-review guidance | More stacks | Split overhead dominates on small features |
| **[4] No hard cap** | Rely on the early split trigger in review-fix-loop only | None | Q-076-shaped growth repeats |

- **Interim:** no cap; the early split trigger is the only size control.
- **If the answer differs:** a short pr-prep step-1 gate edit and a decision-log row.


### Q-086 · install-gnu-parallel
**Needs:** you: terminal · **Opened:** 2026-09-27 · **Status:** ANSWERED

**Answered 2026-09-28:** `GNU parallel 20210822`. That is Ubuntu 22.04's version (bookworm ships 20221122), so it most likely ran on the host, not in the image. 9e5477a adds `parallel` to the Dockerfile's base apt list (`Live-verified: no`); the in-container check joins Q-084's paste, and the `--jobs` work is Q-090. Original entry:

`bats --jobs` needs GNU `parallel`, which is not in the image. The full suite runs serially in 742 s on a 16-core machine. Add `parallel` to the apt-get install list in `devcontainer-config/Dockerfile` and rebuild the image, then confirm:

```
parallel --version | head -1
```

- **Interim:** `run-tests.sh` has no `--jobs`; the suite stays serial.
- **If the answer differs:** once `parallel` is present, an agent adds `--jobs` to `run-tests.sh` and measures the speedup (install-host.bats, the slowest suite, bounds it).


### Q-087 · final-confirming-pass-replicates
**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** ANSWERED

**Answered 2026-09-28: [2] k=3 on the final pass.** Done in c7a6251: `skills/code-review/SKILL.md` Stage 1 applies the k=3 protocol to the final confirming pass, the replication suite pins it, and decision log 63 records the amendment to 031. Original entry:

Should the final confirming pass of a review-fix loop run the fact-check at k=3 instead of decision 031's k=1, now that loop passes default to reviewing only the delta since the last rubric stamp?

- **Why it's yours:** it trades about +300k tokens per loop against recall on code no fix touched, and reverses part of a recorded decision (031 C2).
- **Read:** decision 031 (`docs/decisions/`, C2: k=1 on both clean passes) · `docs/reviews/u4-code-fact-check-report-iter2.md` claim 6 on feat/u4-code-review-skill · proposal B2 (`docs/working/proposal-2026-09-27-smaller-review-units.md`).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep k=1 (031 as is)** | Final confirming pass reviews the full branch with one fact-check agent | None | A defect in untouched code is drawn only twice (first and final pass) instead of on every pass |
| **[2] k=3 on the final pass** | Final confirming pass runs three replicates, merged most-severe-wins; record the departure from 031 | ~+300k tokens per loop | Tokens spent on a pass that 031 found adds little |

- **Blocks:** nothing.
- **Interim:** [1]. U4 (feat/u4-code-review-skill) keeps 031's k=1 and cites this entry.
- **If the answer differs:** one-line change in `skills/code-review/SKILL.md` Stage 1 replication paragraph plus a decision-log row.


### Q-082 · auto-approve-host-checks
**Needs:** you: terminal · **Opened:** 2026-09-27 · **Status:** ANSWERED

Does a PreToolUse hook `allow` override a matching `permissions.deny` rule? That decides whether the auto-approve hook's deny reader is load-bearing or redundant.

**2026-09-28, first run (with the hook wired):** both credential lines were **denied** ("Permission to use Bash with command … has been denied"). That settles one thing: the leading `*` in `Bash(*.credentials.json*)` matches. It does not settle the question, because the hook's deny reader saw the match and fell through (header line 53), so no hook `allow` was ever in play. The deny came from Claude Code alone. The planned "no hook" rerun would test the same thing again. Your `!` run succeeding is expected: `!` commands skip permission checks entirely.

**The test that decides it** needs a hook that always allows, next to a deny rule. It uses a throwaway directory outside the repo and a harmless canary file, so it touches neither the image, the manifest nor your user settings, and needs no re-bless:

```
mkdir -p ~/q082/.claude && cd ~/q082 && echo canary > x.q082-canary
cat > .claude/settings.local.json <<'EOF'
{
  "permissions": { "deny": ["Bash(*.q082-canary*)"] },
  "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command",
    "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"permissionDecisionReason\":\"q082\"}}'" } ] } ] }
}
EOF
claude
```

In that session, check `/hooks` lists the test hook, then ask Claude to run `cat x.q082-canary` and note whether it **runs**, **prompts**, or is **denied**. The test hook allows *every* Bash call in that session, so run only this one command, exit, and `rm -rf ~/q082`.

**2026-09-28, second run (answers-9-28-26-2.txt):** `cat x.q082-canary` was **denied** ("Permission to use Bash with command cat x.q082-canary has been denied"). Claude then read the file with the Read tool instead. That is expected: the test deny rule covers Bash only, and the real wiring also has `Read(/{{CLAUDE_DIR}}/.credentials.json)` (`hooks/wiring.json:129`). **Not yet confirmed:** that `/hooks` listed the test hook in that session. A hook that never loaded gives the same denial, so without that check the result doesn't settle anything. **Answer (2026-09-28):** the user confirmed `/hooks` listed the test hook. So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule. The deny won. The hook's deny reader is therefore redundant for `allow`; its removal is filed as Q-092, and decision log 53 is amended.

- **Interim:** the hook header calls its deny check load-bearing in cc-isolated.
- **If the answer differs:** denied ⇒ `permissions.deny` beats a hook allow; the hook's deny reader can be deleted (architecture-review 1) and decision log 53's amendment updated. Runs or prompts ⇒ the deny reader stays load-bearing; reclassify the hook as an enforcement component.


### Q-091 · cc-push-self-commondir
**Needs:** you: judgment · **Opened:** 2026-09-28 · **Status:** ANSWERED

`cc-push` refuses your main checkout because `.git/commondir` holds `.` (see Q-084). Remove the file, or teach cc-push to accept it?

**Where it came from (investigated 2026-09-28).** Claude Code's own Bash sandbox (bwrap, on Linux/WSL) made it. It was not a git command, a script in this repo, or an IDE.
- `.git/commondir` (`.`), an empty `.git/config.worktree` and an empty `.git/modules/` all have mtimes within 5 ms of each other: 2026-07-09 13:45:22.019–.023 [observed]. That is a single program's burst, not a git operation. Git never writes `commondir` into a main gitdir.
- That afternoon a sandboxed host session was running: spike `2a455fd4` ("nested bwrap … feasible on this WSL2 host") and commit `9a3eca3f` at 13:46:14 [observed].
- The Claude Code binary (2.1.284, this container) carries a protected-path list: `/.git/hooks`, `config`, `config.worktree`, `commondir`, `worktrees`, `modules`, `info/exclude`, `glab-cli`, `/.gitmodules`, `/.bashrc` … [observed, `strings` on the binary]. bwrap can only mount read-only over a path that exists, so the sandbox creates a stand-in for each missing one. A `.` in `commondir` is the one stand-in git still reads as "this same directory" [inferred]. Later bursts fit the same pattern: an empty `.git/glab-cli/` (2026-08-17) and eight empty `.env*`/`package.json`/`.npmrc`/lockfiles in `devcontainer-config/` (2026-09-24 23:10:21, the untracked files in `git status`) [observed].

**Will it come back?** Two cases:
- **2.1.284 (the version in this container):** on Linux/WSL it still *creates* an empty `config.worktree` if one is missing. `commondir` now goes to a list of paths it scrubs after a sandboxed command, and it is not created [inferred from the minified sandbox code; not run]. So on this version `commondir` should not return, but `config.worktree` will.
- **The host's `claude` version is unknown.** The sandbox only runs on the host: the cc-isolated image has no bwrap (Q-081). If the host still runs an older build, any sandboxed host session in this repo can recreate `commondir`.

`cc-push` tolerates an empty `config.worktree` (it rejects only include sections, `cc-push.sh:294`) and an empty `modules/`. Only `commondir` blocks it.

**Answer (2026-09-28): [1].** The user ran `rm ~/claude-workflows/.git/commondir && claude --version`. The `&&` means the version printed only after the rm succeeded, and it printed `2.1.284 (Claude Code)`, the same build whose code was read above, so the old stand-in writer is gone. The file is gone from the shared checkout too (checked from inside the container). Not re-verified live: that 2.1.284 never recreates `commondir`. If a later sandboxed host session brings it back, reopen with [2].

**2026-09-28, later:** it came back, and the user deleted it again to get Q-084 step 3 through. The writer is not yet identified. Continued as Q-093.

- **Read:** Q-084's 2026-09-28 note · `devcontainer-config/cc-push.sh:272` · `commondir_of` in `devcontainer-config/cc-gitdir.sh:50`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Remove `commondir` on the host, then check the host version** | Outside any session: `rm ~/claude-workflows/.git/commondir && claude --version`. Leave `config.worktree` and `modules/`: the sandbox recreates them and cc-push accepts them. cc-push stays as strict as it is. | One paste, then rerun Q-084 step 3 | If the host build is old enough to still write `commondir`, it comes back after the next sandboxed host session and cc-push refuses with the same message. The fix is the same one line, or [2]. |
| **[2] Relax cc-push** | Accept a `commondir` whose whole contents are `.` (a self-reference). Refuse everything else as today. | An enforcement-file unit: review loop, re-bless, a host rerun | A bug here reopens the read-outside-the-checkout hole the check exists to close. It is also only needed if an older sandbox keeps writing the file. |

- **Interim:** nothing changes. cc-push refuses this checkout until [1] runs. Deleting the file from inside a session would trip the exit scan's commondir record, so it isn't done here.
- **If the answer differs:** [2] is still possible after [1]. Answer [1], and if `claude --version` on the host is older than 2.1.284 and `commondir` reappears, [2] becomes the durable fix. The empty `devcontainer-config/` placeholder files can be deleted any time; they return whenever a sandboxed host session starts in that directory.


