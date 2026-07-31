# API Consistency Review — exp/cross-model-openrouter-sweep

Commit: e9d05ea

**Scope:** `git diff main...HEAD` (13 files, +2375/−20) — `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `docs/decisions/log.md`, `docs/thoughts/code-review-evaluation-state.md`, `runs/dd-cross-model-2026-07-30/**`
**Date:** 2026-07-30
**Based on:** Stage 1 merged code-fact-check report (k=3, most-severe-wins) supplied by the orchestrator — its findings are taken as given and not re-verified here.

The consumer-facing surface under review is not HTTP or SDK: it is the **artifact contract** between `code-review` (orchestrator), `code-fact-check` (producer), the bats format gates (automated consumers), and `scripts/self-improvement.sh` (archival consumer). Report file paths, per-claim field names, verdict enums, report section headings, and status-banner formats are the API.

---

## Baseline Conventions

Surveyed `skills/code-fact-check/SKILL.md` (report schema), `skills/code-review/SKILL.md` (unchanged sections), `test/skills/code-fact-check-format.bats` + `test/skills/helpers.bash` (the automated gate), `test/skills/code-review-assurance-contract.bats`, `test/skills/code-review-format-contract.bats`, `docs/reviews/*.md` (existing artifact names), `scripts/self-improvement.sh:1419-1435`, and `runs/cross-model/**` (prior run-data layout).

1. **Report artifacts** live at `docs/reviews/<skill-name>-report.md` or `docs/reviews/<critic-name>-review.md`, one per producing skill. Round/iteration variants use an `-r<N>-<topic>` infix: `code-review-r1-observability.md`, `code-review-r2-convergence.md`, `draft-review-r1-pivot-guidance.md`. **`r<N>` in `docs/reviews/` means *round*.**
2. **Per-claim/per-finding fields are bold-delimited and enumerated.** `skills/code-fact-check/SKILL.md:219`: "downstream consumers (orchestrators, tests, rubrics) parse them by exact name and bold formatting"; `:276` fixes the mandatory set at exactly five (`**Location:**`, `**Type:**`, `**Verdict:**`, `**Confidence:**`, `**Evidence:**`).
3. **Enum values are closed and single-token.** `Verdict` ∈ {Verified, Mostly accurate, Stale, Incorrect, Unverifiable} (`:281`); `Confidence` ∈ {High, Medium, Low} (`:284`). Verdict and confidence are *separate orthogonal fields*, never composed into one token. `test/skills/code-fact-check-format.bats:90` enforces the verdict enum with an anchored `^(...)$` match.
4. **Report section headings are Title Case:** `## Claims Requiring Attention` (`code-fact-check/SKILL.md:305`), `## Confirmed Good`, `## Unverified Findings`, `## Skipped Core Critics` (`code-review/SKILL.md:836,848,863`).
5. **Status banners follow one declared template**, `skills/code-review/SKILL.md:226`: `Stage N (<stage-name>) complete: <key counts> — <next action>`, with per-slot rules in the bullets that follow.
6. **Test filenames spell the skill name exactly as the skill directory does:** `test/skills/code-fact-check-format.bats`, `code-fact-check-eval.bats`, `code-fact-check-edge-cases.bats`, `code-review-format-contract.bats`.
7. **Run data** lives under `runs/<family>/<cell-slug>/` with machine-readable payloads (`findings.jsonl`, `overlap.json`) — see `scripts/cross-model-review.py:29`.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `docs/reviews/code-fact-check-report-r<N>.md` | artifact path | `code-fact-check-report.md`, `code-review-r1-observability.md`, `draft-review-r1-pivot-guidance.md` | `docs/reviews/*.md` | Inconsistent — `-r<N>` already denotes *review round* in this directory; reusing it for *replicate* overloads the token in a flat archive (F3) |
| `Replicate verdicts: r1=… · r2=… · r3=…` | per-claim field | `**Location:**`, `**Verdict:**`, `**Confidence:**`, `**Evidence:**` | `skills/code-fact-check/SKILL.md:219,276` | Inconsistent — unbolded, and outside the enumerated mandatory five (F2) |
| `Incorrect (high confidence)` / `Incorrect (medium confidence)` | verdict token | `Incorrect` + `**Confidence:** High` | `skills/code-fact-check/SKILL.md:281,284`; `test/skills/code-fact-check-format.bats:90` | Inconsistent — composes two orthogonal enum fields into one token the format gate rejects (F1) |
| `single-replicate detection` | claim flag | `Severity: Contested`, `Source: Confirmed-Good cross-check` | `skills/code-review/SKILL.md:794-804` | Inconsistent — no field name, no bold, no defined position (folded into F2) |
| `k=2 (one replicate failed)` | report header field | `**Total claims checked:**`, `**Summary:**`, `**Scope:**` | `skills/code-fact-check/SKILL.md:225-229` | Inconsistent — an unnamed, unbolded header token in a header whose fields are exhaustively enumerated (F4) |
| `## Verdict stability` | report section | `## Claims Requiring Attention`, `## Confirmed Good`, `## Skipped Core Critics` | `skills/code-fact-check/SKILL.md:305`; `skills/code-review/SKILL.md:836,863` | Inconsistent — sentence case against Title-Case section precedent; also defined outside the report's own schema doc (F7) |
| `Stage 1 (fact-check, k=3) complete:` | status banner | `Stage 2 (critics) complete:`; format spec `Stage N (<stage-name>) complete:` | `skills/code-review/SKILL.md:226,248` | Inconsistent — a parameter is stuffed into the `<stage-name>` slot the spec does not parameterize (F5) |
| `### Stage 1: Code Fact-Check (k=3 replicated)` | section heading | `### Stage 2: Critic Agents`, `### Stage 1.5: Critic gating`, `### Fact-Check Gate` | `skills/code-review/SKILL.md:362,468` | Acceptable — stage headings already mix forms; the parenthetical is additive and is what the new test anchors on |
| `test/skills/code-review-factcheck-replication.bats` | test file | `code-fact-check-format.bats`, `code-fact-check-eval.bats`, `code-review-format-contract.bats` | `test/skills/*.bats` | Inconsistent — `factcheck` unhyphenated; every other reference in the repo spells it `fact-check` (F11) |
| `runs/dd-cross-model-2026-07-30/` | run-data dir | `runs/cross-model/gt-8ef9d52/`, `runs/cross-model/nd2/` | `runs/cross-model/**`; `scripts/cross-model-review.py:29` | New category — date-stamped, human-readable arm; documented in its own README. Note the convention being set |
| `<provider>_<model>.md` + `<provider>_<model>.meta.json` | run-data file | `findings.jsonl`, `overlap.json` | `runs/cross-model/*/` | New category — first prose-arm layout; the `_`-for-`/` substitution is applied uniformly across all four arms |

---

## Findings

#### F1 — Merge severity ladder invents a composite verdict token the format gate rejects

**Severity:** Inconsistent
**Location:** `skills/code-review/SKILL.md:323-325`
**Move:** #2 (naming against the grain), #3 (consumer contract)
**Confidence:** High

Precedent: `Verdict` ∈ `Verified | Mostly accurate | Stale | Incorrect | Unverifiable` with `Confidence` as a separate `High | Medium | Low` field, used in `skills/code-fact-check/SKILL.md:281,284` and enforced in `test/skills/code-fact-check-format.bats:90`.

The merge step defines its ordering in composite tokens:

```
2. **Take the most severe verdict any replicate assigned** to the cluster. Severity order,
   most severe first: `Incorrect (high confidence)` > `Incorrect (medium confidence)` >
   `Stale` > `Mostly Accurate` > `Unverifiable` > `Verified`.
```

The orchestrator now authors `docs/reviews/code-fact-check-report.md` (`:314`), which is the exact path the format gate loads (`test/skills/code-fact-check-format.bats:11`). That gate asserts `assert_field_values "Verdict" "Verified|Mostly accurate|Stale|Incorrect|Unverifiable"`, and `assert_field_values` anchors with `^(...)$` (`test/skills/helpers.bash:141`) — so a merged claim written as `**Verdict:** Incorrect (high confidence)` fails, silently, in a suite nothing on this branch runs against a produced report. Nowhere does the merge step say which vocabulary the `**Verdict:**` line or the `r1=<verdict>` slots draw from, so the ladder's own tokens are the most likely thing an orchestrator will copy. Casing compounds it: the ladder writes `Mostly Accurate`, the schema writes `Mostly accurate` (the gate is case-insensitive, but `## Claims Requiring Attention` subsection matching in the same file is not uniformly so).

**Recommendation:** State that the merged report keeps `**Verdict:**` and `**Confidence:**` as the schema's separate fields, and reword the ladder as a two-key sort ("`Incorrect` outranks `Stale`; within `Incorrect`, `High` outranks `Medium` outranks `Low`"). Match the schema's `Mostly accurate` casing.

#### F2 — New per-claim field `Replicate verdicts:` breaks the bold-field parsing contract

**Severity:** Inconsistent
**Location:** `skills/code-review/SKILL.md:330-333`
**Move:** #2 (naming), #3 (consumer contract)
**Confidence:** High

Precedent: `**Location:** / **Type:** / **Verdict:** / **Confidence:** / **Evidence:**` bold-delimited per-claim fields, `skills/code-fact-check/SKILL.md:219,276`.

The schema is explicit that consumers "parse them by exact name and bold formatting" (`:219`) and that "the five fields ... are mandatory" (`:276`) — a closed set. The new instruction adds a sixth field in a different style:

```
3. **Record per-replicate verdicts on every merged claim.** Each claim in the merged report
   carries a `Replicate verdicts: r1=<verdict> · r2=<verdict> · r3=<verdict>` line (`—` for
   a replicate that did not surface the claim; a claim surfaced by only one replicate keeps
   that replicate's verdict and is flagged `single-replicate detection`).
```

Unbolded, so no existing parser (`assert_field_per_claim`, which greps `^\*\*<field>:\*\*`) can see it; the `single-replicate detection` flag has no field name or position at all; and `skills/code-fact-check/SKILL.md` — the schema doc every replicate is pasted verbatim (`skills/code-review/SKILL.md:274-276`) — was not updated, so the producing skill and the consuming orchestrator now disagree on the claim shape. The new bats suite asserts only that the *instruction string* exists in `SKILL.md` (`code-review-factcheck-replication.bats:74`), never that a produced report carries it.

**Recommendation:** Write it as `**Replicate verdicts:**` and `**Detection:** single-replicate`, add both (optional-when-standalone) to `skills/code-fact-check/SKILL.md`'s required-structure rules, and add a matching optional-field assertion to `code-fact-check-format.bats`.

#### F3 — `-r<N>` suffix collides with the established "review round" meaning in `docs/reviews/`

**Severity:** Minor
**Location:** `skills/code-review/SKILL.md:278-280`, `:1066-1068`
**Move:** #2 (naming against the grain)
**Confidence:** High

Precedent: `-r<N>-<topic>` = review *round*, used in `docs/reviews/code-review-r1-observability.md`, `code-review-r2-convergence.md`, `code-review-r3-hypothesis-tracking.md`, `draft-review-r1-pivot-guidance.md`.

```
4. Instruct the agent to save its report as `docs/reviews/code-fact-check-report-r<N>.md`
   (N = 1, 2, 3).
```

`docs/reviews/` is flat and `scripts/self-improvement.sh:1431` archives it flat (`cp -f "$WT_DIR"/docs/reviews/*.md "$CR_ARCHIVE/"`), so `code-fact-check-report-r1.md` sits beside `code-review-r1-observability.md` in the same archive with `r1` meaning two different things. A reader (or a future glob) cannot tell a replicate from a round by name. Note the `r*` glob at `:938` is already load-bearing for the Confirmed-Good cross-check.

**Recommendation:** Rename to `code-fact-check-report-replicate<N>.md` (or `-k<N>`), and update `:938`, `:1066-1068`, and `code-review-factcheck-replication.bats:51,56,98` together. Cheap now, expensive after archives accumulate.

#### F4 — Degraded-run marker `k=2 (one replicate failed)` is an unnamed field in a closed header

**Severity:** Inconsistent
**Location:** `skills/code-review/SKILL.md:306-310`
**Move:** #2 (naming), #8 (nullability/optionality contract)
**Confidence:** High

Precedent: header fields `**Repository:** / **Scope:** / **Checked:** / **Total claims checked:** / **Summary:**`, each "once in the header, on its own line, with the bold delimiters shown" — `skills/code-fact-check/SKILL.md:225-229,277`.

```
tell the user and ask how to proceed; if two returned, proceed but record `k=2 (one
replicate failed)` in the merged report header and the Stage 1 banner.
```

The token has no field name, no bold delimiters, and no position within an exhaustively specified header. Worse, `k` is the *only* signal distinguishing a full-confidence merge from a degraded two-sample one — the single most consumer-relevant piece of metadata the new pipeline produces — and it is optional-when-3, present-when-2, so a consumer cannot distinguish "k=3" from "author forgot the marker". The `## Verdict stability` section (`:334`) reports cluster counts but is not stated to carry `k` either.

**Recommendation:** Make it a first-class always-present header field — `**Replicates:** 3` / `**Replicates:** 2 (r2 failed)` — register it in `skills/code-fact-check/SKILL.md`'s header list as orchestrator-only, and assert its presence in the replication bats suite.

#### F5 — Stage 1 banner parameterizes the `<stage-name>` slot the format spec does not

**Severity:** Minor
**Location:** `skills/code-review/SKILL.md:246,252,347` vs. spec at `:226`
**Move:** #2 (naming), #7 (asymmetry)
**Confidence:** High

Precedent: `**Format:** \`Stage N (<stage-name>) complete: <key counts> — <next action>\`` at `skills/code-review/SKILL.md:226`, with `Stage 2 (critics) complete: …` as the sibling instance.

```
> Stage 1 (fact-check, k=3) complete: 3 Incorrect findings, 1 Stale, verdict agreement 10/12 clusters — launching 4 critics in parallel …
```

`k=3` is a run parameter, not part of the stage's name, and the spec's bullets say `<key counts>` is where run quantities belong — which is also where `verdict agreement 10/12 clusters` correctly went. Consumers that pattern-match the banner (humans scanning logs, and the Stage-2 spec's `dispatch mode:` convention which puts its parameter inside `<key counts>`) now see two different placement rules for the same kind of data. The literal `k=3` in the template also contradicts `:309-310`, which requires the banner to say `k=2` on a degraded run — the template offers no slot for that.

**Recommendation:** Either move `k` into `<key counts>` (`Stage 1 (fact-check) complete: k=3, 3 Incorrect …`), or extend the format spec at `:226` to `Stage N (<stage-name>[, k=<k>]) complete: …` and add a bullet defining the optional parameter. Pick one and make the k=2 path fall out of it.

#### F6 — Two surviving singular references to "the fact-check report" contradict the updated cross-check contract

**Severity:** Inconsistent
**Location:** `skills/code-review/SKILL.md:616`, `:1167`
**Move:** #3 (consumer contract — documentation/test drift)
**Confidence:** High

The rule was updated in one place (`:936-938`):

```
**4. Cross-check every ✅ row against the fact-check reports (Stage 3, before publishing).**
For each candidate ✅ row, re-read the merged fact-check report **and each per-replicate
report** (`code-fact-check-report-r*.md` …
```

but the same contract is restated twice more and both still say the singular thing:

```
616: observation anywhere in the fact-check report inconsistent with it.
1167:  one instance; and every row is cross-checked against the fact-check report before
```

Line 616 is the *procedural* statement inside Stage 3 (the one an orchestrator actually executes step-by-step); line 1167 is the Important-Reminders restatement. Both instruct scanning only the merged report — which by construction drops observations a losing replicate recorded, precisely the gap decision 26 exists to close. Enforcement is asymmetric too: `code-review-factcheck-replication.bats:98` pins the updated sentence, while `code-review-assurance-contract.bats:85` greps `fact-check report` (singular), so the stale wording is *protected* by a test.

**Recommendation:** Update `:616` and `:1167` to "the merged fact-check report and each per-replicate report", and widen the `code-review-assurance-contract.bats:85` pattern to `fact-check reports?` so both phrasings are covered.

#### F7 — `## Verdict stability` deviates from Title-Case section naming and lives outside the report's schema

**Severity:** Minor
**Location:** `skills/code-review/SKILL.md:334`
**Move:** #2 (naming against the grain)
**Confidence:** Medium

Precedent: `## Claims Requiring Attention` (`skills/code-fact-check/SKILL.md:305`), `## Confirmed Good`, `## Unverified Findings`, `## Skipped Core Critics` (`skills/code-review/SKILL.md:836,848,863`) — every report-section heading in both skills is Title Case.

`## Verdict stability` is sentence case. Separately, it is the only structural section of `code-fact-check-report.md` defined outside `skills/code-fact-check/SKILL.md`, so the schema doc a reader consults to understand the report's shape does not mention it, and the format gate does not know it exists.

**Recommendation:** Rename to `## Verdict Stability` and add it to `skills/code-fact-check/SKILL.md`'s structure rules as an orchestrator-only trailing section, so one document still describes the whole report.

#### F8 — Severity ladder is undefined for `Incorrect` at Low confidence

**Severity:** Minor
**Location:** `skills/code-review/SKILL.md:323-325`
**Move:** #3 (consumer contract), #8 (nullability/completeness)
**Confidence:** High

`Confidence` is a three-value enum — "must be exactly one of: High, Medium, Low" (`skills/code-fact-check/SKILL.md:284`) — but the ladder ranks only `Incorrect (high confidence)` and `Incorrect (medium confidence)`. A cluster whose only `Incorrect` verdict came at Low confidence has no defined rank against `Stale`, so the merge outcome is orchestrator-dependent on exactly the class of claim where replicates are likeliest to disagree. The Fact-Check Gate at `:351` blocks only on high-confidence Incorrect, so the practical stakes are the merged report's ordering and the Stage-1.5 critic-gating signal rather than the 🔴 gate — but the ambiguity is silent either way.

**Recommendation:** Extend the ladder to `Incorrect (low confidence)` explicitly, or restate it as the two-key sort proposed in F1 so all nine verdict×confidence combinations rank deterministically.

#### F9 — Mandatory Execution Rules 1 and 5 were not amended for the orchestrator-authored merged report

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:59-62`, `:73-74` vs. `:314-317`
**Move:** #3 (consumer contract)
**Confidence:** High

Rule 1 reads "You MUST NOT write fact-checks or critiques yourself... If you find yourself writing analytical observations about the code, STOP". Rule 5 reads "If a sub-agent fails or returns empty, note this honestly... Do not fill in the gap yourself." The merge step asserts the carve-out from the other side ("mechanical collation, not analysis... Mandatory Execution Rule 1 still stands", `:315-317`) but the rules' own text — declared "absolute" at `:57` — was not updated, and the k=2 path at `:309-310` *is* a documented way to proceed with a failed sub-agent. Two absolute rules and their exception are stated 250 lines apart, in opposite directions.

**Recommendation:** Add one clause to Rule 1 ("…except the mechanical merge of replicate fact-check reports, which adds no claims or evidence") and one to Rule 5 naming the k=2 degraded path, so the rules are readable without the Stage 1 body.

#### F10 — Agent-count wording hardcodes 3 and is contradicted by the documented k=2 path

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:214`
**Move:** #7 (asymmetry)
**Confidence:** Medium

```
- Total agent count (3 fact-check replicates + N critics)
```

This is announced *before* launch, so 3 is correct as a plan — but the same document treats "2 returned" as a normal outcome (`:309-310`) without saying the announced count is a launch count rather than a completion count. Downstream the user sees "3 replicates" announced and `k=2` in the banner with no bridging statement.

**Recommendation:** Word it as "3 fact-check replicates launched (k may drop to 2 if one fails) + N critics", or leave as-is and rely on the F4 `**Replicates:**` header field to reconcile.

#### F11 — Test filename spells the skill `factcheck`, unhyphenated

**Severity:** Minor
**Location:** `test/skills/code-review-factcheck-replication.bats:1`
**Move:** #2 (naming against the grain)
**Confidence:** High

Precedent: `fact-check` hyphenated everywhere — `test/skills/code-fact-check-format.bats`, `code-fact-check-eval.bats`, `code-fact-check-edge-cases.bats`, `test/skills/code-fact-check/`, `skills/code-fact-check/`, and the file's own body ("k=3 fact-check replication contract", line 3).

`factcheck` appears nowhere else in the repo outside this filename and the reports that cite it. Anyone globbing `test/skills/*fact-check*` to find the fact-check contract suite misses this file — including the very suite that pins the new contract.

**Recommendation:** Rename to `test/skills/code-review-fact-check-replication.bats`. No consumer references it by path yet, so the rename is free today.

#### F12 — Byte-identical-prompt claim is weakened by the pasted skill's own output-path instruction

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:274-280` with `skills/code-fact-check/SKILL.md:322-325`
**Move:** #3 (consumer contract)
**Confidence:** Medium

Each replicate prompt is the full text of `skills/code-fact-check/SKILL.md` (`:274-276`), which contains "When run standalone, save your report as `docs/reviews/code-fact-check-report.md`" immediately followed by "When run via an orchestrator, the orchestrator specifies the output path — follow its instructions." The deferral sentence resolves the conflict correctly, so this is not a live bug — but it means each replicate prompt carries a competing path for the *canonical merged* file that the orchestrator itself will later write, and three replicates resolving it wrong would clobber the merged report and each other with no detection (the CHECKPOINT at `:306` counts returned agents, not distinct files).

**Recommendation:** Have Stage 1 step 4 say explicitly "this overrides the standalone path in the pasted skill text", and have the merge step verify three distinct `-r<N>` files exist on disk before merging.

---

## What Looks Good

- **The merged report keeps the canonical path.** `docs/reviews/code-fact-check-report.md` remains the single name every existing consumer binds to — `skills/code-fact-check/SKILL.md:322`, `docs/decisions/001-code-fact-checking.md:51`, `test/skills/code-fact-check/eval-criteria.md:64`, `test/skills/code-fact-check-format.bats:11`. Making the merged artifact canonical rather than introducing a new `code-fact-check-merged.md` avoids the whole class of "which report do I read" breakage. This is the single most important call in the change and it was made correctly.
- **Everything downstream is explicitly bound to the merged report.** `:342-345` enumerates the consumers (Fact-Check Gate, Stage 1.5, critic prompts, Confirmed-Good cross-check, severity mapping) rather than leaving readers to infer it — the one place per-replicate reports are also read (`:936-938`) is called out as the deliberate exception.
- **Output Locations tree annotates each new file's role** (`:1065-1068`), so the tree stays self-documenting rather than becoming four similar names.
- **The `## Verdict stability` section does not collide with claim parsing.** `test/skills/helpers.bash:25,31` ends `CLAIMS_BODY` at the first non-`C` `##` heading and runs `ATTENTION_SECTION` to EOF, so a trailing `V` section is inert for both.
- **The 200-line critic-excerpt rule (`:484-486`) needed no change** — it filters by verdict, which the merge preserves, so the `patterns/orchestrated-review.md:149` curation contract survives the k=3 change untouched.
- **Documentation-drift discipline across the change set:** `docs/thoughts/code-review-evaluation-state.md` §1.1 and open-question #2 were both updated in the same commit as the SKILL.md change, and the decision log row 26 states the contract in the same vocabulary the skill uses. Interface change and contract description moved together.
- **`runs/dd-cross-model-2026-07-30/README.md` documents its own asymmetry.** The missing `local_claude-fable-5.meta.json` is not an oversight — the Files table (`*.meta.json` → "OpenRouter arms") and the results table ("n/a (agent)") both explain it. That is exactly the treatment move #8 asks for on a field present in some records and absent in others.
- **New arm files apply the `provider_model` substitution uniformly** across all four arms, so the directory sorts by provider and no arm is special-cased.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Merge ladder's composite `Incorrect (high confidence)` token fails the anchored Verdict enum gate | Inconsistent | `skills/code-review/SKILL.md:323-325` | High |
| 2 | `Replicate verdicts:` added unbolded, outside the closed five-field per-claim schema | Inconsistent | `skills/code-review/SKILL.md:330-333` | High |
| 4 | `k=2 (one replicate failed)` is an unnamed token in an exhaustively specified header | Inconsistent | `skills/code-review/SKILL.md:306-310` | High |
| 6 | `:616` and `:1167` still say "the fact-check report" (singular) after `:936` was updated | Inconsistent | `skills/code-review/SKILL.md:616,1167` | High |
| 3 | `-r<N>` suffix collides with "review round" in flat `docs/reviews/` | Minor | `skills/code-review/SKILL.md:278-280,1066-1068` | High |
| 5 | Stage 1 banner puts `k=3` in the unparameterized `<stage-name>` slot | Minor | `skills/code-review/SKILL.md:246,252,347` | High |
| 7 | `## Verdict stability` sentence case, and defined outside the report's schema doc | Minor | `skills/code-review/SKILL.md:334` | Medium |
| 8 | Severity ladder undefined for `Incorrect` at Low confidence | Minor | `skills/code-review/SKILL.md:323-325` | High |
| 11 | Test filename spells the skill `factcheck`, unhyphenated | Minor | `test/skills/code-review-factcheck-replication.bats:1` | High |
| 9 | Mandatory Rules 1 and 5 not amended for the orchestrator-authored merge / k=2 path | Informational | `skills/code-review/SKILL.md:59-62,73-74` | High |
| 10 | Agent-count wording hardcodes 3 against the documented k=2 path | Informational | `skills/code-review/SKILL.md:214` | Medium |
| 12 | Pasted skill text carries a competing canonical output path into each replicate prompt | Informational | `skills/code-review/SKILL.md:274-280` | Medium |

---

## Overall Assessment

The load-bearing interface decision — keeping `docs/reviews/code-fact-check-report.md` as the canonical merged artifact so no existing consumer rebinds — is right, and the change explicitly enumerates which stages consume the merged report versus the replicates. There is no *breaking* change here: every previously existing path, section, and field still exists with its prior meaning, and the new files are additive.

What the change does not do is extend the producing skill's schema to cover the new report shape. The merged report is now authored by a different agent (the orchestrator) than the schema it must satisfy was written for, and four new contract elements — a composite verdict token (F1), a per-claim `Replicate verdicts` line (F2), a `k=2` header marker (F4), and a `## Verdict stability` section (F7) — were specified only in `skills/code-review/SKILL.md`, in a style that diverges from `skills/code-fact-check/SKILL.md`'s bold-field, closed-enum, Title-Case conventions. F1 is the one with teeth: an orchestrator that writes the ladder's own token onto a `**Verdict:**` line breaks `code-fact-check-format.bats` silently. F6 is the one with the most consumer impact per line changed: the procedural statement at `:616` — the one actually executed during Stage 3 — still says to scan only the merged report, which reopens exactly the single-replicate-observation gap decision 26 was built to close.

All twelve findings are fixable in place and mostly in `skills/code-review/SKILL.md` plus a short addition to `skills/code-fact-check/SKILL.md`'s structure rules; none require rethinking the design. The pattern across F1/F2/F4/F7 is a single root cause worth naming: the new contract was written from the orchestrator's side without a round-trip through the schema document and format gate that define the artifact. Closing that round trip — one section in `code-fact-check/SKILL.md` describing the orchestrator-produced merged report, and matching optional-field assertions in `code-fact-check-format.bats` — would resolve four findings at once and keep the next change to this pipeline from drifting the same way.

## Goal-Alignment Note
- Answered: yes — full API-consistency pass over the branch's consumer-facing contracts
- Out of scope: correctness of the fact-check findings themselves (taken as given per brief); contents of immutable `runs/` artifacts other than `README.md`; security and performance concerns
- Escalate: F6 (`skills/code-review/SKILL.md:616`) — the executed Stage 3 procedure still says to scan only the merged report, reopening the single-replicate gap this branch exists to close, and a stale-wording grep in `code-review-assurance-contract.bats:85` currently protects it
