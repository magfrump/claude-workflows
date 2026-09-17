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
| [Q-010](#q-010--elan-release-host) | Which host does elan actually fetch toolchains from — `release.lean-lang.org` or `releases.lean-lang.org`? | 2026-09-12 |
| [Q-013](#q-013--elan-version-to-ship) | Is `ELAN_VERSION=v3.1.1` the version to ship? **ANSWERED 2026-09-15: no — `v4.2.4`, taken from the GitHub... | 2026-09-12 |
| [Q-015](#q-015--scholar-hostnames) | Confirm the three `scholar` hostnames that no search summary covered — `pmc.ncbi.nlm.nih.gov`, `api.biorx... | 2026-09-17 |
| [Q-017](#q-017--rpi-doc-zero-reads) | `workflows/research-plan-implement.md` — the documented default — was opened **0 times in 49 days** (27... | 2026-09-17 |
| [Q-018](#q-018--failure-patterns-backfill) | `docs/thoughts/failure-patterns.md`: backfill from the 104 eligible `fix(...)` commits, or delete the file? | 2026-09-17 |
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
