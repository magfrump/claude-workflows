<!-- Reference file for skills/code-review/SKILL.md. Extracted from the skill body
     2026-09-11 (prompt audit F8) so it loads when the orchestrator reaches the
     stage that needs it, not on every trigger. Edit here, not in the skill. -->

## Deliverable 2: Code Review Rubric

Save this as `docs/reviews/code-review-rubric-<YYYY-MM-DD>-<branch-slug>.md` (e.g.
`code-review-rubric-2026-07-29-feat-auth-tokens.md`), where `<branch-slug>` is the branch
name with `/` replaced by `-`. This is a structured, scannable document the author uses to
track code review resolution.

**Within one review-fix loop, keep updating the same file** — iterations 2 and 3 update
statuses in place, which is what the 🔴/🟡 `Status` columns are for. A *new* file is
created only when the date or the branch changes, i.e. when it is a genuinely different
review. This preserves in-loop status tracking while stopping each loop from destroying the
prior loop's findings.

Why date-stamped rather than overwritten: the rubric is the only durable record of what a
review actually surfaced. Overwriting it means the pipeline's own output history — the
substrate for calibrating critic precision, and for noticing that a finding was waived
rather than fixed — survives only in `git log -p`. Every other artifact this skill produces
is already date-stamped; the rubric was the inconsistent one.

**Use this exact format.** A worked example of the format below, kept in sync with it, is
`test/skills/code-review/rubric-current-format.md`; it is what
`test/skills/code-review-format-contract.bats` asserts against, so changes to the template
here must be mirrored there in the same commit.

```markdown
# Code Review Rubric

**Scope:** [branch/range] | **Reviewed:** [date] | **Status: 🔴 DOES NOT PASS** — [N] red item(s) unresolved

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | [Description] | [Security/Performance/etc.] | Critical | `path/to/file:42` | for-author | — _or_ `#123 Won't-Fix (override departed from — see chat)` | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | [Description] | [Domain] | Medium | [Source, e.g., "Security + Performance", "Fact-check"] | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | [Suggestion] | [Which critic] | Low | for-author | — | 🟢 Open |

The **Status** column is the cheapest calibration instrument in this document. 🟢 is ~70%
of everything the pipeline emits, and it was the only tier with no disposition recorded —
so three quarters of the corpus was unadjudicatable after the fact and precision in the
advisory band could never be estimated. Mark each row `🟢 Open`, `Fixed`, `Won't-Fix`, or
`Deferred` as it is resolved; a `Won't-Fix` here should also become an override-log row.

---

## ↩️ Considered Overrides

Rows lifted from `docs/reviews/override-log.md` that matched the current diff per the
Step 3.5 scan. Each row records how the current run treated the prior call.

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `#123` / 2026-04-12 | Null check in `auth.ts:42` (security) | 🔴 Must-Fix → Won't-Fix | "test-only path; covered by guard upstream" | Inherited — not re-flagged. |

If no rows matched, replace the table with the single line: "No prior overrides
matched this diff." The heading must still appear so absence is auditable across runs.

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.
Every row carries `Evidence` and has passed the Confirmed-Good cross-check — see
[Confirmed Good is a claim, not an output](#confirmed-good-is-a-claim-not-an-output).

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| [Description] | ✅ Confirmed | `path/to/file:42` — "[quoted fragment]" _or_ the enumeration that establishes it (`rg -n "[pattern]" [scope]` → N matches, all [disposition]) | [Which agent] | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

Findings whose **Evidence** block could not be located at the cited location (after
basename resolution) per [Evidence grounding](#evidence-grounding). These are advisory
only: they may not be 🔴 or 🟡 and do not count toward convergence.

| # | Finding | Source | Cited location | Why unverified |
|---|---|---|---|---|
| U1 | [Description] | [Which critic] | `path/to/file:42` | No file matching `file` in repo |

If every finding's evidence checked out, replace the table with the single line: "All
findings' evidence resolved." The heading must still appear so the check is auditable.

---

## ⏭️ Skipped Core Critics

Core critics downgraded by the Stage 1.5 critic gate (diff-shape skip and/or absence of
corroborating fact-check evidence). This section makes coverage limits auditable across runs.

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Diff is copy-only with no logic changes | `git diff --stat` shows only `docs/*.md` changes |

If no critics were skipped, replace the table with the single line: "All core critics ran;
no skips applied." The heading must still appear so skips remain auditable across runs.

---

## 🧩 Composition check

Multi-source co-located clusters found by the Fragment-Composition cross-check, with
the forced question's disposition for each.

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `store/database.go:80-110` | FC-6, R3, arch-4 | composed → X1 |

If no cluster qualified, replace the table with the single line: "No multi-source
co-located clusters qualified." The heading must still appear so the check is auditable
across runs and its precision measurable.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
```

**Legibility-target column:** Carry forward the tag each critic placed on the source finding (see [taxonomy](../../../patterns/orchestrated-review.md#legibility-target-tagging)). Typical mapping: 🔴 / 🟡 / 🟢 rows are `for-author`; ✅ rows are `for-orchestrator-synthesis`. `for-automated-gate` findings (e.g., the security-reviewer HALT-ESCALATE pattern) live in the escalation block above the rubric, not in these tables — they reference the source critique once instead of being duplicated as a row.

### Evidence grounding

Before tiering, verify each finding's **Evidence** block against the file it cites.

1. Read the cited file at the cited line range.
2. Confirm the quoted text appears there (ignore leading/trailing whitespace).
3. **Resolve basenames.** Critics routinely cite `genetics.ts` for
   `packages/sim-core/src/genetics.ts` — in a 287-finding sample only 8 of 54 path
   citations resolved as written, and ~46 were basename shorthand. A checker that does
   not resolve basenames rejects ~85% of *correct* citations. Match on basename when the
   full path does not resolve, and only fail when no file in the repo matches.
4. A finding whose evidence cannot be located goes to a `## ⚠️ Unverified findings`
   section: it may **not** be 🔴 or 🟡, and may not participate in convergence.

**What this is and isn't for.** Anthropic's long-context guidance recommends
quote-before-answer to suppress hallucination, and that is the usual rationale. On this
repo's corpus it is *not* the binding problem: across 330 adjudicated findings there was
**one** borderline location error and zero clear hallucinations. The real payoff is
auditability — only 6 of 43 findings in one corpus carried a mechanically checkable
reference at all, which is why precision could never be measured without re-reading every
finding by hand. Requiring Evidence makes the output machine-checkable going forward.
Treat a firing check as a signal worth investigating, not as a routine occurrence.

### Confirmed Good is a claim, not an output

`✅ Confirmed Good` is the highest-assurance row this rubric emits, and until now it was
the only tier nothing checked. On one measured diff, **two of three model tiers filed the
branch's actual blocking defect under Confirmed Good** — and in one of them the
disconfirming evidence was sitting in that same run's own fact-check report, recorded
verbatim, while the security review certified the claim as "matches reality"
(`docs/thoughts/code-review-evaluation-state.md` §1.3). Treat every ✅ row as a claim that
has to survive the same grounding a 🔴 row does.

**1. Evidence is mandatory.** Each ✅ row's `Evidence` cell is filled and checked with
steps 1–3 of [Evidence grounding](#evidence-grounding) above — cite `path/to/file:line`,
quote the text that appears there, resolve basenames before failing. Same form, same
check; do not invent a second citation format.

**2. An unlocatable ✅ row is deleted, not demoted.** If the evidence cannot be found, the
row does **not** move to `## ⚠️ Unverified Findings` — that section exists for findings
that would otherwise be 🔴 / 🟡, and a confirmation that cannot be grounded is not a
finding at all. It is simply not a confirmation: drop the row. Do not restate it as prose
elsewhere in the synthesis.

**3. Exhaustiveness claims need enumeration, not an instance.** Most false confirmations
here are universally quantified — "no `X` anywhere", "all client fetches are `/api/…`",
"`connect-src 'self'` is sufficient", "sound with no unintended carve-outs". One
confirming instance does not establish a claim of that shape, and citing one is the exact
move that produced the observed miss. Evidence for a universally quantified ✅ row must be
the **enumeration that was actually executed** and its scope (e.g. `rg -n "fetch\(" app`
→ 12 matches, all relative `/api/…`). If no enumeration was run, the row may not be ✅:
either reword it as the specific instance that *was* checked, or drop it.

**4. Cross-check every ✅ row against the fact-check reports (Stage 3, before publishing).**
For each candidate ✅ row, re-read the merged fact-check report **and each current-run
per-replicate report** (`code-fact-check-report-r*.md` filtered to files whose `Commit:`
line matches the current HEAD — the directory is git-tracked, so unfiltered globs read
prior branches' replicates; an observation recorded by only one replicate may be absent
from the merged claim it lost the severity contest to, and it still counts)
for any observation touching the same file, symbol, directive, or claim — **including observations recorded in passing,
under a different claim number, or under a claim the fact-check itself marked Verified.**
The observed failure was exactly this: the contradicting detail (`data:` URLs fetched
client-side) was recorded as supporting colour inside a claim the fact-check verified. Ask
of each observation "if this is true, is the ✅ claim still true?", not "did the fact-check
label this a problem?".

**On a contradiction, the row may not be published as ✅.** The behaviour is fixed so the
item is neither silently dropped nor silently promoted:

- Move it into `## 🟡 Must Address` as a single row worded as the contradiction itself —
  what was certified, and which observation is inconsistent with it.
- `Source:` is `Confirmed-Good cross-check`. `Domain` is the domain of the critic that
  certified it. `Severity` is `Contested` — the confirmation was revoked, no critic
  assigned this a native level, and inventing one would be a fabricated severity.
- The fact-check observation goes in verbatim as the row's evidence, with its
  `path/to/file:line`, so the author can adjudicate without re-deriving it.
- 🟡 is the terminal tier for this mechanism. A contested confirmation is **not** promoted
  to 🔴 by this check, and it does not count as corroboration under the
  [Escalation Rule](#escalation-rule) — this revokes an over-claim, it does not
  manufacture a blocking finding. 🟡 is the right home because it is the tier that means
  "the author must fix this or say on the record why it stands", which is precisely what a
  contested certification needs.
- Name the revocation in the chat synthesis under **Actionable guidance**. A row that
  moves must be visible as having moved; deleting it and moving on is the failure this
  check exists to prevent.

This check is cheap — it is a second read of an artifact already in context — and it is
the one check that would have caught the observed miss.

**5. Provenance: an executed verdict or a covering scope, nothing weaker.** A ✅ row may
only assert what its backing verdict covers. Admissible backing is exactly one of:

- a fact-check verdict with `**Verification mode:** executed` — harvested in Stage 1 or a
  Stage-2.5 submitted-claims verdict; or
- a static `Verified` verdict whose per-claim `Scope:` line covers the row's **full
  breadth** — the row asserts nothing the scope sentence excludes.

A critic's `Evidence: read-static` endorsement, an untagged or `[read:]`-tagged
endorsement bullet, or a Verified stamp narrower than the row's wording is never
promotable to a categorical ✅ row. When the evidence stops one hop short of the row's
wording, either narrow the row to exactly what was established — the scoped instance, not
the category — or omit it; do not soften the wording while keeping the categorical shape.
This is the rubric-side pair of the fact-check `Scope:` field, and the one-hop-short
promotions it blocks (a write-signature read certifying cache contents; a narrow Verified
stamp certifying behavior it never tested) are the measured source of false ✅ rows
(`docs/working/pipeline-persona-attribution-2026-08-17.md` §2). Cite the backing verdict
in the row's `Evidence` cell alongside the `path:line` quote (e.g., `FC claim 7
(executed)` or `FC submitted claim 2 (static; scope covers row)`) so provenance is
auditable.

### Unified Severity Mapping

Use this table to map individual critic severity levels to rubric tiers:

| Rubric Tier | Security | Performance | API Consistency | Architecture | Fact-Check |
|---|---|---|---|---|---|
| 🔴 Must Fix | Critical, High | Critical | Breaking | Structural | Incorrect (high confidence), **behavioral** |
| 🟡 Must Address | Medium | High, Medium | Inconsistent | Coupling | Incorrect (medium confidence), Stale, Mostly Accurate, **Incorrect (high) on a comment/doc only** |
| 🟢 Consider | Low, Informational | Low, Informational | Minor, Informational | Minor, Informational | Unverifiable (see below) |

**Unverifiable is an evidence state, not a severity.** The 🟢 mapping for Unverifiable
applies only when no replicate attached a blocking-grade failure mode to the claim. An
Unverifiable claim whose stated failure mode is a crash, data loss, or security
consequence on a plausible, named input maps to `## 🟡 Must Address` with `Severity:
Unverified-High-Risk`, carrying the claim's "what would be needed to verify" line as
the author note (and, where the claim meets the
[Executable-Defect Channel](#executable-defect-channel) trigger, that channel's
run-the-verification step applies first). Evidence-absence must not be read as low
severity: on the e8 discourse cell, the fact-check's own unanimous top-risk claim (nil
`i.content` crash silently aborting the whole poll job, verdict Unverifiable — no Ruby
in the sandbox) was demoted to 🟢 by this mapping row and died there
(`docs/working/fn-trace-skill-levers-2026-08-21.md`, lever 4). Terminal at 🟡 without
execution or human confirmation, mirroring the channels below.

**Fact-check red is scoped by subject (decision 031).** A fact-check `Incorrect (high
confidence)` is 🔴 only when the *code behaves wrong* — the comment/doc accurately
describes broken behavior, or documents a contract/security rationale a future change
would bind to and be misled by (those stay 🔴 here, or are already caught by
api-consistency `Breaking` / the [Soundness-Contradiction Channel](#soundness-contradiction-channel)).
When the code is correct and the claim's only consequence is that a *reader is
misinformed* (e.g. a wrong runtime name in a comment, a stale "same pattern as X"
pointer), map it to 🟡, not 🔴 — under the 0R+0A merge standard a comment fix costs the
same as an ack, so it is still fixed, but a stale *comment* no longer carries a code
defect's merge-blocking authority. **Immutable-history exception:** a fact-check Incorrect
about a claim in an *already-merged commit message* (or any artifact no new commit can
edit) is not a tier at all — route it to `docs/reviews/override-log.md` as an
accepted-immutable acknowledgment and do not raise it as 🔴/🟡; blocking merge on
unfixable history is a category error. Rationale and the measured driver (verdict-draw
variance on these two marginal classes controls loop length, ~1M tokens per marginal-red
pass) are in `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`.

**Record the critic's own severity, don't discard it.** The `Severity` column on the 🔴 /
🟡 / 🟢 tables carries the source critic's native level (Critical / High / Medium / Low /
Informational, or the domain equivalent — Breaking, Structural, Incorrect) *verbatim*,
before this table maps it to a tier. The mapping is lossy and it is lossy in the direction
that matters: tier assignment is the **least** stable part of the output — identical
prompts on an identical diff produced Medium/Low/Low for the same issue — while the
critic-native High band is the **most** stable, with every finding any run rated High
appearing in all runs of that diff
(`docs/working/experiment-results-code-review-2026-07-29.md`, Result 1). Flattening to a
tier throws away the reliable quantity and keeps the unreliable one. Recording both costs
one column and lets a later gate key on whichever proves sound.

**Contextual critics are advisory:** Findings from `test-strategy`, `tech-debt-triage`, `dependency-upgrade`, and `ui-visual-review` go to 🟢 Consider tier regardless of their internal severity. They inform but never block merge. `architecture-review` is the exception: it is auto-selected like a contextual critic but uses its own severity-to-rubric mapping above and can produce blocking (🔴) findings. Two further exceptions are evidence-gated rather than critic-gated: a contextual-critic finding that meets the [Soundness-Contradiction Channel](#soundness-contradiction-channel) trigger is lifted to 🟡 Must Address (terminal at 🟡), and one that meets the [Executable-Defect Channel](#executable-defect-channel) trigger is verified by execution — confirmed, it maps by native severity as if from a core critic; unexecutable, it lifts to 🟡 (terminal). These are the only paths by which a contextual-critic finding leaves 🟢.

### Mechanism visibility floor (triage-loss prevention)

A finding that names a **concrete defect mechanism** — a specific location plus a causal
chain by which behavior goes wrong ("the dev-only flag is enforceable in production
because Y never checks Z"), not a vague concern — may never be dropped below rubric
visibility on severity or remit grounds alone. Whatever tier the mapping above assigns,
the floor is a 🟢 Consider row carrying the mechanism intact in its `Finding` cell — the
causal chain, not a softened summary. "Out of remit for this critic", "unlikely in
practice", or "defer to cleanup" are grounds for tier placement and author notes, never
for omission. This binds synthesis, contextual critics' findings included: a mechanism a
critic detected and then deferred on remit grounds still lands as a 🟢 row. Measured
driver: on the attribution corpus, detected mechanisms died in severity triage/synthesis —
found by a critic, reasoned correctly, then dropped or deferred out of the rubric entirely
(`docs/working/pipeline-persona-attribution-2026-08-17.md` §2–3). The critic-side severity
floors (e.g., security-reviewer's Floor rule) govern the level a critic may assign; this
rule governs what synthesis may discard — both must hold. Evidence-grounding failures are
unaffected: an ungrounded finding still routes to `## ⚠️ Unverified Findings` — that is an
evidence rule, not a severity call.

### Escalation Rule

If 2+ **core critics, architecture-review, or fact-check** flag the same issue (same code
region, overlapping concern), **record the convergence** on the finding
(`Convergence: security + performance`) and surface it in the synthesis as a
prioritization signal.

**Convergence alone no longer escalates a tier.** Promotion to a higher tier additionally
requires one piece of corroboration that does not come from another critic sampling the
same model:

- a failing test or other executed evidence,
- a fact-check verdict of **Incorrect**, or
- explicit human confirmation during the run.

With corroboration, escalate one tier (🟢 → 🟡, 🟡 → 🔴) and note which corroboration
applied. Without it, the finding keeps its own tier and carries the convergence note.

**Why this changed.** The rule previously read "independent agreement across domains is
the strongest signal that an issue is real." In this repo the critics are **not
independent** — they are the same model on the same diff, differing only by role prompt,
so their errors are correlated by construction. Measurements
(`docs/working/experiment-results-code-review-2026-07-29.md`, Results 2 and 5) found:
cross-role convergence is *rare* (0–1 borderline case across 3 diffs), so the rule almost
never fires; of the four historical convergence-escalations, the one with the **most**
convergence (3 critics) is the one the human waived; and the escalation was applied
inconsistently anyway (≥2 findings labelled convergent were never escalated). The
mechanism was carrying merge-blocking authority on an untested n≈5.

Note what the evidence did *not* show: those escalated findings were factually **valid**.
The failure mode was true-but-unwanted — a real issue promoted to blocking against the
author's judgment. That is why the corroboration required is executable or human, not
another opinion.

Contextual critics (test-strategy, tech-debt-triage, dependency-upgrade) do **not** count toward escalation. Their findings remain in 🟢 Consider regardless of overlap with other critics. If a contextual critic flags the same issue as a core critic, note the agreement in the finding's description for visibility, but do not escalate — contextual critics are advisory and must not gain blocking power through the escalation mechanism. A contextual-critic finding lifted to 🟡 by the [Soundness-Contradiction Channel](#soundness-contradiction-channel) or an unexecuted [Executable-Defect Channel](#executable-defect-channel) lift is likewise excluded here: those lifts are terminal at 🟡 and do not count as escalation corroboration. (An executable-defect finding whose verification *ran and confirmed* is different — the execution itself is admissible corroboration under this rule, which is why that path maps by native severity.)

This rewards convergence — independent agreement across domains is the strongest signal that an issue is real and important. When escalating, place the finding in its new (higher) tier section in the rubric, not in its original tier.

### Soundness-Contradiction Channel

A correctly-reasoned **soundness defect** — code whose documented behaviour is accurately
described and wrong as design — can earn neither of the verdict-driven promotions: the
fact-check correctly rates the accurate comment `Verified`, and nothing is `Breaking`. On
a measured diff, a reviewer reached the ground-truth defect, rejected the docstring
defending it, reconstructed the full behavioural inversion — and filed it 🟢, because no
promotion channel existed (`docs/thoughts/code-review-evaluation-state.md` §1.2, Results
15/14a); the historical human panel filed the same finding 🟡 and gated the merge on it.
This channel closes that gap without granting blocking authority to an unvalidated
mechanism (decision 028).

**Trigger — all three parts must be present in the critic report itself:**

1. a **stated intent quoted verbatim** with `path/to/file:line` — a design document, a
   sibling comment or docstring, a spec the code cites, or `<pr-intent>`. *Verbatim*
   admits standard editorial marks — bracketed alterations (`[is]`) and elision (`…`) —
   so long as the quoted words are recognizably the source's; a paraphrase is not a
   quote (measured: the one true lift in the validation corpus carries an `[is]`
   bracket, so a byte-exact reading fails the channel's own purpose);
2. the **code's actual mechanism quoted or reconstructed** with `path/to/file:line`; and
3. the report's own reasoning that the mechanism produces **runtime behaviour contrary
   to the stated intent** — a behavioural defeat or inversion. Contradictions of a
   stated *convention, structure, or hygiene principle* ("this code breaks the module
   header's stated design principle") do **not** qualify, and neither does a claim that
   documentation is *false* (that is fact-check-`Incorrect` territory). In the
   validation replay this distinction alone removed every clear false lift while
   keeping the true one.

**Precision guard.** An intent claim alone, a missing quote on either side, or a critic's
disagreement with a design's *wisdom* never qualifies. Do not lift a finding whose report
does not contain both quotes — the channel's authority comes from evidence a
human can re-verify in seconds, never from any critic's internal severity label.

**On a qualifying finding:**

- Place it in (or move it to) `## 🟡 Must Address` with `Severity: Contested-Soundness`
  and `Source: Soundness cross-check (found by <critic>)`. **Lift only, never demote:** a
  qualifying finding already at 🔴 (or already 🟡 via another channel) keeps its band and
  simply gains the Contested-Soundness annotation — in the validation corpus 8 of 19
  trigger fires were rows already promoted by existing channels, and a literal "move to
  🟡" would have moved 🔴 rows *down*.
- Both quotes go in verbatim as the row's evidence, each with its `path/to/file:line`,
  so the author can adjudicate without re-deriving the contradiction.
- This applies **regardless of which critic filed the finding** — contextual critics
  included. It is one of the two evidence-gated paths by which a contextual-critic
  finding leaves 🟢 Consider (the other is the
  [Executable-Defect Channel](#executable-defect-channel)); the advisory rule otherwise
  stands unchanged.
- **🟡 is the terminal tier for this channel.** A Contested-Soundness row is never
  promoted to 🔴 by this mechanism, and it does not count as corroboration under the
  [Escalation Rule](#escalation-rule) — the same bar the Confirmed-Good cross-check
  carries. Executed evidence remains the path to 🔴: a failing test demonstrating the
  inversion already promotes under the existing rule, with no help needed from here.
- Name the lift in the chat synthesis under **Actionable guidance**. A row that moved
  must be visible as having moved.

**Why 🟡 and not 🔴.** This mechanism has one retrospective validation behind it and no
prospective one, and such mechanisms get no blocking authority. 🟡 is also the
ground-truth band: the human panel filed the measured case 🟡, and 🟡 means "the author
must fix this or say on the record why it stands" — exactly what a contested soundness
question needs. **Validation status (2026-07-30,
`docs/working/validation-soundness-channel-2026-07-30.md`):** the decision-028 replay
passed with recalibration — recall 1/1 on the ND2 reconstruction; ~1.3% clear-false-lift
rate before the condition-3 behavioural-only tightening above, 0 after it; md1
`proxy.ts:14` held non-vacuously (the negative control with real probing power — ND3's
`sim.ts:625-628` control was vacuous in that corpus and future falsifiers should not
rely on it). The 🟡 cap stands until a **prospective** corpus of ≥10 correct lifts
accumulates (decision 028's cap-raise precondition).

### Executable-Defect Channel

A contextual critic's finding of a *deterministic* failure can be proven cheaply — and
the provenance rules alone would still file it advisory. On the e8 benchmark cells this
demoted two real bugs the pipeline had found and correctly diagnosed: an invalid ERB
template (`end if`) rated Critical by ui-visual-review, which proposed the one-command
verification (`ruby -c`) itself, filed 🟢 because its sole critic is contextual; and a
unanimously-flagged nil-crash risk (`i.content.scrub` on feed items with no content,
named by all three fact-check replicates as the diff's highest-value unresolved risk)
filed 🟢 because its verdict was Unverifiable
(`docs/working/fn-trace-skill-levers-2026-08-21.md`, lever 4). Both died in the advisory
bucket — 🟢 is ~70% never-actioned by this rubric's own calibration note. Like the
Soundness-Contradiction Channel, this channel grants a lift only on evidence
re-verifiable in seconds — here, evidence a *machine* verifies.

**Trigger — all three parts must be present in the critic report itself:**

1. the finding asserts a **deterministic** failure — a syntax/parse error, a guaranteed
   exception on a **named, plausible** input or state, a violated type/contract that
   cannot fail to fire — not a probabilistic, load-dependent, or configuration-remote
   one;
2. the report names a **concrete verification executable in the review sandbox**: a
   single command with expected pass/fail semantics, an existing test, or a ≤10-line
   reproduction; and
3. the mechanism is quoted with `path/to/file:line`.

**On a qualifying finding — run the verification first.** Execute the named check,
capturing provenance exactly as fact-check's `executed` mode requires (command, cwd,
exit code, timestamp, output captured under `docs/reviews/execution-logs/`). Then:

- **Confirms the defect** → the finding now carries executed evidence — precisely the
  non-correlated corroboration the [Escalation Rule](#escalation-rule) demands — so map
  it through the Unified Severity Mapping **by its native severity as if filed by a
  core critic** (a confirmed Critical/High is 🔴). `Source: Executable-defect channel
  (found by <critic>, executed)`.
- **Cannot be run** (missing interpreter, sandbox restriction, blocked dependency) →
  lift to `## 🟡 Must Address` with `Severity: Unexecuted-Deterministic`, `Source:
  Executable-defect channel (found by <critic>)`, naming the specific blocker and the
  exact command a human should run. **🟡 is terminal on this path** — blocking
  authority requires the execution or a human, and the row does not count as
  escalation-rule corroboration.
- **Refutes the finding** → no lift; record the refuting execution on the 🟢 row (or
  drop it per evidence grounding) so the refutation is visible.

**Precision guard.** "Might crash", "could be nil in some configurations", or any
failure whose triggering input/state the report cannot name concretely does not qualify
— that is ordinary severity-tier material. The channel's authority comes from the
determinism plus the named verification, never from the critic's severity label. Lift
only, never demote, per the Soundness channel's rule.

### Rubric Status Line

- Red items unresolved: `**Status: 🔴 DOES NOT PASS** — [N] red item(s) unresolved`
- Zero red but amber open: `**Status: 🟡 CONDITIONAL PASS** — [N] amber item(s) awaiting resolution or justification`
- All red and amber resolved: `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation`

#### The single-sample label

A passing verdict is **one draw**, not a proof of absence. Measured 🔴-band self-agreement
between replicate runs of this pipeline on an identical diff is **0.14–0.25**
(`docs/thoughts/code-review-evaluation-state.md` §1.4) — a second run of the same
configuration on the same code frequently disagrees about what is blocking. So a clean
result says "this run found nothing", never "there is nothing".

Carry this label, verbatim and once, wherever a clean or passing verdict is emitted:

> single-sample review; absence of findings is not an attestation

It appears in exactly two places, and never more than once in each: appended to the
`✅ PASSES REVIEW` status line above, and in the chat synthesis when the run is clean
(see [Deliverable 1](../SKILL.md#deliverable-1-chat-synthesis)). Do not expand it into a paragraph,
do not repeat it per section, and do not attach it to a 🔴 or 🟡 verdict — those are not
being consumed as assurance, and hedging them dilutes the label where it matters.
