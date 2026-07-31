# API Consistency Review — exp/cross-model-openrouter-sweep (021 Stage-1 adoption)

Commit: fbd8597

**Scope:** `git diff main...HEAD` — 10 files, +207/−7 (2 commits: 8c23b7e, fbd8597)
**Date:** 2026-07-31
**Based on:** `docs/reviews/code-fact-check-report.md` (k=3 merged)

---

## Baseline Conventions

Surveyed before evaluating the diff, so the author can check the baseline:

**1. Harness CLI + output (`scripts/cross-model-review.py`, sibling `scripts/dd-cross-model-sweep.py`).**
- Flags are lowercase-kebab with a value or `action="store_true"`; `--context-base`, `--max-inline-kb`, `--dry-run`, `--analyze-only`, `--max-usd`. No flag has a default that changes behavior silently.
- `description=__doc__` with `RawDescriptionHelpFormatter` (line 344) — the module docstring **is** the `--help` preamble, so docstring edits are user-visible CLI documentation.
- **All** progress/status/advisory output goes to **stdout** via bare `print()`. This holds across the whole file (lines 398–416, 452, 470, 489, 497, 503, 560–572) and across the sibling sweep script (`dd-cross-model-sweep.py:61,69,73,76`). Hard failures use `sys.exit("msg")` (lines 369–377, 429, 432), which is the file's only pre-existing stderr channel.
- Advisory (non-fatal) conditions use a bare `WARNING: ` prefix — exactly one precedent, line 497.
- Run records are append-only JSON objects; new fields (`context_base`) were added as additive keys and read back with `r.get(...)` (line 495), i.e. the established compatibility technique.

**2. `skills/code-review/SKILL.md` process contract.**
- Prompt-content requirements live as **numbered steps inside the mandatory dispatch checklists**, not as prose elsewhere in the document. Stage 1 uses `1, 2, 3, 3b, ...` (lines 277–290); Stage 2 uses `1..7` under an explicit "you MUST" (lines 522–539).
- The decision-29 precedent is the exact analog of this diff's change: a validated, experiment-backed requirement about what every replicate prompt must contain was inserted as numbered step **`3b`** in the Stage-1 checklist — deliberately renumbering rather than adding prose.
- Scope override vocabulary is enumerated once at lines 93–97 as a four-item list: `--files`, `--pr`, `--range`, `--staged`.

**3. `docs/decisions/log.md`.**
- Five-column table `| # | Date | Decision | Context / Why | Full Record |`.
- The **Full Record** column is defined at line 19 as the link a row gets when *that row* is promoted to a record. Empirically the row number and the record number are the same for every linked row: 2→002, 3→003, …, 17→017, 20→020, 21→021, 22→022, 28→028 (verified by parsing all rows). Unpromoted rows carry `—`.

**4. `docs/working/` experiment docs and `runs/cross-model/` artifacts.**
- Experiment docs: `experiment-<topic>-<YYYY-MM-DD>.md` (`experiment-cross-model-review-2026-07-30.md`, `experiment-md1-r1-replication-2026-07-30.md`, `experiment-results-code-review-2026-07-29.md`).
- Run dirs: `<arm-prefix>-<short-sha>` (`gt-31e2d3a`, `fast-7ceba3f`, `gt-8ef9d52`) or a bare case id (`nd1`, `md1`); each holds `findings.jsonl` + `overlap.json`.

---

## Name-Pattern Audit

This diff introduces **no new CLI flags, no new functions, no new JSON fields, and no new exported symbols** — the harness change is docstring text plus one `print()`. The new public names are documentation/artifact identifiers:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `docs/working/experiment-stage1-fp-kill-2026-07-31.md` | doc filename | `experiment-md1-r1-replication-2026-07-30.md`, `experiment-cross-model-review-2026-07-30.md`, `experiment-results-code-review-2026-07-29.md` | `docs/working/experiment-*.md` | Consistent — matches `experiment-<topic>-<date>.md` |
| `runs/cross-model/s1-31e2d3a`, `runs/cross-model/s1-7ceba3f` | run dir | `gt-31e2d3a`, `fast-31e2d3a`, `gt-8ef9d52` | `runs/cross-model/*` | Consistent — `<arm-prefix>-<short-sha>`; `s1-` is a new arm prefix on an existing shape, and reuses the same target SHAs as `gt-`/`fast-`, which makes the arms comparable at a glance |
| decision-log row `30` → `[021](021-reviewer-context-management.md)` | decision-log Full Record value | rows `21`→`021`, `28`→`028`, `22`→`022` | `docs/decisions/log.md:22-51` | **Inconsistent** — first row whose Full Record number differs from its row number; see Finding 2 |
| `WARNING: diff-only mode is a recall probe …` | console message prefix | `WARNING: findings.jsonl mixes …` (`cross-model-review.py:497`) | `scripts/cross-model-review.py:497` | Prefix consistent; **stream inconsistent** — see Finding 3 |
| `**Partial-scope reviews must label out-of-scope sibling work.**` | SKILL.md rule heading | `#### Large diff triage (~1000+ lines)` (:103), numbered step `3b` (:281) | `skills/code-review/SKILL.md` | **Inconsistent placement** — prompt-content requirements are numbered checklist steps here, not free-standing prose; see Finding 1 |
| `docs/reviews/api-consistency-review-2026-07-31-r2.md` | review artifact | `api-consistency-review-2026-07-31.md`, `code-fact-check-report-r1.md` | `docs/reviews/*` | New combination (date + `-rN`) of two existing suffix conventions; orchestrator-specified, not author-chosen — noted, not a finding |

---

## Findings

#### 1. The partial-scope labelling rule is a "every critic prompt must state" requirement placed outside the mandatory prompt-assembly checklists that orchestrators actually follow

**Severity:** Inconsistent
**Location:** `skills/code-review/SKILL.md:101` (new rule) vs `skills/code-review/SKILL.md:277-290` and `:522-531` (the checklists)
**Move:** #3 (consumer contract) + #7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> **Partial-scope reviews must label out-of-scope sibling work.** When the scope is narrower than the full branch changeset (`--range`, `--staged`, or `--files` on a multi-commit branch), every critic prompt must state: (a) that commits/files on the branch outside the scope are *already committed — context only, not under review*, and (b) that before flagging work as "missing", the critic must check the rest of the branch (`git log main..HEAD`, `git diff main...HEAD -- <path>`) for it.

> 3. Include the scope specification (e.g., "Review files changed on the current branch relative
>    to main using `git diff main...HEAD`")

> For each critic agent, you MUST:
>
> 1. Read the full contents of that critic's skill file (e.g., `skills/security-reviewer/SKILL.md`)
> 2. Paste those contents directly into the Agent tool prompt
> 3. Include the scope specification so the agent runs its own `git diff`

`Precedent: prompt-content requirements are inserted as numbered steps in the dispatch checklist (step "3b", the decision-29 rich-brief rule) used in skills/code-review/SKILL.md:281-290`

The consumer of this contract is an orchestrator agent composing critic prompts. That agent works from the two numbered "you MUST" checklists (Stage 1 at :277, Stage 2 at :522), and neither now mentions the label. The nearest precedent is decision 29, which faced the identical problem — a validated, experiment-backed requirement about what every replicate prompt must contain — and solved it by renumbering the checklist to insert step `3b` rather than adding prose upstream. Placing this one in Step 1 ("Determine scope") also mislocates it: the rule is about prompt *content*, and Step 1's own closing line already hands off to the dispatch stages ("Pass the scope specification so each agent runs its own `git diff`", :99). A conditional rule that only fires on `--range`/`--staged`/`--files` is exactly the kind an orchestrator skips when it is not in the checklist it is executing. Secondary asymmetry: the rule says "every **critic** prompt", but the Stage-1 fact-check replicates receive the same scope spec (:279) and can produce the same missing-work FP as a `Stale`/`Incorrect` verdict — the strongest blocking channel in the pipeline.

**Recommendation:** Insert the requirement as a numbered step in both dispatch checklists (e.g. Stage 2 step `3a`, mirroring decision 29's `3b`), leaving a one-line pointer at :101 rather than the full rule. Clarify whether Stage-1 fact-check replicates are in scope — if yes, say "every agent prompt", not "every critic prompt".

---

#### 2. Decision-log row 30 links another decision's full record, breaking the row-number ↔ record-number correspondence every other linked row holds

**Severity:** Inconsistent
**Location:** `docs/decisions/log.md:51`
**Move:** #2 (naming against the grain) + #7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> | 30 | 2026-07-31 | Adopt 021 Stage-1 context as the review-quality default across the process: … | … Single clear answer — the decision record (021) prescribed exactly this adoption once validated; this row records the process wiring | [021](021-reviewer-context-management.md) |

> Log entries that later get a full record should link to it in the **Full Record** column (see entry #6 below for an example). Full decision records do not need to back-link here.

`Precedent: row number == linked record number for every linked row (2→002, 3→003, 6→006, 17→017, 20→020, 21→021, 22→022, 28→028) in docs/decisions/log.md:22-51`

Row 21 already links `[021]`; row 30 now links it too, so two rows point at the same record and the column's documented meaning at :19 ("entries that later get a full record") no longer holds for row 30 — 021 is not row 30's promotion, it is the upstream decision row 30 implements. Readers and grep-based process steps that resolve "row N ↔ record NNN" (the pattern every other row teaches) will mis-resolve here, and a reader arriving at `021-reviewer-context-management.md` finds no mention of row 30. Note the diff also updates 021's own record (`021:11-17`) with the validation result, so the relationship is genuinely upstream/downstream, not promotion.

**Recommendation:** Put `—` in the Full Record column and move the 021 reference into the "Context / Why" cell (which already names it in prose: "the decision record (021) prescribed exactly this adoption"). If a cross-reference in the column is wanted, distinguish it from a promotion link, e.g. `— (implements [021](021-reviewer-context-management.md))`.

---

#### 3. The new advisory warning writes to stderr while the script's only other `WARNING:` — and every other status line, in this script and its sibling — writes to stdout

**Severity:** Minor
**Location:** `scripts/cross-model-review.py:422-427`
**Move:** #4 (error consistency) + #7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> ```python
>         if not args.context_base:
>             # Decision 021 + the 2026-07-31 FP-kill validation: diff-only manufactures
>             # sibling-commit/flattened-boundary FPs; Stage-1 context is the review-quality mode.
>             print("WARNING: diff-only mode is a recall probe with a known misattribution "
>                   "FP class (decision 021; validated fix: --context-base). Findings from "
>                   "this run must not be treated as review verdicts.", file=sys.stderr)
> ```

> ```python
>     if len(variants) > 1:
>         print(f"WARNING: findings.jsonl mixes {len(variants)} (prompt_sha, context_base) "
>               f"variants — overlap numbers below pool across different prompts")
> ```

The two conditions are the same kind — non-fatal advisories that qualify how the run's numbers may be used — and now differ in destination. The consequence is not hypothetical: an operator who runs `cross-model-review.py … > run.log` gets the mixed-variants caveat captured in the log and the diff-only caveat lost to the terminal, which inverts the intent (the new warning is the more consequential of the two: "must not be treated as review verdicts"). The code fact-check verified the stderr choice does protect the stdout status lines that tooling parses — that is a real benefit, but it is a benefit the file has not previously claimed for its warnings, and taking it for one warning and not the other is the inconsistency. `sys.exit()` is currently the file's only stderr channel, which gives stderr a clean "this run is dead" meaning that the new advisory dilutes.

**Recommendation:** Pick one channel for advisories and apply it to both call sites. Preferred: keep stderr (it is the better convention) and move line 497's `WARNING:` to stderr in the same commit, so the file has one rule — `sys.exit` and `WARNING:` on stderr, run status on stdout — and say so in the docstring next to the existing "print a warning to stderr" sentence.

---

#### 4. `--context-base`'s per-flag `--help` text still reads as a neutral opt-in while the description block now calls it RECOMMENDED

**Severity:** Minor
**Location:** `scripts/cross-model-review.py:354-356` (unchanged) vs `:16, :25-28` (changed)
**Move:** #7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> ```python
>     ap.add_argument("--context-base", help="decision-021 Stage 1: enrich the prompt with the "
>                     "sibling-branch diff from this ref to the range start, plus whole enclosing "
>                     "files. Omit for the historical diff-only prompt.")
> ```

> ```
>   and byte-identical across models. VALIDATED 2026-07-31
>   … --context-base is therefore the RECOMMENDED mode for any
>   review-quality use; run diff-only only as a deliberate recall probe or for
>   comparability with pre-021 measurements (live diff-only runs print a
>   warning to stderr).
> ```

Mitigating: `description=__doc__` (line 344) means the recommendation *does* appear in `--help`, in the preamble. But the per-flag line is what a reader scanning the options block sees, and "Omit for the historical diff-only prompt" reads as a neutral either/or — the same wording that was accurate when the docstring said "opt-in". Decision-log row 30 states the harness "documents `--context-base` as the recommended mode"; one of the two places it is documented was not updated. Note also that no `--help`-visible text says the *default* (no flag) is the discouraged path — a reader has to infer it from "Omit".

**Recommendation:** Extend the per-flag help to carry the same one-clause signal, e.g. `"… plus whole enclosing files. Recommended for any review-quality run; omit only for a deliberate recall probe or pre-021 comparability."`

---

#### 5. The new rule enumerates the narrow scopes as `--range`/`--staged`/`--files`, omitting `--pr` from the four-item list two lines above it

**Severity:** Minor
**Location:** `skills/code-review/SKILL.md:101` vs `:93-97`
**Move:** #7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
> Accept user overrides:
> - **File list:** `--files path/to/a.py path/to/b.js`
> - **PR number:** `--pr 42` (use `gh pr diff 42`)
> - **Commit range:** `--range abc123..def456`
> - **Staged changes:** `--staged` (use `git diff --cached`)

> When the scope is narrower than the full branch changeset (`--range`, `--staged`, or `--files` on a multi-commit branch)

`Precedent: the scope-override vocabulary is enumerated as the four-item list --files / --pr / --range / --staged in skills/code-review/SKILL.md:93-97`

The rule's trigger condition re-enumerates a documented vocabulary and drops one member without saying why. `--pr 42` → `gh pr diff 42` is narrower than the full branch changeset whenever the PR is stacked or the branch has commits outside the PR — exactly the sibling-commit situation the rule addresses. An orchestrator applying the rule literally will not label a `--pr` review. If the omission is deliberate (a PR diff is normally the whole logical changeset), the rule should say so, because a reader comparing the two lists cannot tell omission from oversight.

**Recommendation:** Either add `--pr` to the enumeration, or replace the flag list with the general condition ("any scope narrower than `git diff main...HEAD`") and note `--pr` as usually-but-not-always full.

---

#### 6. The new warning has no test, on a surface whose own test file exists because an untested change shipped a defect

**Severity:** Minor
**Location:** `scripts/cross-model-review.py:422-427`; `test/cross-model-review-stage1.bats`
**Move:** #3 (consumer contract — test drift)
**Confidence:** High
**Legibility-target:** for-automated-gate
**Evidence:**
> ```
> # Unit/e2e coverage for scripts/cross-model-review.py's Stage-1 context path
> # (decision 021), added by the 2026-07-31 review (rubric C4): the binary-crash
> # class shipped precisely because this surface had zero tests.
> ```

> ```bash
>   run env OPENROUTER_API_KEY=sk-or-bogus-offline "$SCRIPT" --repo "$FIX" \
>     --range "$LEFT..$RIGHT" --models fake/model --replicates 1 \
>     --out "$BATS_TEST_TMPDIR/out-guard"
>   [ "$status" -ne 0 ]
>   [[ "$output" == *"cost guard cannot price"* ]]
> ```

I ran the suite: 8/8 pass, and test 8 ("unpriced models fail the cost guard closed") is already the exact code path that now emits the warning — no `--context-base`, non-dry-run. It passes only because bats merges stderr into `$output` and the assertion is a substring match, so the new line is silently absorbed rather than checked. Two properties are therefore unverified by the suite: that the warning fires at all on a live diff-only run, and that it lands on **stderr** — the latter being precisely the property the code fact-check identified as protecting the stdout status lines other tooling parses. Adding a warning without a test is the convention this file's header commits against; every other guard in the block (cost-guard refusal, `$0.00` suppression, prompt-sha stability) has one.

**Recommendation:** Add a bats case asserting the warning appears on stderr and not stdout (e.g. `run bash -c '… 2>/dev/null'` → no `WARNING: diff-only`, and `… 2>&1 >/dev/null` → contains it), plus a negative case that `--context-base` suppresses it.

---

#### 7. The warning is emitted before the two guards that can abort the run, so a refused run still tells the operator not to trust findings it never produced

**Severity:** Informational
**Location:** `scripts/cross-model-review.py:422-432`
**Move:** #9 (safety semantics / ordering)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> ```python
>         if not args.context_base:
>             …
>             print("WARNING: diff-only mode is a recall probe …", file=sys.stderr)
>         if unpriced:
>             sys.exit(f"cost guard cannot price: {', '.join(unpriced)} — refusing to send "
>                      f"(pricing fetch failed or unknown model id); re-run when pricing resolves")
>         if projected > args.max_usd:
>             sys.exit(f"projected ${projected:.2f} > --max-usd {args.max_usd}; raise the cap to proceed")
> ```

The placement is defensible against the file's "informational prints first, guards last" shape, but the message's content ("Findings from **this run** must not be treated as review verdicts") presupposes a run that happens. When the cost guard refuses, the operator gets a warning about a nonexistent run's findings immediately followed by a refusal — mildly confusing, and it makes the warning less trustworthy as a signal that calls were actually sent. The `--dry-run` early return at :417-421 already correctly excludes the no-spend path, which shows the intent was "warn only on live runs"; the guards are the remaining non-live paths.

**Recommendation:** Move the block to just after the `--max-usd` guard (immediately before `with open(findings_path, "w")`), so the warning is emitted only when calls are actually about to be sent.

---

#### 8. The "already committed — context only" label exists in three renderings across the surfaces this diff touches

**Severity:** Informational
**Location:** `scripts/cross-model-review.py:188` and `:192`; `skills/code-review/SKILL.md:101`; `docs/decisions/log.md:51`; `docs/decisions/021-reviewer-context-management.md:78,124`
**Move:** #7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
> ```python
>         parts.append(header(f"ALREADY COMMITTED - CONTEXT ONLY, NOT UNDER REVIEW "
>                             f"(branch diff {context_base}...{left})") + sibling)
> ```

> ```python
>         parts.append(header("ALREADY COMMITTED - CONTEXT ONLY") + f"(none: no sibling "
>                      f"commits between {context_base} and the range start)\n")
> ```

> must state: (a) that commits/files on the branch outside the scope are *already committed — context only, not under review*

`Precedent: the canonical literal is uppercase ASCII-hyphen "ALREADY COMMITTED - CONTEXT ONLY, NOT UNDER REVIEW" in scripts/cross-model-review.py:188`

The harness emits the uppercase ASCII-hyphen form; the SKILL.md rule and the decision log quote a lowercase em-dash form; and the harness's own empty-sibling branch (`:192`, pre-existing, not touched by this diff) drops ", NOT UNDER REVIEW" entirely. Nothing parses these strings, so there is no functional break — but decision-log row 30 quotes the phrase as though it were a single shared token adopted across both surfaces, and it is not. Since the whole mechanism is "a label a model must recognize", a stable canonical spelling is cheap insurance and makes the two adoption sites greppable as one.

**Recommendation:** Name one canonical spelling in decision 021, have SKILL.md:101 quote the harness literal verbatim, and (separately, since it is pre-existing) align `:192` with `:188`.

---

#### 9. SKILL.md:101 asserts its own validity from a warrant the fact-check found incorrect

**Severity:** Minor
**Location:** `skills/code-review/SKILL.md:101`
**Move:** #3 (documentation drift on a consumer contract)
**Confidence:** High (inherited from `docs/reviews/code-fact-check-report.md`; not re-verified)
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
> This rule is validated, not speculative: the 2026-07-31 Stage-1 experiment (`docs/working/experiment-stage1-fp-kill-2026-07-31.md`, decision 021) showed unlabelled single-commit scope made **all four model families** unanimously flag work as missing that sat in sibling commits, and the label + sibling context reduced that FP class to 0/8 while *raising* agreement on real issues.

The merged k=3 fact-check rates "all four families unanimously" as Incorrect (actual: 3/4 families, 6/11 replicates). I am not re-verifying that; I flag it here because of *where* it sits. This sentence is the sole authority clause of a mandatory process contract that other orchestrator runs consume, and it is doing load-bearing work — the rule's phrasing ("validated, not speculative") explicitly invites a reader to weigh the warrant before complying. A reader who checks the cited experiment doc and finds 3/4 rather than 4/4 has grounds to treat the whole rule as soft. The underlying result (0/8 reproduction) is unaffected and is the stronger half of the claim.

**Recommendation:** Restate as "three of four model families (6/11 replicates)" and let the 0/8 reproduction carry the authority clause. Apply the same correction wherever the k=3 report flagged the sibling miscounts in `docs/thoughts/code-review-evaluation-state.md` and `docs/decisions/log.md:51`, so all three copies of the warrant agree.

---

## What Looks Good

- **The compatibility guarantee is honored exactly.** No CLI flag signature changed; `--context-base` stays optional with no default; the diff-only prompt is byte-identical (fact-check: sha `968d268b1689`, bats 8/8, including the dedicated `diff-only dry-run prompt is unchanged … (prompt sha stable)` test). The repo's implicit versioning convention here — "byte-identical default prompt keeps historical numbers comparable" — is stated in the docstring and actually upheld. A recommendation was strengthened without a behavior change; that is the right shape for this kind of adoption.
- **`--dry-run`'s no-spend guarantee is preserved.** The warning sits after the dry-run early return, so the no-spend path is unchanged and cannot acquire new output.
- **Additive-field discipline on the run artifacts.** `runs/cross-model/s1-*/findings.jsonl` carries `context_base`, absent from the older `gt-*`/`fast-*`/`nd*` corpora; the analysis path reads it via `r.get("context_base")` (line 495), so mixed-vintage corpora still load and are correctly reported as multi-variant. `overlap.json` likewise gains `abstain` additively. Backward-compatible by move #6.
- **`s1-` run dirs reuse the same target SHAs as the `gt-`/`fast-` arms**, which makes the arm-to-arm comparison the experiment claims directly checkable from the directory listing — a good use of an existing naming convention rather than a new one.
- **The warning's tone matches the file.** Bare `WARNING: ` prefix, states the condition, names the fix flag, and names the decision that justifies it — the same shape as line 497 and as the `sys.exit` guard messages. Only the stream deviates (Finding 3).
- **The docstring change is genuinely user-facing and was treated as such.** Because `description=__doc__`, the author updating the docstring did update `--help`; Finding 4 is the residue, not a miss of the whole surface.
- **Status-line contract untouched.** `context mode: …`, `prompt size: …`, `{model} r{r}: …` are all unchanged, so the bats assertion at `test/cross-model-review-stage1.bats:80` and any external log parser keep working.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Partial-scope labelling rule not wired into the mandatory prompt-assembly checklists | Inconsistent | `skills/code-review/SKILL.md:101` vs `:277-290`, `:522-531` | High |
| 2 | Decision-log row 30 links another decision's record, breaking row-N ↔ record-NNN | Inconsistent | `docs/decisions/log.md:51` | High |
| 3 | New `WARNING:` on stderr while the existing one is on stdout | Minor | `scripts/cross-model-review.py:422-427` | High |
| 4 | `--context-base` per-flag help still neutral vs RECOMMENDED in the description block | Minor | `scripts/cross-model-review.py:354-356` | High |
| 6 | No test asserts the new warning fires or lands on stderr | Minor | `scripts/cross-model-review.py:422-427`; `test/cross-model-review-stage1.bats` | High |
| 9 | SKILL.md:101's authority clause rests on a warrant the fact-check found incorrect | Minor | `skills/code-review/SKILL.md:101` | High |
| 5 | Rule's scope enumeration omits `--pr` | Minor | `skills/code-review/SKILL.md:101` vs `:93-97` | Medium |
| 7 | Warning emitted before the guards that can abort the run | Informational | `scripts/cross-model-review.py:422-432` | High |
| 8 | Context-only label rendered three ways across surfaces | Informational | `cross-model-review.py:188,192`; `SKILL.md:101`; `log.md:51` | Medium |

---

## Overall Assessment

This diff is consistent with the codebase's conventions where it matters most for consumers: no interface signature changed, the byte-identical diff-only prompt — this harness's de-facto compatibility guarantee — is preserved and test-enforced, the `--dry-run` no-spend contract is untouched, the new run artifacts extend the JSONL/`overlap.json` schemas additively with the `.get()` read-back pattern the analysis path already uses, and the new filenames follow their neighbors exactly. There are no Breaking findings; nothing here will break a consumer written against the previous version. The two Inconsistent findings are both placement/cross-reference problems in documentation contracts rather than code: the partial-scope rule is a "you MUST include this in every prompt" requirement filed outside the two numbered "you MUST" checklists that orchestrators execute — the codebase's own decision-29 precedent shows the intended shape (numbered step `3b`) — and decision-log row 30 is the first row to break the row-number ↔ record-number correspondence that every other linked row teaches. Both are fixable in place in minutes and neither indicates the author failed to survey conventions; they read as a rule written where it was discovered rather than where it will be consumed. The stderr/stdout split on `WARNING:` (Finding 3) is the one worth resolving deliberately rather than reflexively: the new choice is the better convention, so the cheapest consistent fix is to move the older warning to match it and state the rule in the docstring. Consumer impact overall is low and confined to readers and orchestrator agents, not to running code.

## Goal-Alignment Note
- Answered: yes — API-consistency review of all 10 changed files, 9 findings, no Breaking
- Out of scope: correctness of the experiment's statistics and the `runs/cross-model/s1-*` findings content (fact-check/experiment-validation territory); the pre-existing `cross-model-review.py:192` label truncation, noted in Finding 8 but not on this branch's diff
- Escalate: nothing
