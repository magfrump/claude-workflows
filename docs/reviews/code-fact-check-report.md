Commit: 0661353

# Code Fact-Check Report

**Repository:** `/workspace` (claude-workflows)
**Scope:** `git diff -M -C 2d679ce..HEAD` (four commits: 4d41add, c56be81, 59ca38f, 0661353) plus the commit messages from `git log 2d679ce..HEAD`, `docs/reviews/prompt-audit-2026-09-11.md` and `docs/decisions/log.md` row 47
**Checked:** 2026-09-12
**Total claims checked:** 13
**Summary:** 3 verified, 4 mostly accurate, 2 stale, 2 incorrect, 2 unverifiable
**Commit:** 0661353
**Replication:** k=3

Merged from three byte-identical-prompt replicates (27 / 29 / 21 claims) by most-severe-wins,
annotations merged by union. Replicate reports: `code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`
(all `Commit: 0661353`). Execution logs: `docs/reviews/execution-logs/r{1,2,3}-*`.

---

## Claim 1: "All 85 tests across the code-review suites pass"

**Location:** `docs/reviews/prompt-audit-2026-09-11.md:569` and commit `59ca38f` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "the *pass* half is verified — `bats test/skills/code-review-*.bats` exits 0, 97 ok / 0 not ok / 0 skip" · r1: "exhaustive subset-sum over all eight candidate suites returns the empty set — no reading produces 85" · r2: "counts were identical before the change, so the figure was never true" · r3: "per-suite counts 15/10/9/17/18/17/11, +19 for `test/code-review-gate.bats`"
**Evidence:** the seven `test/skills/code-review-*.bats` suites hold **97** tests; the four suites commit `59ca38f` modified hold **53**.
**Scope:** establishes that the number is wrong and that the suites pass; does not establish which suite list the author intended.
**Legibility-target:** for-author

## Claim 2: "health-check failures are identical to the pre-change baseline (four, all pre-existing)"

**Location:** commit `c56be81` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "the *identity* and *all pre-existing* halves are both confirmed — the failure set is the same at HEAD and at `2d679ce`" · r1: "a baseline run also showed an extra `✗ BATS tests failed`; a control run at HEAD from a worktree reproduced it, so that one is an environment artifact, not a regression" · r2: "`check_md_consistency` calls `fail`, not `warn`" · r3: "the two omitted failures are the ones whose message text this very change rewrites"
**Evidence:** `scripts/health-check.sh` emits **six** `✗` lines at both commits — four shellcheck plus two `MD file consistency (workflows)`.
**Scope:** establishes the count is wrong; does not disturb the identity claim.
**Legibility-target:** for-author

## Claim 3: `workflows/pr-prep.md:183` link label

**Location:** `workflows/pr-prep.md:183`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Mostly accurate · r2=Stale · r3=Verified (anchor resolves) + scope note
**Replicate annotations:** r1+r2+r3: "the href was correctly retargeted to `references/override-log.md#capture-format`; the link *text* still reads `skills/code-review/SKILL.md`, which no longer holds the capture format"
**Evidence:** `` [`skills/code-review/SKILL.md`](../skills/code-review/references/override-log.md#capture-format) ``
**Scope:** establishes the label is wrong; the anchor itself resolves.
**Legibility-target:** for-author

## Claim 4: "see [Capturing new overrides](…) **below**"

**Location:** `skills/code-review/SKILL.md:158`, same drift unlinked at `:1173`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Stale · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "the section is no longer below, it is in another file"
**Evidence:** `skills/code-review/SKILL.md:158` — "see [Capturing new overrides](references/override-log.md#capturing-new-overrides) below"
**Scope:** establishes two positional references are wrong post-split.
**Legibility-target:** for-author

## Claim 5: "kills the last surviving 'Task tool' reference"

**Location:** commit `4d41add` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "`patterns/orchestrated-review.md:31` still names it, deliberately, in a terminology note — the killed one was the last *prescriptive* reference" · r2: "two live occurrences remain outside `skills/`; the audit's own F2 row scopes it correctly ('in the skill'), the commit dropped the qualifier" · r3: "four descriptive occurrences remain by design — `guides/skill-format-audit.md:148,156,161,167` (the finding's own text)"
**Evidence:** `patterns/orchestrated-review.md:31` — "regardless of whether the underlying implementation uses the Task tool, Agent tool, or manual sequential processing"
**Scope:** establishes the unqualified wording overstates; the substantive fix is real.
**Legibility-target:** for-author

## Claim 6: decision-log row 47 — "byte-identical" / "takes effect at the next install.sh + rebuild"

**Location:** `docs/decisions/log.md:68`, echoed in commit `c56be81`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "'byte-identical duplication' holds only while the baked image is current with the repo — the image is stamped 2026-09-09, the repo copy changed 2026-09-11" · r2: "true for containers but silent on host-native installs, where the old `~/.claude/CLAUDE.md` symlink dangles at `git pull` time and must be recreated"
**Evidence:** `docs/decisions/log.md:68` — "so the image layout and `link-claude-home.sh` are unchanged"
**Scope:** establishes two unstated preconditions; does not contradict the change.
**Legibility-target:** for-author

## Claim 7: `test/skills/code-review-assurance-contract.bats:123` extraction range

**Location:** `test/skills/code-review-assurance-contract.bats:123`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified + scope note
**Replicate annotations:** r1: "`sed -n '/^## Important Reminders/,$p'` now extends past SKILL.md into all three reference files, so `references/rubric.md:174` can satisfy the assertion on its own" · r3: "the assertion still lands on real Important Reminders text (`SKILL.md:1231`), so the test is not vacuous — but its scope widened silently" · r3: "the concatenated `SKILL_CONTENT` now contains three duplicated `##` headings (stub + real section); no current test range-extracts one, but a future `sed -n '/^## Deliverable 1/,…'` would silently capture the stub"
**Evidence:** `test/skills/code-review-assurance-contract.bats:123` — "sed -n '/^## Important Reminders/,$p'"
**Scope:** establishes the range widened; does not establish the test currently passes vacuously.
**Legibility-target:** for-author

## Claim 8: the re-baselined judge default `anthropic/claude-sonnet-5`

**Location:** `scripts/cross-model-review.py:374`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Replicate verdicts:** r1=Mostly accurate · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1+r3: "the underlying Anthropic model id `claude-sonnet-5` is real and current, and the slug matches the harness's own naming shape" · r2+r3: "confirming OpenRouter serves it needs a live `GET https://openrouter.ai/api/v1/models` — blocked, no egress" · r3: "`main()`'s fail-closed unpriced-model guard covers `--models`, not `--judge`, so a bad judge slug surfaces as a stage-2 API error rather than a pre-flight abort"
**Evidence:** `scripts/cross-model-review.py:374` — `ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")`
**Scope:** establishes the construction is consistent; does not establish the slug resolves.
**Legibility-target:** for-author

## Claim 9: "the next candidates are Stage 1's dispatch template (~240 lines) and Stage 3's synthesis procedure (~160)"

**Location:** commit `59ca38f` message, `docs/reviews/prompt-audit-2026-09-11.md` F8 row
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Replicate verdicts:** r1=Verified · r2=Unverifiable · r3=Verified
**Replicate annotations:** r2: "'~240 lines' names no unit the file delimits — Stage 1 is 302 lines (`:382-683`), its pre-merge dispatch prose 118 (`:382-499`); Stage 3's '~160' is exact (159)"
**Evidence:** `skills/code-review/SKILL.md:382-683` — Stage 1 spans 302 lines; its pre-merge dispatch prose spans 118 (`:382-499`)
**Scope:** establishes the second figure; the first depends on an unstated line range.
**Legibility-target:** for-author

## Claim 10: single-sample label provenance

**Location:** `skills/code-review/SKILL.md:1136`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=—  · single-replicate detection
**Replicate annotations:** r2: "the single-sample label is *used* in `references/chat-synthesis.md` but *defined* in `references/rubric.md:499`"
**Evidence:** `skills/code-review/references/rubric.md:499` — "#### The single-sample label"
**Legibility-target:** for-author

## Claim 11: the basename staging, payload layout, and `link-claude-home.sh`

**Location:** `devcontainer-config/install.sh:41`, `devcontainer-config/link-claude-home.sh:47`, `docs/decisions/log.md:68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "re-derived by actually running `install.sh` to the prompt — payload root gets the file plus six dirs, no `global-instructions/` subdir, byte-identical content" · r2+r3: "`basename` is the identity for the other six entries, so the layout is unchanged and `ENTRIES=(… CLAUDE.md)` still resolves"
**Evidence:** `devcontainer-config/install.sh:51` stages each entry under its basename; `devcontainer-config/link-claude-home.sh:47` still lists `CLAUDE.md` among its ENTRIES
**Scope:** establishes the staged layout; does not establish behaviour inside a built image.
**Legibility-target:** for-orchestrator-synthesis

## Claim 12: the F8 split — line counts, anchors, moved text

**Location:** `skills/code-review/SKILL.md:1`, `skills/code-review/references/rubric.md:1`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "all 51 anchor links touching `skills/code-review/` resolve" · r2: "all **54** anchor links across the skill, its references and every external referrer resolve; every moved block is byte-identical to its original apart from three link-depth fixes" · r3: "0 unresolved; line counts 1,909 → 1,256 and 515/126/52 are exact"
**Evidence:** `skills/code-review/SKILL.md` 1,909 to 1,256 lines; `references/rubric.md` 515, `references/chat-synthesis.md` 126, `references/override-log.md` 52
**Legibility-target:** for-orchestrator-synthesis

## Claim 13: the F4 cap retirement is complete; `install.sh` is outside the live-verify gate

**Location:** `devcontainer-config/cc-isolated.sh:107`, `hooks/live-verify-gate.sh:57` (plus a repo-wide sweep for the retired cap)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "repo-wide search (minus archive/external/runs/docs/node_modules) finds zero surviving `<300 words` / `output cap` / `#default-output-cap` references" · r3: "`install.sh` appears neither in `enforcement_files()` nor in the gate's regex — no `Live-verified:` trailer required"
**Evidence:** `devcontainer-config/cc-isolated.sh:107` — `enforcement_files()` lists six names, none of them `install.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/reviews/prompt-audit-2026-09-11.md:569`, commit `59ca38f`): "All 85 tests across the code-review suites pass" — real count 97 across the seven suites, 53 across the four this change modified. All three replicates, unanimous.
- **Claim 2** (commit `c56be81`): "health-check failures … (four, all pre-existing)" — six, not four. The identity and all-pre-existing halves both hold.

### Stale
- **Claim 3** (`workflows/pr-prep.md:183`): link label names a file that no longer holds the capture format.
- **Claim 4** (`skills/code-review/SKILL.md:158`, `:1173`): "below" for a section now in another file.

### Mostly Accurate
- **Claim 5** (commit `4d41add`): "last surviving 'Task tool' reference" — the last *prescriptive* one; descriptive occurrences remain by design.
- **Claim 6** (`docs/decisions/log.md:68`): silent on image currency and on host-native installs.
- **Claim 7** (`test/skills/code-review-assurance-contract.bats:123`): the extraction range widened into the reference files.
- **Claim 8** (`scripts/cross-model-review.py:374`): the judge slug's construction is consistent; its presence in OpenRouter's catalogue is unconfirmed.
- **Claim 10** (`skills/code-review/SKILL.md:1136`): the single-sample label is used in one reference file and defined in another.

### Unverifiable
- **Claim 8** (`scripts/cross-model-review.py:374`): no egress to confirm the OpenRouter slug. Needed: one `GET https://openrouter.ai/api/v1/models` from a networked host.
- **Claim 9** (commit `59ca38f`): "Stage 1's dispatch template (~240 lines)" names no unit the file delimits. Needed: the line range the author measured.

---

## Escalations

| Entry | Raised by | `path:line` | Addressee |
|---|---|---|---|
| Three measured counts quoted as verification evidence are wrong in one four-commit series ("85 tests" ×2, "four failures" ×1). Same shape as both existing `hallucination-patterns.md` entries; excluded from that log by its own rules (miscount, not fabrication), so it is raised here instead. The counts are being written from recollection rather than from command output — the failure the "Verified:" lines exist to prevent. | r1, r2, r3 | `docs/reviews/prompt-audit-2026-09-11.md:569`; commits `59ca38f`, `c56be81` | orchestrator |
| The "85" appears in one immutable place (commit message) and one editable place (the audit doc). The audit doc is what a future pass reads as the record of what was verified — fix it there. | r2 | `docs/reviews/prompt-audit-2026-09-11.md:569` | orchestrator |
| `test/agents-gemini-sync.bats` never reads the instructions file (it diffs `AGENTS.md` against `GEMINI.md` only), so citing its pass as evidence for the F1 move is a non-sequitur. | r3 | commit `c56be81` message | orchestrator / test-strategy |
| The assurance suite's `/^## Important Reminders/,$p` end anchor now means "end of the concatenation" rather than "end of SKILL.md". | r1, r3 | `test/skills/code-review-assurance-contract.bats:123` | test-strategy |

---

## Verdict stability

- **Clusters:** 13
- **Unanimous among reporting replicates:** 9
- **Disagreed:** 4 — Claim 2 (r2 Mostly accurate vs r1/r3 Incorrect), Claim 3 (Stale / Mostly accurate / Verified+note), Claim 8 (Mostly accurate / Unverifiable / Unverifiable), Claim 9 (Verified / Unverifiable / Verified)
- **Agreement rate:** 9/13 = **69%**

Every disagreement is a severity-band adjacency on the same underlying observation — no replicate contradicted another's evidence. The two blocking-channel clusters (Claims 1 and 2) were reached by all three, and Claim 1 unanimously.
