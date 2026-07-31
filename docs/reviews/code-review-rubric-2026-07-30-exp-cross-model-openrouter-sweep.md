# Code Review Rubric

**Scope:** exp/cross-model-openrouter-sweep vs main (13 files, +2375/−20) | **Reviewed:** 2026-07-30 | **Status: 🟡 CONDITIONAL PASS** — 3 amber item(s) carrying author notes awaiting user endorsement

Commit reviewed: e9d05ea · fixes applied in-loop on top (this file reflects post-fix statuses)
Pipeline: Stage 1 k=3 fact-check (first live run of the mechanism this branch ships) → 4 critics (security, performance, api-consistency on opus + tech-debt-triage advisory) → synthesis.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | "fact-check Incorrect is the pipeline's *only* 🔴-promotion channel" contradicted by the Unified Severity Mapping (5 🔴 sources) and §1.0's own two-channel wording; propagated to 5 sites incl. upstream state doc | Fact-check (M2) | Incorrect (High) — replicate split r1=Incorrect/r2=Verified/r3=Mostly accurate, merged most-severe-wins | `skills/code-review/SKILL.md:27,264,1142` · `docs/decisions/log.md` row · bats header · state doc §1.1 | for-author | — | ✅ Fixed (reworded at all 5 sites: "one of two verdict-driven blocking channels; the only one reachable by documentation-class findings") |
| R2 | Kimi runner-up misattributed as "doc-order status quo"; artifact banner says runner-up [2] measurement-first | Fact-check (M16) | Incorrect (High) | `runs/dd-cross-model-2026-07-30/README.md:40` | for-author | — | ✅ Fixed |
| R3 | "~9× Sol's latency" — actual 6.2×; ~9× matches the Gemini ratio (8.5×) | Fact-check (M17) | Incorrect (High, unanimous 3/3) | `runs/dd-cross-model-2026-07-30/README.md:48-49` | for-author | — | ✅ Fixed (now "~6× Sol's (and ~8.5× Gemini's)") |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Confirmed-Good cross-check globs git-tracked `code-fact-check-report-r*.md` with no run-scoping → fresh worktrees read prior branches' replicates as this run's (decision-25 failure class) | Security | Medium | security-reviewer #1 | for-author | — | ✅ Fixed | Stale-replicate guard added to Stage 1 dispatch (delete non-HEAD-Commit replicates); all consumers must match by `Commit:` line, never glob alone |
| A2 | k=3 unconditional ⇒ SI loop's unattended headless reviews spawn 3 write-capable `acceptEdits` agents per task per round; no cap/ceiling/back-off | Security | Medium | security-reviewer #2 | for-author | — | 🟡 Open — author note | Accepted cost, decision-recorded (log row 27); the ≥90%-agreement falsifier is the designed opt-down path. Revisit if SI-loop spend or archive volume becomes a problem before the falsifier trips |
| A3 | Orchestrator holds 4 fact-check reports in context Stage 1→3 with no release point; merge input uncapped; semantic clustering is new serial O(k·n²) work on the blocking path | Performance | High | performance-reviewer #1 | for-author | — | ✅ Mitigated | Observation index now built once during the merge; Stage 3 consults the index, not 4 re-reads. Residual: merge-input size still uncapped — revisit if a >200-claim diff hits it |
| A4 | Stage-1 agent spend and per-agent read work triple | Performance | Medium | performance-reviewer #2 | for-author | — | 🟡 Open — author note | Deliberate and decision-recorded; flagged so it stays a number, not a footnote. First k=3 run (this one) is the baseline datum |
| A5 | Confirmed-Good cross-check grows N×1 → N×4 report passes (~30 re-scans/run at measured ✅ density) | Performance | Medium | performance-reviewer #3 | for-author | — | ✅ Fixed | Shares fix with A3 (observation index) |
| A6 | Merge ladder's composite tokens (`Incorrect (high confidence)`) written into `**Verdict:**` would silently fail the format gate's 5-value enum | API consistency | Inconsistent | api-consistency F1 | for-author | — | ✅ Fixed | Spec now: plain enum in `**Verdict:**`; ladder tokens are ordering vocabulary only |
| A7 | `Replicate verdicts:` unbolded / outside the closed five-field schema consumers parse | API consistency | Inconsistent | api-consistency F2 | for-author | — | ✅ Fixed | Now a bolded sixth field; merged report keeps full standard schema so the format bats gates it instead of skipping |
| A8 | Degraded-run marker `k=2 (…)` an unnamed prose token | API consistency | Inconsistent | api-consistency F4 | for-author | — | ✅ Fixed | New bolded `**Replication:**` header field |
| A9 | Executed Stage-3 cross-check text still read "the fact-check report" (singular), reopening the single-replicate-observation gap; stale-wording test protected it | API consistency | Inconsistent | api-consistency F6 (escalated) | for-author | — | ✅ Fixed | Both cross-check sites now name merged + Commit-matched replicate reports |
| A10 | State doc "implemented **exactly** as shaped" — clustering key deliberately deviates | Fact-check (M7) | Mostly accurate (High) | fact-check merged | for-author | — | ✅ Fixed | Deviation now stated in §1.1 status |
| A11 | README "Per §5.2 discipline" mis-attributes its own extension | Fact-check (M22) | Mostly accurate (Medium, single-replicate) | fact-check merged | for-author | — | ✅ Fixed | Now "Extending §5.2's detection-not-tier discipline" |
| A12 | **This run's own merged report** is in cluster-table form, predating the A6/A7 schema spec — the format gate skips it silently ("Report has no claims") | API consistency (self-identified at synthesis) | Inconsistent | orchestrator | for-author | — | 🟡 Deferred — author note | The three replicate reports carry full schema-compliant detail for this run; the merged-schema spec applies from the next run. Regenerating this run's merged artifact would re-do the collation for no reviewer benefit |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Merge step waives "MUST NOT write fact-checks yourself" by assertion; merged file has no provenance invariant | security-reviewer #3 | Low | for-author | — | 🟢 Open |
| C2 | ~750 lines of third-party model output + 1004-line directive-shaped prompt committed with no untrusted-content marker (precedent risk) | security-reviewer #4 | Low | for-author | — | 🟢 Open |
| C3 | SI-loop gate reads only `CODE_REVIEW_RED`; a k=2-degraded run is invisible to it (`**Replication:**` field now exists but nothing consumes it) | security-reviewer #5 | Low | for-author | — | 🟢 Open |
| C4 | No retention rule for 3× verbatim-quoting artifacts in tracked dir | security-reviewer #6 | Informational | for-author | — | 🟢 Open |
| C5 | k=3 hardens 1 of 5 🔴 channels; critic channels stay single-sample while `## Verdict stability` reads as pipeline-wide assurance | security-reviewer #7 | Informational | for-orchestrator-synthesis | — | 🟢 Open (matches sweep's own §1.2/vendor follow-ups) |
| C6 | No adaptive-k path; the sweep runner-up proposal (scope replication to promotion-candidate claims) unimplemented and unrecorded as follow-up | performance-reviewer #4 | Low | for-author | — | 🟢 Open |
| C7 | Three simultaneous identical prompts can't share prompt cache — recorded as **not actionable** (do not "fix" by serialising) | performance-reviewer #5 | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix (by design) |
| C8 | bats suite re-reads/re-seds the skill per test | performance-reviewer #6 | Informational | for-author | — | 🟢 Won't-Fix (conventional pattern, fast category) |
| C9 | `-r<N>` suffix collides with "review round" naming in flat docs/reviews/ | api-consistency F3 | Minor | for-author | — | 🟢 Open |
| C10 | Stage-1 banner stuffs k into `<stage-name>`; k=2 path wording now aligned via `**Replication:**` field but banner slot still unparameterized | api-consistency F5 | Minor | for-author | — | 🟢 Open |
| C11 | `## Verdict stability` sentence-case vs Title-Case precedent; defined outside the report schema doc | api-consistency F7 | Minor | for-author | — | 🟢 Open (schema home: candidate one-section addition to code-fact-check SKILL.md) |
| C12 | Severity ladder lacked `Incorrect (low confidence)` rank | api-consistency F8 | Minor | for-author | — | ✅ Fixed |
| C13 | Test filename spells `factcheck` unhyphenated | api-consistency F11 | Minor | for-author | — | 🟢 Won't-Fix (rename churn > benefit) |
| C14 | Mandatory Rules 1/5 not amended for merge/k=2; agent-count wording hardcodes 3; pasted skill text carries competing output path | api-consistency F9/F10/F12 | Informational | for-author | — | 🟢 Open |
| C15 | Duplicate decision-log row ID 26 (main's Rust row + this branch's) — 3 artifacts cited the ambiguous ID; no gate checks ID uniqueness | tech-debt-triage #7 | Medium (advisory tier per contextual-critic rule) | for-author | — | ✅ Fixed (renumbered 27 + all citations updated) |
| C16 | k literal hardcoded across ~18 sites while the branch schedules its own k→2 change | tech-debt-triage #1 | Medium (advisory) | for-author | — | 🟢 Open |
| C17 | k=3 rationale copy-pasted into 5 artifacts, no canonical source — and it drifted (this run's R1 is the proof) | tech-debt-triage #2 | Medium (advisory) | for-author | — | 🟢 Partially addressed (all 5 sites now consistent; canonicalization still open) |
| C18 | log.md rows outgrown the log format (4,014-char rows with subsections — the file's own promotion trigger) | tech-debt-triage #3 | Medium (advisory) | for-author | — | 🟢 Open |
| C19 | Contract-test gaps: near-vacuous regex in test 2; nothing asserts the k restatements outside Stage 1 agree | tech-debt-triage #4 | Low (advisory) | for-author | — | 🟢 Open |
| C20 | DD-sweep harness not committed (`run_dd_sweep.py` lived in job tmp); README table hand-transcribed — which is where R2/R3 arose | tech-debt-triage #5 | Low (advisory) | for-author | — | ✅ Fixed (`scripts/dd-cross-model-sweep.py`, with a generate-don't-transcribe note for future sweeps) |
| C21 | State-doc §1 status markers use 3 different "done" conventions; `Relevant paths` lacks the sweep dir | tech-debt-triage #6 | Low (advisory) | for-author | — | 🟢 Partially fixed (sweep dir + runner added to Relevant paths; marker unification still open) |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (Log's nearest row — 2026-06-23, `hooks/batch-feedback-routing-reminder.sh` — shares no location, category, or claim with this diff.)

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Most-severe-wins is fail-closed and correctly justified against the observed under-calling failure mode | ✅ Confirmed | `skills/code-review/SKILL.md:336-341` — "take the **most severe verdict** any replicate assigned … the observed failure mode is under-calling, not over-calling" | security-reviewer | for-orchestrator-synthesis |
| Replicate independence designed in and enforced | ✅ Confirmed | `SKILL.md:316-317` — "all three replicates in a single message so they run in parallel and cannot see each other's output"; output path pinned as only prompt variance, asserted by `code-review-factcheck-replication.bats` test 2 | security-reviewer + api-consistency | for-orchestrator-synthesis |
| Canonical report path preserved — no existing consumer rebinds | ✅ Confirmed | `test/skills/code-fact-check-format.bats:11` — `load_report "docs/reviews/code-fact-check-report.md"` still resolves; enumeration: api-consistency grepped consumers of the old contract, 0 Breaking | api-consistency | for-orchestrator-synthesis |
| Sweep README numeric table matches the meta.json artifacts (latencies, tokens, costs, survivors, confidences) | ✅ Confirmed | Enumeration: all three fact-check replicates independently compared every cell against `runs/dd-cross-model-2026-07-30/*.meta.json` and the run outputs (M13, unanimous Verified High); $1.21 total re-computed | fact-check k=3 | for-orchestrator-synthesis |
| No secrets/credentials in committed run artifacts | ✅ Confirmed | Enumeration: security-reviewer scanned `runs/**` incl. `.meta.json` fields (model ID, tokens, cost, latency only) and injection-shaped content — clean | security-reviewer | for-orchestrator-synthesis |

Cross-check: each row re-checked against the merged fact-check report and all three replicate reports (this run's Commit: e9d05ea); no observation in any report contradicts these five rows. (M16/M17's README errors are in prose-interpretation cells, outside row 4's numeric-table scope.)

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (Load-bearing citations — the five R1 sites, log.md rows 41/48, format-bats:11 binding, the singular cross-check text, the format-gate skip behavior — were re-verified directly by the orchestrator during the fix pass; remaining Evidence blocks spot-checked against their cited lines.)

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (Stage 1.5 evaluated: security kept — shell test + trust-relevant orchestration text; performance kept — code change + process-economics surface; api-consistency kept — published contract changes.)

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
Post-fix state: 3/3 🔴 Fixed · 9/12 🟡 Fixed, 3 carrying author notes (A2, A4, A12) · re-verified by 59/59 bats.
