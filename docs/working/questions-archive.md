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
| [Q-046](#q-046--failure-analysis-fix-or-delete) | `scripts/failure-analysis.sh` computes its re-attempt pass rate against its own definition (it counts attem... | 2026-09-18 |
| [Q-047](#q-047--hypothesis-log-run-id) | Hypothesis-log rows record only a round number, and round numbers restart every self-improvement run, so th... | 2026-09-18 |
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

