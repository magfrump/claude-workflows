# Code Review Rubric

**Scope:** `2d679ce..HEAD` (main, 4 commits) | **Reviewed:** 2026-09-12 | **Status: 🟡 CONDITIONAL PASS** — 0 red (R1 fixed 2026-09-12), 5 amber awaiting resolution or justification

Panel: code-fact-check k=3 (opus) · security-reviewer · api-consistency-reviewer · architecture-review · test-strategy. Delivery mode: self-read (218 KB diff, over the 25k-token shared-block budget).

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | Gate 1d ("Critical file protection") no longer protects the global instructions file. The gate matches repo-relative deleted paths against the whole-string glob `CLAUDE.md`; after the move the file is `global-instructions/CLAUDE.md`, which does not match, so an autonomous self-improvement branch that deletes the entire instruction set is recorded as `critical_files: pass`. Executed: the `case` arm reads `scripts/self-improvement.sh\|docs/evaluation-rubric.md\|CLAUDE.md)`. | API consistency + Security | Breaking (api-consistency) / Medium-High (security) | `scripts/self-improvement.sh:1172-1181` | for-author | — | ✅ Fixed 2026-09-12 — the arm is now basename-keyed (`*/CLAUDE.md`) so a future move cannot disarm it again |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The config auditor's default scan roots contain the literal `"CLAUDE.md"`, and `iter_targets` skips a missing root silently. Auditing a checkout in place (fresh clone, CI, worktree, pre-install host) no longer scans the instructions file for injected content. `guides/claude-config-security-checkup.md:61` still documents the old coverage. | Security | Medium | security-reviewer + api-consistency | for-author | — | ✅ Fixed 2026-09-12 | Coverage partly survives via the `~/.claude` root wherever the symlink resolves; the loss is specific to in-place checkout scans — which is the branch-review case the guide names. |
| A2 | `code-review-assurance-contract.bats:123`'s `sed -n '/^## Important Reminders/,$p'` now ends at end-of-*concatenation*, not end-of-`SKILL.md`, and is satisfied by `references/rubric.md:174`'s own `### Confirmed Good is a claim, not an output` heading. Mutation-proven in both directions: deleting the two real Important-Reminders bullets leaves the test green post-split, red pre-split. | Test harness | Medium (executable-defect channel, executed → native severity) | test-strategy, confirmed by orchestrator execution | for-author | — | ✅ Fixed 2026-09-12 | The suite that was updated is the one that broke; `code-review-factcheck-replication.bats:144` uses the same idiom, was not re-pointed, and still binds correctly. |
| A3 | `code-review-assurance-contract.bats:166-167` still greps `"$SKILL"` while every sibling assertion migrated to `$SKILL_CONTENT`. Executed: `grep -c 'PASSES REVIEW\|DOES NOT PASS\|CONDITIONAL PASS' skills/code-review/SKILL.md` → **0**. The status lines moved to `references/rubric.md`, so both negative assertions now pass vacuously. One-word fix. | Test harness | Medium (executable-defect channel, executed → native severity) | test-strategy, confirmed by orchestrator execution | for-author | — | ✅ Fixed 2026-09-12 | The `run !` mechanism itself is correct under bats 1.8.2; the bug is the operand, not the idiom. |
| A4 | `guides/` is staged into the image payload, and `guides/cross-project-setup.md:7,34` now cite `global-instructions/CLAUDE.md` — a path that does not exist in the deployed tree, where the file sits at the payload root. The pre-move bare-filename text was correct in both layouts; the new text is correct in only one. | Architecture | Coupling | architecture-review | for-author | — | ✅ Fixed 2026-09-12 | Fix before the next `install.sh` bakes it. |
| A5 | Fact-check **Incorrect**: "All 85 tests across the code-review suites pass" — the seven `test/skills/code-review-*.bats` suites hold **97** tests (all passing); the four modified suites hold 53. No subset sums to 85. Appears in `docs/reviews/prompt-audit-2026-09-11.md:569` (editable) and commit `59ca38f` (immutable). | Fact-check | Incorrect (high), doc-only → 🟡 per decision 031 | fact-check k=3, unanimous | for-author | — | ✅ Fixed 2026-09-12 | The commit-message instance is unfixable history → route to the override log as an accepted-immutable acknowledgment. |
| A6 | Fact-check **Incorrect**: "health-check failures are identical to the pre-change baseline (four, all pre-existing)" — there are **six** `✗` lines (four shellcheck + two MD-consistency). The identity and all-pre-existing halves are both confirmed. | Fact-check | Incorrect (high), doc-only → 🟡 | fact-check (r1, r3 Incorrect; r2 Mostly accurate) | for-author | — | ✅ Fixed 2026-09-12 | The two omitted failures are exactly the ones whose message text this change rewrites. |
| A7 | Fact-check **Stale** ×3: `workflows/pr-prep.md:183`'s link label still reads `skills/code-review/SKILL.md` while its href points at `references/override-log.md`; `skills/code-review/SKILL.md:158` and `:1173` say a section is "below" when it is now in another file (architecture adds `:741` and `:992`). | Fact-check + Architecture | Stale | fact-check + architecture-review | for-author | — | ✅ Fixed 2026-09-12 | — |
| A8 | Two dangling `Mandatory Execution Rule 1` pointers survive at `skills/code-review/SKILL.md:945,957` after that section was renamed and unnumbered by F3. `scripts/lib/si-functions.sh:590-592` cites SKILL.md for a row format that now lives only at `references/rubric.md:43`. | API consistency + Architecture | Inconsistent / Coupling | api-consistency + architecture-review | for-author | — | ✅ Fixed 2026-09-12 | — |
| A9 | The `.bats` `SKILL_CONTENT` contract now has two conflicting definitions across seven sibling suites, and the 8–11-line concat block is copy-pasted byte-identically into four of them while `test/skills/helpers.bash` already exists and is loaded by one. The `cat` order is load-bearing (two suites bound ranges with `/^### Rubric Status Line/`, which exists only in `rubric.md`) and is enforced only by a comment. | API consistency + Architecture | Inconsistent / Coupling | api-consistency + architecture-review | for-author | — | 🟡 Open | — |
| A10 | The reference-file cut line does not match the stated rule. `references/rubric.md` holds severity semantics the *running* pipeline consults at Stage 1.5, Stage 2.5 and all four Stage-3 cross-checks — 19 links from 17 sites — so the deferral saves nothing except on a fact-check short-circuit, and `rubric.md`'s `###` anchors became a de-facto public API with no test asserting they resolve. Recommended re-cut: `severity.md` (read at 1.5/2.5) vs `rubric.md` (template, read at Stage 3). | Architecture | Coupling | architecture-review | for-author | — | 🟡 Open | SKILL.md's own reference table concedes it: "Needed from the moment you tier a finding." |
| A11 | Reference-link direction is cyclic: `references/rubric.md:513` → `../SKILL.md#deliverable-1-chat-synthesis`, which is a 5-line stub forwarding to `chat-synthesis.md`, which links back to `rubric.md`. The link routes the reader to a forwarding address rather than the spec. | Architecture | Coupling | architecture-review | for-author | — | 🟡 Open | — |
| A12 | `health-check.sh:237`'s bare `continue` on a missing `$GLOBAL_MD` reduces MD-consistency to an AGENTS-vs-GEMINI comparison that `agents-gemini-sync.bats` already guarantees — and still prints `✓`. `warn` never touches `FAIL`. A future rename of the instructions file degrades the check to a vacuous pass. | Test harness / Architecture | Medium | test-strategy | for-author | — | 🟡 Open | — |
| A13 | `install.sh`'s missing-source path is warn-and-continue: a payload with no global instruction file is assembled, blessed, and linked (`link-claude-home.sh:51` skips again), exit 0. Likelier now that the source path is a directory deep. Executed: a basename collision does not overwrite — `cp -r` *nests* (`stage/hooks/hooks/y.sh`) and the extra tree gets blessed by the manifest walk. | Security + Architecture | Low (security) / Coupling (architecture) | security-reviewer + architecture-review | for-author | — | 🟡 Open | Escalated from Low because two critics reached the same seam independently and the failure is silent-and-total. Open question for the author: should a missing payload source be fatal? |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `--judge`'s new pinned default is excluded from the `unpriced` / `--max-usd` fail-closed guard that covers `--models`, so a bad or expensive judge id fails only at stage 2; `api()`'s `except Exception` retries a 4xx three times. | security + api-consistency | Low | for-author | — | 🟢 Open |
| C2 | `anthropic/claude-sonnet-5` could not be confirmed against OpenRouter's catalogue (no egress). Needs one `GET /api/v1/models` from a networked host before the next cross-model run. | fact-check | Unverifiable | for-author | — | 🟢 Open |
| C3 | The new `references/` headers diverge from the `ui-visual-review` precedent (HTML comment instead of `# H1` + load-trigger line). That missing H1 is what produces the three duplicated `##` headings in the concatenation. | api-consistency | Minor | for-author | — | 🟢 Open |
| C4 | `SKILL_MD` in `code-review-format-contract.bats` now names a non-`SKILL.md` file three lines from `SKILL`, with a stale file header. | api-consistency | Minor | for-author | — | 🟢 Open |
| C5 | Six-plus guide referrers still use the bare `CLAUDE.md` path (`pr-prep.md`, `parallel-worktrees.md`, `divergent-design.md`, `workflow-selection.md`, `workflow-dependency-graph.md`), now ambiguous against consumer projects' own files — the repo spells the same file two ways. | architecture + api-consistency | Minor | for-author | — | 🟢 Open |
| C6 | `test/cc-isolated-functions.bats:420` passes on a substring blind to the very change it names. | api-consistency | Minor | for-author | — | 🟢 Open |
| C7 | One `## Mandatory Execution Rules` block survives at `skills/ui-visual-review/SKILL.md:58` — F3 covered three orchestrators and missed this one. Open question: deliberate? | api-consistency + test-strategy | Minor | for-author | — | 🟢 Open |
| C8 | `install.sh` is in neither `enforcement_files()` nor `live-verify-gate.sh`'s regex, yet it assembles the hashed payload, prints the review diff, and calls `--bless`. Pre-existing; this diff makes it load-bearing. | security | Informational | for-author | — | 🟢 Open |
| C9 | No test covers the basename staging (T3: a hermetic `install.sh` staging test) or the `GLOBAL_MD` indirection. `cross-reference-integrity.bats:31`'s target filter `(workflows\|skills\|guides\|patterns)/` excludes both `global-instructions/` and the 20 new `references/*.md` links; `link-claude-home-wiring.bats:37` stubs the payload with `touch "$SRC/CLAUDE.md"`. | test-strategy | Low (advisory) | for-author | — | 🟢 Open |
| C10 | "The next candidates are Stage 1's dispatch template (~240 lines)" names no unit the file delimits — Stage 1 is 302 lines, its pre-merge dispatch prose 118. Stage 3's "~160" is exact (159). | fact-check | Unverifiable | for-author | — | 🟢 Open |
| C11 | Decision-log row 47 is silent on two preconditions: "byte-identical" holds only while the baked image is current (stamped 2026-09-09 vs a repo copy edited 2026-09-11), and host-native installs lose the old `~/.claude/CLAUDE.md` symlink at `git pull` time rather than at rebuild time. | fact-check | Mostly accurate | for-author | — | 🟢 Open |
| C12 | Commit `4d41add`'s "last surviving `Task tool` reference" overstates — it was the last *prescriptive* one; descriptive occurrences remain by design at `patterns/orchestrated-review.md:31` and `guides/skill-format-audit.md:148,156,161,167`. | fact-check | Mostly accurate | for-author | — | 🟢 Open |
| C13 | The ~1,400 lines of new/moved skill prose were not audited for instruction-smuggling content — the same gap A1 names in the tooling. | security | Informational | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/batch-feedback-subagent-routing` (#35) / 2026-06-23 | Hook fires on every UserPromptSubmit incl. agent/tool notifications (`hooks/batch-feedback-routing-reminder.sh`) | 🟢 Consider → Won't-Fix (intended) | "Reminder targets the model not the human; non-human submits are valid fan-out points; cost ~85 tok/firing. Broad firing preferred." | **Inherited.** Matched substantively: the audit's F5 proposed removing this hook and F6 edited the CLAUDE.md section it re-injects. F5 was declined this run on exactly this row's reasoning, and the hook cross-reference paragraph was deliberately left in place. Not re-flagged. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The staged payload root is byte-identical to before the move: the file plus six directories, no `global-instructions/` subdir | ✅ Confirmed | r1 re-ran `install.sh` to the prompt; `basename` is the identity for the other six `CLAUDE_HOME_SRC` entries, so `link-claude-home.sh:47`'s `ENTRIES=(… CLAUDE.md)` still resolves | FC claim 11 (executed, k=3 unanimous) | for-orchestrator-synthesis |
| The F8 split preserved every anchor and every moved byte | ✅ Confirmed | 54 anchor links across `SKILL.md`, the three references and both external referrers machine-resolve to real headings, 0 unresolved; moved blocks byte-identical apart from three link-depth fixes; line counts 1,909 → 1,256 / 515 / 126 / 52 exact | FC claim 12 (executed, k=3 unanimous) | for-orchestrator-synthesis |
| The F4 numeric-cap retirement is complete | ✅ Confirmed | repo-wide search (minus archive/external/runs/docs/node_modules) returns zero surviving `<300 words` / `output cap` / `#default-output-cap` references | FC claim 13 (executed, k=3 unanimous) | for-orchestrator-synthesis |
| 97/97 `test/skills/code-review-*.bats` pass; 18/18 across the five named suites | ✅ Confirmed | test-strategy executed both; `bats` exits 0, 97 ok / 0 not ok / 0 skip | test-strategy (executed) | for-orchestrator-synthesis |

Every row above rests on an `executed`-mode verdict. Critic endorsement claims routed `route: code-fact-check` are **not** represented here — see Skipped stages below.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Stage 1.5 evidence gate: no corroborating evidence in domain | No fact-check claim touches loops, queries, caching, complexity or hot paths; the only control-flow changes in the diff are a `basename` call inside a copy loop (`install.sh:51-57`) and a variable indirection in a linter script (`health-check.sh`) |

**Non-core stages also skipped, recorded so coverage limits stay auditable:**

| Stage / critic | Reason |
|---|---|
| tech-debt-triage | Its size trigger (>10 files, >500 lines) fired, but ~90% of the volume is two file moves. Orchestrator judgment, not a gate — recorded as a coverage limit. |
| Stage 2.5 (endorsement-claim verification) | Skipped by orchestrator judgment on cost, not by a documented skip condition. Consequence applied conservatively: every routed endorsement claim from security, api-consistency and architecture is treated as *pending execution verification* and none was promoted to a ✅ row. |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/self-improvement.sh:1172-1181` | security F1, api-consistency Breaking | distinct defects: both fragments describe the same defect and each states its mechanism and fix completely; security's report already names the general root ("guards that classify by basename survived; guards that classify by path silently stopped covering it") |
| 2 | `test/skills/code-review-assurance-contract.bats:118-170` | FC claim 7, test-strategy F1, test-strategy F2, api-consistency (dual `SKILL_CONTENT` definition), architecture (missing `helpers.bash` abstraction) | distinct defects: F1 is a range end-anchor, F2 is a wrong operand, and each fragment states its own one-line fix; composing would staple complete findings together, which the entailment discipline forbids |
| 3 | `devcontainer-config/install.sh:41-57` | security F3+F4, architecture (payload seam), test-strategy T3 | distinct defects: collision-nesting, missing-source tolerance and the undeclared mapping are three independent properties of the same seam, each separately stated and separately fixable |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
