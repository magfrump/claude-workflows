# Constraints draft: claude-workflows (2026-10-19)

This is input for you, not the constraints doc itself. Once you've settled the calls below, copy the block into `docs/constraints.md` (or apply the diff). The rest of this file is the evidence.

- **Mode:** amend. `docs/constraints.md` exists as revision 2, which you committed in 83b653d2 on 2026-10-15 (you are the only author; no co-author trailer). That revision came from decision records, log rows 1–72 and DD docs (`docs/working/constraints-sources-2026-10-15.md`). It did not read your answers files or the questions archive. This run reads those, plus log row 73 and how the three build loops since 10-17 used the doc. Every ID is kept. This draft is revision 3.
- **Read:** four read-only readers, each with its own output file in the session scratchpad:
  - `docs/human-author/` (16 answers files, `feedback.md`, `CodeReviewWriteup.md`, `LLM Code Review.md` and `Next Live Interface.md`; `prompts.ts` and `property-tests.json` are data and were skipped), about 65 KB
  - `docs/working/questions-archive.md`, lines 1–1702 and 1703–3459, about 380 KB
  - `docs/working/questions.md`, `docs/thoughts/failure-patterns.md`, `docs/thoughts/retro-constraints-builder.md`, `docs/working/idea-log.md`, `docs/dev-cycle.md` and log row 73
  - Read inline: the research docs on the three build-loop branches (`feat/q146-si-script-commits`, `fix/cc-isolated-profile-names`, `fix/claude-md-import-guard`). They were read as diffs against main and not extracted, since only their constraint citations were counted.
- **Parsed:** `constraints ok 4-hard 10-soft: docs/working/constraints-draft-2026-10-19.md (draft)` (the installed `~/.claude/scripts/build-loop.sh --check-constraints`, run under `timeout 60`, exit 0).
- **Citations:** file:line with a short quote. I spot-checked these against the files: `answers-10-12-26.txt:4-6,11,14,17`, `answers-10-16-26.txt:2,12,18-19,22,36,39-40,47` and `answers-9-20-26.txt:2-3,6-7,12-14,51-52`. Citations into the questions archive are the readers' and were not spot-checked.
- **Provenance** (step 4, `git blame` on main):
  - `answers-9-20-26.txt`, `answers-9-28-26.txt`, `answers-10-12-26.txt`, `answers-10-16-26.txt` and `CodeReviewWriteup.md` were committed by you, with no agent co-author.
  - `answers-9-17-26-2.txt`, `answers-9-23-26.txt`, `answers-9-23-26-2.txt` and `feedback.md` carry a Claude `Co-Authored-By` trailer. By the skill's rule they count as agent-written, even though they sit in `docs/human-author/`. That includes the Q-050 "only editable copy… human bless" quote and the "I *will* forget to add flags" quote.
- **Cost:** every line rides in every loop prompt. Revision 2 has 15 lines; this draft has 14 (the S9 line removed, its IDs not renumbered).

## Copy-ready block

This doc holds the design-level constraints that steer the choices a build loop makes on its own: hard lines prune candidates, soft lines rank the survivors. Coding rules (argv and heredocs, headless `claude`, live verification, test stubs, probes) are in `CLAUDE.md`, and most of them are enforced by code.

H1: Code that gates, reviews or bounds a change runs from a copy that change cannot edit (the root-owned image payload or the host); what an agent session writes, including git config, hooks and attributes in a checkout it can write, is input to those checks, not a source of their logic. Known interim exception (Q-149 [2]): the health check runs the change's own `scripts/` and `test/`, and a self-merged `install.sh` reaches the host at the next release.
success: `rg -n -- '"command": ' hooks/wiring.json | rg -v -F -- '{{CLAUDE_DIR}}/hooks/'` prints nothing, and a new gate or reviewer path is added to GATE_CODE in `scripts/lib/dev-cycle-read.sh`.

H2: A gate or boundary fails closed and loudly: a missing dependency, unparseable or unmodelled input, absent verdict or degraded primitive refuses and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access. A cost-saving pre-step instead falls through to the full step, and a refusal at launch names a way forward that keeps the sandbox.
success: each new failure path has a bats case asserting a refusal (or a fall-through to the full step) and a message naming the gap; `rg -n -- '^[^#]*command -v [^|]*\|\| *exit 0' hooks scripts` prints only the three existing lines in `hooks/live-verify-gate.sh` and `hooks/claude-config-audit.sh`.

H3: Every behavioural change is verifiable inside the sandbox with hermetic tests (no network, no live `claude`, no Docker, no host); a host check can add to that, never replace it, and never needs a branch image or devcontainer install or blocks normal use of the harness.
success: `bats` passes in the sandbox with new cases for the change, and `scripts/hermeticity-lint --root .` passes (both author to run).

H4: An LLM judgment is a detector, never an enforcement primitive: a blocking gate keys on something re-checkable from the artifact (an exit code, a verbatim quote with file:line), and a new judgment-based check ships advisory until a recorded falsifier passes.
success: `rg -n -e '^[^#]*claude -p' -e '^[^#]*claude_headless_flags' -- scripts/build-loop.sh scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh hooks/` prints nothing; a new judgment check is capped at amber.

S1: Security measures are proportionate: weigh a restriction's friction (egress profile work, denied tools, extra host steps) against the risk it removes given what is already permitted, and do not add a restriction whose bypass is already allowed; a relaxation that states its residual risk is a valid design. Gates defend against honest slips by a same-uid loop, not a deliberately hostile one, and no restriction may stop all self-merges.
S2: Cost scales by passes, tasks and rounds: add no new mandatory agent dispatch per pass and no more than about 30 lines to always-loaded context (no `@` imports in instruction files) unless the design states the measured delta and why it pays.
S3: Reuse the existing reviewed mechanism (launcher, installer, gate, helper) before adding a second; one trust regime and one code path per job, and one source of truth per rule or grammar, never restated.
S4: Put mechanical steps in tested scripts rather than prose; prose that must guide behaviour arrives at the moment it is needed.
S5: Establish the motive before comparing options; the status quo and deciding against a feature are valid outcomes, and value in real use outside this repo outranks loop-internal metrics.
S6: A new script, skill or workflow needs a call site something actually runs (reachable, not frequently used) and a claimed benefit with an observable that could come out negative; a step that cannot run is re-implemented or removed, never left listed as optional.
S7: Measure before budgeting a saving; a cost cut in the review pipeline is recall-neutral by construction or gated on a measured recall check.
S8: Keep units small and dependency-free: under the ~400-line cap (log row 62), no growth of the 500-plus-line files (`cc-isolated.sh`, `install.sh`), python3 stdlib and bash, no new image package without a decision that names it, and a change one `git revert` undoes.
S10: Spend the user's attention last: at most one host paste per verification, no new recurring host chore or trust decision, nothing left behind to clean up, no merge or loop that waits on the user's manual action when a fail-closed alternative exists, and no safety that depends on the user remembering a flag.
S11: Portable where it costs little: AGENTS.md-readable instructions over Claude-Code-only hooks, pure-text mechanisms over kernel or platform primitives.

## Diff against revision 2

```diff
-This doc is for design-level constraints that steer the choices a loop makes on its own. Coding rules (argv, credentials, host actions, live verification, questions-file ownership, docs) now appear under "Moved out" below. Most of them are already enforced by code here, so no prompt needs to restate them.
+This doc holds the design-level constraints that steer the choices a build loop makes on its own: hard lines prune candidates, soft lines rank the survivors. Coding rules (argv and heredocs, headless `claude`, live verification, test stubs, probes) are in `CLAUDE.md`, and most of them are enforced by code.
-H1: ... what an agent session writes is input to those checks, not a source of their logic.
-success: no new hook, gate, launcher or reviewer invocation reads its code or policy from the working tree; security-reviewer reports no "the reviewed branch can change its reviewer or gate" finding.
+H1: ... what an agent session writes, including git config, hooks and attributes in a checkout it can write, is input to those checks, not a source of their logic. Known interim exception (Q-149 [2]): ...
+success: `rg -n -- '"command": ' hooks/wiring.json | rg -v -F -- '{{CLAUDE_DIR}}/hooks/'` prints nothing, and a new gate or reviewer path is added to GATE_CODE ...
-H2: Fail closed and loudly: a missing dependency, unparseable input, ...
+H2: A gate or boundary fails closed and loudly: a missing dependency, unparseable or unmodelled input, ... A cost-saving pre-step instead falls through to the full step, and a refusal at launch names a way forward that keeps the sandbox.
-success: ...; no `|| exit 0` or silent skip on a missing dependency.
+success: ...; `rg -n -- '^[^#]*command -v [^|]*\|\| *exit 0' hooks scripts` prints only the three existing lines ...
-H3: ...; a host check can add to that, never replace it.
+H3: ...; a host check can add to that, never replace it, and never needs a branch image or devcontainer install or blocks normal use of the harness.
-success: the design names the deterministic channel that carries any model output into a blocking decision; a new judgment check is capped at amber.
+success: `rg -n -e '^[^#]*claude -p' -e '^[^#]*claude_headless_flags' -- <gate files>` prints nothing; a new judgment check is capped at amber.
+S1: ... Gates defend against honest slips by a same-uid loop, not a deliberately hostile one, and no restriction may stop all self-merges.
+S6: ... (reachable, not frequently used) ...; a step that cannot run is re-implemented or removed, never left listed as optional.
+S8: ... no new image package without a decision that names it, and a change one `git revert` undoes.
-S9: Prefer the minimal change one `git revert` undoes, staged so the cheaper step is checked first; after repeated mechanism errors, escalate to a decision instead of another patch.
+S10: ... no merge or loop that waits on the user's manual action when a fail-closed alternative exists, ...
```

## Sources

This section is new evidence only. The citations for revision 2 are in `docs/working/constraints-sources-2026-10-15.md`. "Archive" means `docs/working/questions-archive.md`.

### The H1 line: 4 new decisions, plus revision 2's 4 records, 1 log row and 9 DDs
- `answers-10-16-26.txt:39` (yours): "the desired end-state here would be migrating away from symlinks fully and separating working repo files from referenced image files".
- Archive Q-140:2646: "The snippet always runs the root-owned image copy under /opt … [1] removes code rather than adding it". Q-103:3402: "the gate that runs is the root-owned image copy, which no loop can edit".
- Git-config clause, 6 decisions (all agent-written):
  - FP-116, `failure-patterns.md:258`: "host-git-runs-against-a-container-written-directory … fix:remove-the-path".
  - Q-169, `questions.md:289`: "an agent-planted `core.fsmonitor` would run on the host".
  - Q-098, `questions.md:592`.
  - Q-197, `questions.md:95`: "hooks and fsmonitor off and the git dir pinned".
  - Archive Q-162:2917.
  - Log row 73, `docs/decisions/log.md:96`.
- Cited as the reason in a loop: the Q-146 research doc on `feat/q146-si-script-commits` says "`git -c core.hooksPath=/dev/null commit --no-verify`. The reason is H1."
- Narrowed by: archive Q-149:3442-3452 (your [2], `answers-10-16-26.txt:40`): "A self-merged script or test runs in the next health check, and a self-merged `install.sh` runs on your host at the next release, unreviewed". Revision 2 did not mention this exception.
- Today: the wiring grep prints nothing (rg exit 1; 9 of 9 hook commands name `{{CLAUDE_DIR}}/hooks/`). In a `git archive` copy where one command was rewritten to `bash ./hooks/dd-routing-reminder.sh`, it printed that line. Runs with and without `--no-ignore` matched (the path is explicit). The old success line (a security-reviewer finding) was not a check anything could run.

### The H2 line: 11 decisions in the archive's first half, 6 in its second, 2 of your own lines
- Confirms it:
  - `answers-10-12-26.txt:14` (yours): "refusing to open it seems like the correct default". This is the source of "unmodelled".
  - Archive Q-001:179, Q-013:272, Q-048:1001, Q-062:1395, Q-064:1439, Q-093:1786, Q-112:1931 and Q-118:2013.
- Narrowed by (fall-through):
  - `answers-9-17-26-2.txt:5` (agent co-authored): "If the lite review mechanism is broken, proceeding to a full review is still an appropriate next step".
  - Archive Q-022:389-403: option [1] rejected because it "adds a failure condition the review-fix loop must handle".
- Narrowed by (launch refusal): `answers-10-16-26.txt:18-19` (yours): "When I fell back to running host sessions, it was because I installed a new devcontainer config that was unable to launch cc-isolated … one was the startup check failing." A refusal that sends you to an unsandboxed host session widens access. That works against the line's own "degradation only ever narrows access".
- Cited as the reason in loops: the `fix/cc-isolated-profile-names` DD ("This fails closed (H2)") and the `fix/claude-md-import-guard` DD matrix column.
- Today: the grep prints three lines, `hooks/live-verify-gate.sh:56-57` and `hooks/claude-config-audit.sh:52`. The live-verify gate is fail-open by design ("every internal failure must fall through to exit 0", line 53), which the old line's "no `|| exit 0`" forbade. This is call C1. In a planted copy, the grep caught a new `command -v jq >/dev/null || exit 0` in `scripts/questions.sh` and skipped a commented mention. With and without `--no-ignore --hidden`, the results were identical. Only ignored copies under `.claude/` worktrees and `devcontainer-config/claude-home/` differ, and both are outside `hooks/` and `scripts/`.

### The H3 line: 2 new decisions, both yours
- `answers-10-12-26.txt:4-6`: "requires a devcontainer install with a branched image … This will block verification constantly … We need a different process for validating specific sections of code without blocking use of the harness overall".
- `answers-10-12-26.txt:11`: "See Q-117; this test process is too disruptive."
- Cited as the reason: `fix/egress-dnsmasq-ipset` and Q-125 stay unmerged because of it.
- Today: both success commands run repo code, so they are marked "author to run" and were not executed here.

### The H4 line: no new decisions; success line rewritten
- Today: the grep prints nothing (exit 1, the same with `--no-ignore --hidden`). In a planted copy it caught `verdict=$(claude -p …)` added to `scripts/dev-cycle.sh`. The comment-tolerant form skipped `# … never call claude -p here`; the plain form did not, which is why the line uses `^[^#]*`. The one model call under `scripts/lib/`, `si-morning-summary.sh:870`, is an advisory summary, and the scope deliberately leaves it out.
- Consistent with: `Next Live Interface.md:15` "Verification *cannot* be grounded in AI output". That note is probably about another project, so it is not counted.

### The S1 line: 5 new decisions, 2 of them yours
- `answers-10-12-26.txt:17`: "[3] would prevent all self-merges to main and effectively block development on every project."
- `answers-10-16-26.txt:36`: "claude-workflows is allowed to self-merge, as this is a single author repo."
- Archive Q-133:2361-2375 (you chose [3] against the recommendation: "Over-engineering for a threat the solo setup may never meet"), Q-138:2610 and Q-103:3402.
- Narrowed by: Q-140, where hostile routes `--main-log` cannot see were still closed.

### The S6 line: 2 new decisions, both yours
- `answers-9-20-26.txt:6-7`: "Is it a logical claim that market sizing isn't listed and can't be retrieved? If so, fix … an empirical claim that market sizing has never been selected … no action".
- `answers-9-20-26.txt:12`: "Either this step needs to be re-implemented, or the text should be removed entirely, not just listed as optional."
- Supported by: archive Q-065:1592, Q-046:915 and Q-033:705 (dead code deleted or archived).

### The S8 line: 1 new decision
- Archive Q-086:1691 added `parallel` to the Dockerfile's apt list. That was a decision the old "no new image package" wording did not allow.

### The S9 line (removed at your request, 2026-10-19; the revert clause went to the S8 line, the rest to Moved out): 6 new decisions
- Archive Q-101:1899 ("Cut, then one confirming pass"), Q-143:2637, Q-140:2646, Q-112:1926 and Q-162:2934 ("I took the simplify option").
- Log row 73 (`log.md:96`, today): "three review iterations kept finding new ways…", and the fix was to shrink the trust boundary.
- Cited as the reason in a loop: the `fix/claude-md-import-guard` DD ("C widens scope with no motive (S5, S9)").

### The S10 line: 6 new decisions, 3 of them yours
- `answers-10-16-26.txt:40`: "I don't want this much merging blocked on my manual actions."
- `answers-10-16-26.txt:47`: "When I'm away it's often for several hours".
- Archive Q-152:3096 and Q-137:2445.
- Traded away at least once: archive Q-064:1439 and Q-062:1395, where you took a recurring ssh-agent chore and nuisance refusals in exchange for the bless guarantee. That is why the line stays soft.

### Removing over guarding (proposed as a new soft line; dropped by the author on 2026-10-19, see Left out)
- Log row 73 (`log.md:96`): "The git-config denylist the skill briefly carried is removed rather than kept as false assurance".
- Archive Q-076:1583: "a `.git` scan can't be a guarantee, so on the user's decision it ships as a tripwire … the single list".
- Archive Q-048:1006-1011: the exemption was withdrawn after three passes found bypasses ("A real fix belongs to the file-identity guard redesign, not to more text matching").
- `questions.md:601` (Q-092): remove the hook's deny reader and rely on `permissions.deny`.
- `failure-patterns.md:99`: `remove-the-path`, 7 entries (FP-033, FP-041 and others).
- Author source: transcribed only ("on the user's decision"). No line in your own files states it.

### How the three build loops used the doc (10-17 to 10-19)
- Cited to rank or prune: the H2, S3, S5, S8 and S9 lines. The H1 line was cited as a reason once.
- Never cited: the H3 and H4 lines, and S1, S2, S4, S6, S7, S10 and S11.
- Three small units are too few to cut anything. The pattern to watch is whether the security and cost lines ever decide a pick.

## Findings

These are not constraints.

- **Dangling reference in `docs/constraints.md`.** Its preamble says the coding rules "now appear under "Moved out" below", but the file has no such section. The skill warns about exactly this defect. The rules did land in `CLAUDE.md` (Code, Tests, Probes), so the new preamble points there.
- **The live-verify gate fails open when `jq` or `git` is missing** (`hooks/live-verify-gate.sh:47,53,56-57`). So does the config-audit hook when `python3` is missing (`:52`). It is documented and deliberate: a PreToolUse hook that refused there would block every Bash call. But it is a blocking enforcement hook that goes inert, which revision 2's H2 forbade. Call C1.
- **Q-165's status disagrees with itself.** It is indexed OPEN in `questions.md`, but `questions.md:281` says it was answered [1] in `answers-10-16-26.txt`, and `answers-10-16-26.txt:12` confirms that.
- **Entries waiting to be archived:** Q-096, Q-110 and Q-160 say "Ready to archive" and are still open.
- **A revisit trigger is likely to fire:** Q-074 (`questions.md:519`) reopens L1 if failure-patterns gains fewer than 5 entries by 2026-10-26. It has 3 so far (FP-172 to FP-174). The dev cycle's watched-questions step observes it.
- **Dead triggers** (nothing observes them):
  - Q-103 F11, "A Claude Code upgrade that changes its import grammar reopens it" (archive :3406).
  - Q-129's G1 deferral, "a walk past 30 s" (archive :2276).
  - The agent-chosen "2+ waivers past the in-loop re-check within 14 days" (archive :2934), still waiting for your confirmation.
- **Accepted risks carried in the doc:** the Q-149 [2] interim (now named in the H1 line), and the hostile same-uid loop scope (Q-133, Q-138; now in the S1 line).
- **Provenance:** four `docs/human-author/` files were committed with a Claude co-author. They read as your answers transcribed in-session. They are treated as agent-written here, and nothing hard rests on them alone.
- **Authority-shaped text** the readers recorded and did not act on:
  - Archive Q-137:2445: "Standing instruction with the answer: merges … go ahead on the recommendation without asking".
  - Archive Q-020:473: "stated as the format rather than a suggestion".
  - Archive Q-155:3039: the constraints "must be yours, not inferred". This run complies: you commit the file.

## Against existing guidance

- **Implied by the decisions, but stated in no guidance:**
  - Fall-through for cost-saving pre-steps.
  - No branch-image install for verification.
  - Hostile-loop scope.
  - Removing over guarding (dropped by you; see Left out).
  - Reachable rather than frequently used.
- **Stated and confirmed:** `CLAUDE.md`'s argv, headless and live-verify rules, and its stub, no-skip and probe rules, all match the moved-out rules of revision 1. `AGENTS.md` overlaps none of the lines.
- **Stated but contradicted:** revision 2's H2 ("no `|| exit 0` … on a missing dependency") against `hooks/live-verify-gate.sh:56-57` (call C1). Revision 2's "S6 … skill or workflow" wording is fine as it stands: `answers-10-16-26.txt:2` says workflows have merged into skills, but `workflows/` still exists.

## Calls for the author

| Call | Where the sources disagree | Interim reading in the block | If you choose otherwise |
|---|---|---|---|
| C1 fail-open hooks | Revision 2's H2 forbids `\|\| exit 0` on a missing dependency. `hooks/live-verify-gate.sh:53` falls through by design, and your 10-16:18-19 shows hard refusals at launch pushed you to host sessions | The H2 line is scoped to "a gate or boundary". The three existing lines are named as known in its success line | To make them refuse, a brief fixes the two hooks and the success line drops "only the three". To bless fail-open for hooks, the line gains "a hook on every tool call may fail open if it says so" |
| C2 H1 interim | Q-149 [2] accepted that the health check runs the change's own code, which H1's letter forbids | The H1 line names the exception inline as an interim | If you would rather the doc not carry it, delete the sentence. Loops then see the H1 line as violated by the cycle's own health check |
| C3 hostile-loop scope | Q-133 [3] and Q-138 (yours) took hostile loops out of scope; Q-140 still closed quiet hostile routes | Added to the S1 line, soft | Making it hard prunes any design that spends passes on hostile-class findings. Leaving it out lets loops treat each such finding as a new round |
| C4 removing over guarding | It rests on transcribed answers and agent-written failure patterns; no line in your own files states it | Dropped (your answer, 2026-10-19) | Restore it as a soft line |
| C5 fall-through clause | Your Q-022 answer is in `answers-9-17-26-2.txt`, which carries an agent co-author | Kept in the H2 line | Delete the clause if Q-022 was a one-off |

Your answers in session (2026-10-19):
- C1: name the three lines as known, as drafted.
- The no-branch-image clause is a design constraint and stays in the H3 line.
- C3: soft, in the S1 line.
- C4: drop the proposed removing-over-guarding line.
- Remove the S9 line as guidance rather than a design constraint: its revert clause folds into the S8 line, and its repeated-errors clause goes to `workflows/review-fix-loop.md` (Moved out). The S10 and S11 IDs are not renumbered, so existing loop citations stay valid.
- C2 and C5 are still open, at their interim readings.

Questions for the top hard lines:
- **The H2 line:** does "a gate or boundary" match your stance, or should every script fail closed? What has the fail-closed launch check cost you since Q-170?
- **The H3 line:** is "never needs a branch image or devcontainer install" design-level, or practice for `guides/`?
- **The H1 line:** should the git-config clause stay inside it, or would you rather the doc stay short and the clause live in `security-reviewer`?

## Moved out

| Rule | Kind | Enforced today by | Proposed home | Paste-ready text |
|---|---|---|---|---|
| Size cap and iteration-4 gate waived only by you (archive Q-104:2042, Q-111:1948) | authority | `workflows/review-fix-loop.md` § Size re-check, pr-prep step 1a | already covered | none |
| Self-merge policy and never-lines (Q-103, Q-149) | setting | `docs/dev-cycle.md:7-11` | already covered | none |
| Pre-existing red findings before new work (`answers-10-16-26.txt:22`, "I'm inclined") | setting | nothing | dev-cycle skill, pick order | "Pick a red finding that predates the unit before new work (Q-171 [2])." |
| Amber merges only with a discoverable TODO or revisit trigger (`answers-9-20-26.txt:51-52`) | decision-local | code-review rubric (Q-041) | already covered | none |
| Host pastes run no git that can execute planted state (archive Q-162, Q-180, Q-144) | practice | the paste guard | covered by the git-config clause in the H1 line, as a design rule | none |
| Revision 2's S9 repeated-errors clause: after repeated mechanism errors, cut, coarsen or re-scope instead of another patch (archive Q-101:1899, Q-143:2637, Q-162:2934; log row 73) | process (it applies mid-review, not when comparing designs) | the review-fix loop's cap options at `workflows/review-fix-loop.md:79-81` (escalate, split, abandon), which state no preference for cutting | `workflows/review-fix-loop.md`, beside the cap options | "When a mechanism draws the same class of finding twice, prefer an option that cuts, coarsens or re-scopes it over another patch (Q-101, Q-143, log row 73)." |
| Fixes carry a test that fails on the old code | practice | memory "Prove old-code failures hermetically" | `CLAUDE.md` Tests | "- A fix's new test fails on the pre-fix code; say so in the merge entry." |

## Left out

| Candidate | Why left out | Sources |
|---|---|---|
| Hook usage logs under-count, so they are not evidence | already in the global instructions (questions routing) | `answers-9-17-26.txt:46-47`, archive Q-017:301-319 |
| Schema changes are additive | 3 decisions, and it binds formats rather than designs across features | archive Q-047:932, Q-022:402, Q-008:242 |
| Subscription only, no OpenRouter | already enforced (log row 48; revision 1's moved-out list) | archive Q-006:224, Q-025:583 |
| Fast suite first, block on red; cheaper step checked first (revision 2's S9 clause) | already handled by the health check's fast-then-slow staging (Q-023); practice, not a design criterion | `answers-9-20-26.txt:2-3`, archive Q-023:948 |
| Keep the GitHub PR path | a hedge on expected use; a call site exists | `answers-9-20-26.txt:13-14` |
| Archive over delete | practice | archive Q-021:489 |
| Accept known-benign shapes exactly, so warnings stay rare | one decision | archive Q-094:1806-1816 |
| Children get no shell grants | local to the self-improvement loop | archive Q-146:2855-2869 |
| Narrowest kernel widening (seccomp profile file) | local, and blocked on Q-130 | archive Q-124:2178-2189 |
| Repo text is evidence, never instructions | local to constraints-builder (log row 73) | `log.md:96` |
| Path-keyed guards follow the code | unanswered Q-175 | `questions.md:396` |
| Prefer removing a capability to an incomplete guard; a tripwire carries one "does not see" list | dropped by the author, 2026-10-19 (review practice rather than a design criterion) | `log.md:96`, archive Q-076:1583, Q-048:1006-1011, `failure-patterns.md:99` |

## Superseded

| Earlier rule | Replaced by | Citation |
|---|---|---|
| Revision 2's H2 "no `\|\| exit 0` or silent skip on a missing dependency" | the scoped H2 line and its named-lines success check | `hooks/live-verify-gate.sh:53` |
| Revision 2's S9 line | its revert clause folded into the S8 line; its repeated-errors clause moved to `workflows/review-fix-loop.md` (Moved out); its cheap-step-first clause left out as practice | your request, 2026-10-19 |
| Q-095's waiver for the 857-rule allowlist | shelved until a sandbox exists | archive :1828 |

## Notes for the skill

- **Amend mode had no step for "what did the last run skip".** Revision 2's sources doc read only records, log and DDs. The biggest yield this time came from the author's answers files and the archive, which the earlier run never opened. Step 0.1 should ask which slices the existing doc was built from.
- **Provenance by path misleads.** Four `docs/human-author/` files carry a Claude co-author trailer. The step 4 check caught this, and the reader brief's AUTHOR-PATH tag would have hidden it.
- **Evidence from loop outcomes is now available**, through the three research docs on the build-loop branches, and it was cheap to read. The skill does not name it as a source. It should: it shows which lines decide picks.
- **The existing doc carried the defect the skill warns about** (a preamble pointing at "Moved out" in a file without one). That is evidence the author pasted the block from a working doc.
- **Revision 2's success lines were mostly not runnable** ("security-reviewer reports no…", "the design names…"). Rewriting them as greps found a live contradiction (live-verify-gate's fail-open lines) within minutes.
- **The author's corrections:** they took the recommended reading on C1, C3 and the H3 clause, and dropped the one new line (removing over guarding) as practice. A candidate resting only on agent-written evidence was the one cut, which is consistent with the step 4 authority ranking.
- **The author moved a soft line out after reading the draft:** the S9 line (minimal revertable change, cheap step first, cut after repeated errors) failed the discrimination test on two of three clauses, but it passed both of the skill's earlier sorts (revision 2's and this run's). Clauses that trigger mid-review ("after repeated errors") are process. The sort in step 5 should test each clause for *when* it applies, not only whether designs could differ.
- **Recording the answers broke the parse once:** a list item beginning `- H3:` made the file unreadable (duplicate ID). The template's rule covers it, but writing answers back into the doc is the moment it bites.
- **`awk` with `{40}` is not portable** (mawk). The blame loop printed nothing until it was rewritten with `grep -E`. A silent empty result looks like "no author commits".
