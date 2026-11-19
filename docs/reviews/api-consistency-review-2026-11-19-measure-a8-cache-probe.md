Commit: f87a1455

# API Consistency Review — measure/a8-cache-probe

**Scope:** `git diff 8b06087719a4fd260cf692be9f5d485aee8535f1..HEAD` (commits 4363a15c, f87a1455; 3 docs files)
**Date:** 2026-11-19
**Based on:** `docs/reviews/code-fact-check-report-2026-11-19-measure-a8-cache-probe.md` (k=3 merged; 0 Incorrect, 0 Stale). Its Mostly-accurate items are not re-filed here.

The consumer-facing contracts reviewed: the rubric file format as `rubric_parse` (`scripts/lib/rubric-check.sh:76-199`) reads it (Status-cell first word, cell counts, tier headings); the status words and their required content (`skills/code-review/references/rubric.md:190-211`); the Rubric Status Line (`rubric.md:605-627`); the routing rule for reviews of code already on main (`rubric.md:233-240`); the run-record conventions in `runs/review-arms/a8-2026-11-19/` and the measurement-provenance convention (`docs/working/review-canon.md:112-131`); the research-doc conventions (`workflows/research-plan-implement.md:60-80` and sibling research docs).

## Baseline Conventions

- **Status words** (`rubric.md:192-206`): a Status cell starts with one word from the table, read as its first word. `Split` (🔴, 🟡) means "moved to another unit" and the cell or the Author note must carry "the tracked follow-up (Q-ID, roadmap item or branch)". `Acknowledged` (🟡, 🟢) means the row stands with a qualifying author note. `Deferred` needs an override-log row.
- **Parser** (`rubric-check.sh:65-71,113-115`): an amber closes if its Status or Author note cell holds a Q-ID, an override-log reference, a TODO, "roadmap" or a revisit trigger, whatever its first word. It checks only that a keyword is present, not that the referenced unit covers the row.
- **Status line** (`rubric.md:607-609,619-626`): the all-resolved form is `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation`, with the label appearing verbatim and only once.
- **Already-on-main routing** (`rubric.md:235-238`): "the commit that adds its rubric lands only after every open 🔴 and 🟡 row is routed: a question entry, a roadmap item or an override-log row, named in the row."
- **Run records** (`runs/review-arms/a8-2026-11-19/`): `results.md` opens by pointing to its research doc, `token-ledger.md` ("Per-agent rows") and `manifest.json` ("totals") (`results.md:3-5`). The ledger says "One row per dispatched agent, appended when its notification arrived (review-canon.md §3)" (`token-ledger.md:3-5`). The manifest keeps a `tokens` map for each cell.
- **Provenance convention** (`review-canon.md:112-131`, adopted to close **this rubric's own A6**): "any run or sub-run that reports per-agent token figures MUST (a) append one row per agent to a `token-ledger.md` in the run directory *at measurement time* … and (b) register the sub-run's agents and totals in the run's `manifest.json`". The 2026-08-18 amendment makes this "**unconditional** for orchestrated measurement runs — any run with a `runs/` manifest", and adds that "A run that nonetheless finishes with empty `tokens` maps must state the omission explicitly in its results doc."
- **Research docs**: the RPI spec asks for a four-line header (Goal / Problem framing / Project state / Task status) and a `## Files read` section that opens with `Last verified:` (`research-plan-implement.md:62-80`). In practice the repo is mixed: 12 of 30 `docs/working/research-2026-11-1*.md` docs have `## Files read`. The direct sibling `research-2026-11-19-a8-token-measurement.md` uses `Brief: … Branch: …` plus Question / What I know / Method / Design choices / Plan, and has neither the four-line header nor `## Files read`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Split — <prose> … moved to Q-308` (A8 Status cell) | status word | `Split: roadmap Now item "…"`, `Split out; known route`, `Split to the roadmap item rubric-gate-2` | `docs/reviews/code-review-rubric-*.md`; `test/scripts/build-loop-check.bats:1197` | Consistent first word. The follow-up comes at the end of a long cell rather than first, but the parser extracts Q-IDs from anywhere in the cell. |
| status line `… attestation (A8 split to Q-308 …)` | status-line form | `… attestation (after 4 passes. …)` | `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:5` | Consistent: the label is verbatim, appears once, and is followed by a parenthetical, which has precedent. |
| `runs/review-arms/a8-2026-11-19/cache-probe.md` | run-record file | `results.md`, `token-ledger.md`, `hunt-factcheck-behavioral-lie.md`, `levers-3-4-measurement.md` | `runs/review-arms/{a8-2026-11-19,baseline-2026-08-06}/` | Consistent: a lowercase kebab-case sub-run doc next to the run's results, like `levers-3-4-measurement.md`. |
| `docs/working/research-2026-11-19-a8-cache-probe.md` | research doc | `research-2026-11-19-a8-token-measurement.md`, `research-2026-11-12-host-board-answer-commit.md` | `docs/working/research-2026-11-1*.md` | Consistent naming, `research-<date>-<brief-slug>.md`, matching the brief slug. |

## Findings

#### 1. A8 closes as `Split`, but the follow-up it names does not cover the row's own subject (the SKILL text, now shown false)

**Severity:** Inconsistent
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `docs/working/research-2026-11-19-a8-cache-probe.md:72-77`; `skills/code-review/SKILL.md:274,353`
**Move:** 3 (trace the consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Row A8's finding is about the SKILL claim itself: `"Leave it on because it is free" / "0% of token count" (SKILL.md:276-278) is not established …`. The new Status cell says the claim "fails on its benefit" and ends `Net inline cost and recall effect moved to Q-308`. Q-308 (`docs/working/questions.md:166-179`, OPEN on main) asks only "Run the two larger measurements … a self-read control pass on the csp cell and a pass on the larger corpus cell?". The direct remedy for the measured result is to correct the text, which the branch leaves unfixed and unrouted. The research doc says so: "The skill still says the cache "serve[s] the shared block to all ~8 agents" and "Leave it on because it is free" (`SKILL.md:274-277`, `:352-354`); the probe shows that saving does not occur on the Agent-tool path. Correcting that text is a pipeline change the brief puts out of scope, so it is for the cycle to file." (`:74-77`). The text is still live at HEAD: `SKILL.md:274` "This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a" and `:353` "Leave it on because it is free; do not expect". `rubric.md:204` requires a Split cell to carry "the tracked follow-up (Q-ID, roadmap item or branch)". This rubric reviews main (`:4` "on `main`"), so `rubric.md:235-238` also requires every open row to be "routed … named in the row". Only part of A8 is routed. The parser reports the row as `closed` (`rubric_parse` at HEAD: `row amber A8 closed`) because Q-308 is present, so no merge-time check will catch the unrouted part. For a consumer of the rubric, the row now reads as fully disposed while the false claim it was filed against stays in the skill and appears in no tracked unit.

**Recommendation:** Before this merges, file the SKILL-text correction (a roadmap item or a Q entry; the cycle owns those files per the brief's Out of scope) and name it in A8's cell, for example `… Net inline cost and recall effect moved to Q-308; the SKILL.md:274/:353 text correction moved to <roadmap item>`. The other option is to state in the cell that the text correction is waiting on a named unit.

#### 2. The probe's per-agent token figures are recorded only as prose. They are not in the run's `token-ledger.md` or `manifest.json`, which the provenance convention that closed A6 requires

**Severity:** Inconsistent
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:34,93-94`; `runs/review-arms/a8-2026-11-19/token-ledger.md` (unchanged); `runs/review-arms/a8-2026-11-19/manifest.json` (unchanged)
**Move:** 1 / 7 (baseline conventions; asymmetry between sibling records)
**Confidence:** High
**Legibility-target:** for-author

The probe reports per-agent figures (`| Notified `subagent_tokens` | 50,685 | 50,685 |`, `:34`; "Cost of the probe: 2 × 50,685 = 101,370 tokens by the notified figure.", `:93`). It is a sub-run of a run directory that has a manifest. `review-canon.md:114-117` says such a sub-run "MUST (a) append one row per agent to a `token-ledger.md` in the run directory … and (b) register the sub-run's agents and totals in the run's `manifest.json`", and the amendment (`:125-131`) makes this unconditional for any run with a `runs/` manifest. The sibling records follow it: the ledger says "One row per dispatched agent, appended when its notification arrived (review-canon.md §3)", and `results.md:3-5` points to "Per-agent rows: `token-ledger.md`; totals: `manifest.json`". `cache-probe.md:3` names only its brief. This is the same pattern as A6 in the same rubric ("the sub-run's 8 agents / 577,971 tokens absent from `manifest.json` and `token-ledger.md`"), whose fix was this convention. The impact is smaller: the transcripts persist under `~/.claude/projects/…/subagents/` and the fact-check verified the figures (Claim 9). They still live outside the repo, so the run's ledger total (852,285) and the manifest `totals` no longer cover every agent dispatched under this run directory.

Precedent: per-agent ledger rows + manifest `tokens` map used in `runs/review-arms/a8-2026-11-19/token-ledger.md:9-21`, `runs/review-arms/a8-2026-11-19/manifest.json` (`cells.csp.tokens`).

**Recommendation:** Append two rows (probe A, probe B: 50,685 each, sub-run subtotal 101,370) under a "Cache probe" heading in `token-ledger.md`, and add a `cache_probe` entry (agents, tokens, pointer to `cache-probe.md`) to `manifest.json`. Then give `cache-probe.md:3` the sibling's "Per-agent rows / totals" pointers. The brief's doc list (criterion 4) does not name these two files, so the orchestrator must widen the scope, or the probe doc must state the omission explicitly, as the amendment allows.

#### 3. A8's Author note still states the 2026-08-07 instruction as pending

**Severity:** Minor
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35` (Author note cell)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

The Author note is unchanged: `User decision 2026-08-07: run the post-restructure measurement once code/prompt changes are fully settled`. The Status cell now says the measurement ran ("measured 2026-11-19 … the A8 pass (`runs/review-arms/a8-2026-11-19/results.md` …; merge approved Q-306)") and that the remainder moved to Q-308. The note does not contradict the Split in a way the parser sees (the parser reads Q-IDs and closure keywords, and the row reads `closed` either way). A human reader still gets two instructions in one row: "run … once settled" and "moved to Q-308". The fact-check (Claim 13, r3) flagged this as out of its scope.

**Recommendation:** Add a dated tail to the note, for example `… settled (done 2026-11-19: results.md, cache-probe.md; remainder Q-308)`. Leave the original sentence in place, since it is the owner's decision record.

#### 4. The brief's Status line is still `open`; its acceptance criterion requires `done` in the change that merges this work

**Severity:** Minor
**Location:** `docs/working/briefs/2026-11-19-a8-cache-probe.md:3,22`; `docs/working/research-2026-11-19-a8-cache-probe.md:83`
**Move:** 3 (contract between brief and branch)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`Status: open` (`:3`) against "In the change that merges this work, change this brief's status line from open to done." (`:22`). The research doc's Plan lists it as still to do: "3. Review-fix loop over the doc changes; brief Status line to done; marker." (`:83`). The brief is not in the diff (the branch does not touch it), and it also reads `Status: open` on main. This confirms the fact-check's first escalation. It is a lifecycle field consumers read, not a parser contract.

**Recommendation:** Flip it to `Status: done` in the branch's final commit, or confirm that the orchestrator's merge commit does it.

#### 5. Q-308, the unit A8 is split to, has text the probe makes stale

**Severity:** Informational
**Location:** `docs/working/questions.md:171,179`
**Move:** 3
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The Split's target still reads "the cheap cache probe (a roadmap agent item, no ask) still runs" (`:171`), but the probe has now run. Its option `**[2] After the cache fix** | Run them once the cache probe has said whether the prompt layout can be fixed, and any fix has merged` (`:179`) presumes a fix that `cache-probe.md:63-69` says no prompt order can deliver. A Split row is only as good as the unit it points at. The questions files are out of this brief's scope, so this goes to the cycle. Same as fact-check escalation 2; recorded here because it bears on whether `Split` points at a coherent unit.

**Recommendation:** The cycle restates Q-308's options and its "If you say no" line in light of the probe (outside this branch).

#### 6. The research doc follows its direct sibling, not the RPI header and `Files read` spec

**Severity:** Informational
**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:1-4` (header), whole file (no `## Files read`)
**Move:** 1
**Confidence:** High
**Legibility-target:** for-author

The doc opens `Brief: … Branch: …` / `Probe record: …` and has no Goal / Problem framing / Project state / Task status lines and no `## Files read` with `Last verified:`. Both are required by `research-plan-implement.md:62-80`. It matches its direct sibling `research-2026-11-19-a8-token-measurement.md:1-4` exactly, and 18 of 30 recent research docs also lack `## Files read`. The doc is consistent with its neighbours and not with the spec. It is flagged only so the convention is set deliberately: without `Last verified`, a later reader cannot run the freshness check against `SKILL.md:268-358`, which this doc's verdict depends on.

**Recommendation:** Optional: add a `## Files read` section (`Last verified: 2026-11-19`; SKILL.md, results.md, csp/shared-block.md, rubric.md, the rubric file).

#### 7. The correction to `results.md` §2 is recorded only in the probe doc

**Severity:** Informational
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:52-54`; `docs/working/research-2026-11-19-a8-cache-probe.md:55-57`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-author

"A small correction to `results.md` §2, which reads this path as "the end of the first user turn" …". `results.md` is not edited and has no forward pointer, so a reader who starts at the run's entry document, which is where the siblings point, keeps the uncorrected reading. The research doc acknowledges the choice: "not edited into the merged results (outside the brief's doc list)". This is a deliberate scope call. The conclusion is unchanged ("still after the tail").

**Recommendation:** When the cycle next touches the run directory, add a one-line pointer under `results.md` §2 to `cache-probe.md`.

## What Looks Good

- At HEAD, the parser reads every 🔴/🟡 row as closed and reports no `bad` lines: `R1 fixed`, `A1`–`A7` and `A9`–`A12` `fixed`, `A8 closed`. At base 8b060877 it reported `bad 30/33/34 row A3/A6/A7 has 8 cells where its header has 9` and dropped those rows. f87a1455's empty Author-note cells fix that. [unverified — submitted as claim] Location: `docs/reviews/code-review-rubric-2026-08-07-main.md:17,28-39`; probe: `rubric_parse` from `scripts/lib/rubric-check.sh` run read-only on `git show HEAD:` and `git show 8b060877:` copies.
- R1's first word is `Fixed` (`✅ Fixed (iter 1 — …`, emoji skipped), with none of the parser's negation words, so it reads as fixed. The 🔴 table's 8 columns match its header. [unverified — submitted as claim] Location: `code-review-rubric-2026-08-07-main.md:15,17`.
- The new status line uses the all-resolved template verbatim, carries the single-sample label once, and adds only a parenthetical, which has precedent. It is justified: no 🔴/🟡 row is open by the Status-words table or by the parser. [unverified — submitted as claim] Location: `code-review-rubric-2026-08-07-main.md:4`; `rubric.md:609,619-624`; precedent `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:5`.
- `Split` is the right word among the three candidates for the part of A8 it describes. `Deferred` would need an override-log row (`rubric.md:202`), which this row does not have and does not describe. `Acknowledged` would mean the finding "stands", but the measured part is settled and the unmeasured part is a separate unit. The cell carries the Q-ID that `Split` requires (Q-308, OPEN on main). Finding 1 is about what Q-308 does not cover, not about the word. [unverified — submitted as claim] Location: `code-review-rubric-2026-08-07-main.md:35`; `rubric.md:201-204`; `git show main:docs/working/questions.md` Q-308.
- "Review of code already on main" is met for the part of A8 the cell routes (Q-308 is named in the row). It is not fully met for the SKILL text (Finding 1). [unverified — submitted as claim] Location: `rubric.md:235-238`; `code-review-rubric-2026-08-07-main.md:35`.
- The new file names follow sibling conventions (see the audit). [unverified — submitted as claim] Location: `runs/review-arms/a8-2026-11-19/`, `docs/working/`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A8 Split names Q-308 (net cost and recall) but not the correction of the SKILL text the row is about, now shown false | Inconsistent | `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `skills/code-review/SKILL.md:274,353` | High |
| 2 | Probe tokens (2 × 50,685) missing from `token-ledger.md` and `manifest.json`, against the provenance convention that closed A6 | Inconsistent | `runs/review-arms/a8-2026-11-19/cache-probe.md:34,93` | High |
| 3 | A8 Author note still reads as a pending instruction | Minor | `code-review-rubric-2026-08-07-main.md:35` | High |
| 4 | Brief `Status: open` not flipped to done | Minor | `docs/working/briefs/2026-11-19-a8-cache-probe.md:3,22` | High |
| 5 | Q-308 (the Split target) text made stale by the probe | Informational | `docs/working/questions.md:171,179` | High |
| 6 | Research doc lacks the RPI header and `Files read`; matches its sibling | Informational | `docs/working/research-2026-11-19-a8-cache-probe.md:1-4` | High |
| 7 | `results.md` §2 correction not cross-linked from `results.md` | Informational | `runs/review-arms/a8-2026-11-19/cache-probe.md:52-54` | Medium |

## Overall Assessment

On the machine-read surface the branch conforms. Every Status cell parses to a closing first word, f87a1455 fixes the cell-count defect that had hidden A3, A6 and A7 from the parser, and the status line is the template's all-resolved form, justified row by row. The gaps are in what the closure points at, which the parser cannot check. First, A8 is split to a question that covers only the follow-up measurements, while the skill text the row was filed against, now measured false, is routed nowhere (Finding 1). Second, the probe repeats on a small scale the record-keeping gap that this rubric's own A6 was closed for, with figures only in prose and none in the ledger or manifest (Finding 2). Both can be fixed in place with one routing line and two ledger/manifest entries. Finding 1's routing entry belongs to the cycle (roadmap and questions files are outside the brief), so it is an orchestrator call before merge. No existing parser consumer breaks.

## Goal-Alignment Note

- **Success criterion (verbatim):** "an api-consistency-reviewer report saved at the output path below, structured per the api-consistency-reviewer skill."
- **Answered:** `Split` vs `Acknowledged`/`Deferred` (Split is correct for the routed part, and its required Q-ID is present; What Looks Good, Finding 1). Status-line conformance, plus each 🔴/🟡 row's first word, with the parser run read-only (all closed at HEAD, R1 included). Author-note conflict (Finding 3: no parser conflict, human-reading drift). Already-on-main routing (met for Q-308's part, not for the SKILL text: Finding 1). Sibling run-record conventions and provenance (Finding 2: the 101,370 tokens should be in the ledger and manifest). Brief Status line (Finding 4: not done). Research-doc conventions (Finding 6).
- **Out of scope:** whether the probe's technical conclusions hold (the fact-check's domain, Claims 9–11 Verified); the content of the SKILL text correction; editing the questions, roadmap or brief files.
- **Escalate:** (a) Finding 1: the cycle should file the SKILL.md:274/:353 correction as a roadmap item or Q entry and A8's cell should name it before merge; addressee orchestrator. (b) Finding 2: the brief's doc list excludes `token-ledger.md`/`manifest.json`; the orchestrator should widen it or accept an explicit omission note. (c) Finding 5 / fact-check escalation 2: restate Q-308.
- **Decisions:** none made; all findings are recommendations.
