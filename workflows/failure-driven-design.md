---
value-justification: "Replaces requirements-first design with failure-mode-first design when the dominant risk is repeating known classes of incident — making the catalog of past pain the explicit driver of the next implementation."
---

# Failure-Driven Design Workflow

## When to use

Use Failure-Driven Design (FDD) when the *space of things that could go wrong* is richer and more concrete than the space of forward requirements — and when preventing those specific failures is the primary value of the design. Typical triggers:

- A new system in a domain with deep incident history (your own postmortems, prior-quarter bugs, on-call journals, competitor outages).
- Reliability- or safety-sensitive work (data-loss avoidance, auth correctness, financial integrity, deploy safety) where "the design that prevents the known failures" is a sharper target than "the design that meets vague requirements."
- Hardening an existing surface where the failure catalog already exists in the form of bug tickets, near-misses, or fears the team can articulate.
- Building a replacement for a system the team knows mostly through its failure modes.

### Generative vs. evaluative: contrast with `skills/what-if-analysis.md`

FDD is **generative**: it has no proposed design as input and *produces one* from a catalog of concrete failures. The skill [`what-if-analysis`](../skills/what-if-analysis.md) is **evaluative**: it requires an existing proposal (plan, design, migration, policy) and stress-tests it through pre-mortem, second-order effects, hidden coupling, and reversibility analysis.

The two are complements, not alternatives:

- If you have failures and need a design → FDD.
- If you have a design and need to know what could still break → `what-if-analysis`.
- If you have failures **and** want a stress-tested design → FDD, then feed FDD's output into `what-if-analysis` as the proposal to validate. See the FDD → `what-if-analysis` compose path in "When to pivot" below.

Skip FDD when the dominant uncertainty is "what should this do?" rather than "what must it not do?" — for those cases use RPI (default) or Divergent Design (when 3+ design approaches are in tension). FDD's bet is that failure data is denser than requirement data; if that bet is wrong, RPI or DD will be faster.

## When to pivot

- **→ RPI**: The default downstream handoff. Once FDD has produced a merged feasible design (step 4), it does not implement — it hands off to [`research-plan-implement.md`](research-plan-implement.md). The FDD record becomes an input to RPI's research doc: the failure catalog and prevention sketches replace the "explore what could break" part of RPI research, and the merged design becomes the seed of RPI's plan. Reference the FDD record (`docs/working/fdd-{topic}.md`) from the plan's `Research:` link line.
- **→ `what-if-analysis`** ([`../skills/what-if-analysis.md`](../skills/what-if-analysis.md)): The validation compose path. After step 4 produces a merged design, run `what-if-analysis` against it before handing off to RPI. FDD asks "what failures must we prevent?"; `what-if-analysis` then asks "given this design, what failures could still occur and what assumptions might be wrong?" The FDD merged design is the *proposal* the skill requires as input, and the FDD failure catalog tells the skill which assumptions have already been examined (so it can focus on the gaps). Run this whenever the design will be hard to reverse — the cost of the validation pass is small relative to the cost of shipping a design that prevents the cataloged failures but introduces new ones.
- **↔ Divergent Design** ([`divergent-design.md`](divergent-design.md)): When the merge step (step 4) surfaces *irreconcilable* prevention sketches — two or more sketches that each prevent a real failure but cannot coexist in one design — invoke DD as a sub-procedure to make the tradeoff. The failure modes become DD's diagnose-step constraints (each `prevent-X` becomes a hard constraint); the conflicting prevention sketches become DD's diverge-step candidates. DD's decision feeds back into FDD's merge step.
- **← From Bug Diagnosis**: When a bug postmortem (`bug-diagnosis.md`) reveals a *class* of failures rather than a single incident — i.e., the diagnosis names a category of bug that could recur in adjacent code — pivot to FDD to design preventive structure across the class, rather than only patching the single occurrence. The diagnosis log seeds the failure catalog with at least one richly-detailed entry.
- **← From RPI**: When RPI research surfaces that the system's design is dominated by reliability/correctness concerns and the team has more failure data than forward requirements, pivot to FDD. The RPI research doc's "Invariants" and "Gotchas" sections seed the failure catalog.

## Working documents

This workflow produces one markdown artifact in `docs/working/` within the project:

- `docs/working/fdd-{topic}.md` — the failure catalog, categorization, prevention sketches, merged design, and explicit handoff section pointing to the RPI plan that will implement it.

Follows the same convention as RPI working docs: committed to the repo, treated as disposable, collapsed in GitHub diffs via `linguist-generated` (see RPI's "Working documents" section for the `.gitattributes` pattern).

The artifact uses the same three-line header convention as RPI and DD working docs:

- **Goal**: One sentence — the design problem being solved, framed as "design X such that failures {f1, f2, ...} are prevented."
- **Project state**: One sentence — `<what this branch delivers> · <position in larger initiative, or "standalone"> · <blocked on, or "not blocked"> (cite: <short-hash> | <branch-name> | <docs/path>)`.
- **Task status**: Lifecycle keyword from `in-progress | blocked | paused | complete`, optionally with a free-form phase note (e.g., `in-progress (catalog complete, categorizing)`).

## Process

### 1. Failure catalog — enumerate concrete failures from real sources

Generate a catalog of **specific, concrete failure modes** the design must prevent. Quantity beats quality here, exactly as in DD's diverge step — but the source discipline is stricter: every entry must trace to a real, citable source, not invented hazards.

**Eligible sources**, in rough order of evidential weight:

- **Own incident journal / postmortems**: past production incidents in this or adjacent systems. Strongest signal — the failure has already happened in something like this environment.
- **Prior bug tickets / bug graveyard**: closed bugs from the issue tracker, especially those marked recurring or repeat-offender. Strong when the bug is well-documented and the analogy to the new system is tight.
- **Fears and near-misses**: failures the team has articulated as worries (in standups, design reviews, retros) but that haven't yet happened. Medium weight — the team's worry is a signal but unverified.
- **Competitor / industry failures**: public postmortems from peer companies (Cloudflare RFOs, AWS service health histories, vendor outage reports). Medium-to-weak weight depending on how comparable the system is; tag carefully.
- **Code-archaeology smells**: defensive comments, "do not change" blocks, TODOs naming specific failure modes the original author was worried about. Weak-to-medium signal — surfaces fears that survived into production but doesn't confirm they ever happened.

For each catalog entry, record:

- A **one-sentence failure description** in the form "[component] [action] [bad outcome]" — e.g., "The job runner retries a partial write and double-charges the customer."
- A **source tag** from the list above: `[own-incident]` / `[prior-bug]` / `[fear]` / `[competitor]` / `[code-smell]`. Place the tag inline at the start of the entry.
- A **source citation** — incident ID, ticket number, commit hash, URL, or a name like "raised by Alice in 2026-04 design review." A failure without a citation is not eligible for the catalog; either find the source or move it to a separate "speculative" list that does not drive the design.

Aim for **15–30 concrete entries**. Far fewer means the failure data isn't dense enough to justify FDD over RPI — consider pivoting. Far more usually means cluster-of-near-duplicates; collapse them in step 2's categorize pass rather than during enumeration.

**Done when...**
- [ ] At least 15 concrete failure entries are recorded
- [ ] Every entry has a one-sentence "[component] [action] [bad outcome]" description
- [ ] Every entry has exactly one source tag from the taxonomy (`[own-incident]` / `[prior-bug]` / `[fear]` / `[competitor]` / `[code-smell]`)
- [ ] Every entry has a citation (incident ID, ticket, hash, URL, or named human source)
- [ ] Entries that could not be cited were moved out of the catalog, not silently kept

### 2. Categorize — group by cause type, not by symptom

Group the catalog into **cause-type categories**, not symptom-type categories. The distinction matters: two failures that look different at the symptom layer (one is "duplicate charge," one is "missing audit row") may share the same cause (non-idempotent retry path) and therefore the same prevention sketch. The whole point of FDD is to make one design decision prevent many failures.

Start with these default cause-type buckets and add domain-specific ones as needed:

- **State / consistency**: race conditions, partial writes, non-idempotent retries, lost updates, stale caches, ordering violations.
- **Capacity / saturation**: thundering herd, queue depth runaway, memory leak, descriptor exhaustion, cost overrun.
- **Validation / trust-boundary**: missing input validation, type confusion, deserialization of untrusted data, auth bypass, privilege escalation.
- **Dependency / supply-chain**: upstream API change, library breaking-update, expired credential, vendor outage, DNS failure.
- **Observability / silent failure**: error swallowed, log missing context, metric stops firing, alert never wired up, dashboard reading from wrong source.
- **Human-factors / process**: ambiguous runbook, on-call handoff loss, undocumented assumption, configuration drift between environments.

For each catalog entry, assign **exactly one primary cause type** and optionally one secondary. If you can't pick a primary, the entry's description is too vague — return to step 1 and tighten it.

After categorizing, check:

- **Cluster density**: any cause type with 5+ entries is a heavyweight category — its prevention sketch (step 3) will pay back across many failures. Any cause type with exactly 1 entry is a one-off — its sketch may be cheaper to absorb into another, or to live as a one-off mitigation rather than a structural design choice.
- **Coverage gaps**: if you have a heavyweight `[fear]` category but zero `[own-incident]` or `[prior-bug]` entries in it, the team's worry may be miscalibrated — flag this for the human reviewer, but do not silently drop the category.

**Done when...**
- [ ] Every catalog entry has exactly one primary cause type assigned
- [ ] Categories are cause-type (mechanism), not symptom-type (observed effect)
- [ ] Heavyweight categories (5+ entries) and one-off categories (1 entry) are explicitly noted
- [ ] Any category that is entirely `[fear]` or `[competitor]` with no own-evidence is flagged for human review

### 3. Minimum-prevention sketch — derive the smallest design that prevents each category

For **each cause-type category** (not each individual failure), write a **minimum-prevention sketch**: the smallest, most local design element that would prevent every entry in that category. The discipline is *minimum* — resist scope creep into general-purpose abstractions. A sketch that prevents the cataloged failures and nothing more is the goal.

Each sketch must include:

- **Mechanism**: a one-paragraph description of the structural change. Concrete — name the API, data structure, invariant, or guardrail. Bad: "add resilience." Good: "wrap all retry sites in `withIdempotencyKey(operationID, fn)`, which records the keyed operation in a unique-indexed table before invoking fn."
- **Failure entries prevented**: list the catalog entry IDs this sketch covers. If a sketch claims to prevent an entry, that entry must trace back to the mechanism — no hand-waving.
- **Cost**: rough size estimate (lines, days, complexity bucket) and a one-line note on the ongoing maintenance burden.
- **Falsifiable hypothesis** (same form as DD step 4): *"If we adopt this sketch, we expect [observable] within [window]; counter-evidence would be [X]."* For prevention sketches, the observable is usually "category-N failures stop occurring in the failure log" or "the metric tracking category-N failures stays at zero across a release cycle."

**Sketches the team would have written from requirements anyway are not findings** — flag them as `[would-have-built-anyway]` and downweight them in the merge step. The FDD-specific value lives in sketches the failure catalog *forced into existence* — the ones a requirements-first design would have skipped.

**Done when...**
- [ ] Every cause-type category from step 2 has at least one minimum-prevention sketch
- [ ] Each sketch names a concrete mechanism (API, data structure, invariant, guardrail) — no vague "add resilience" entries
- [ ] Each sketch lists the catalog entry IDs it claims to prevent, and each listed entry can be traced back to the mechanism
- [ ] Each sketch has a cost estimate and a falsifiable hypothesis
- [ ] Sketches that would have existed without FDD are tagged `[would-have-built-anyway]`

### 4. Merge to feasible design — resolve conflicts, produce a coherent design

The collection of sketches from step 3 is not yet a design — each sketch was derived in isolation. Merging is where they interact: some compose cleanly, some are redundant, and some are incompatible.

For each pair of sketches, classify:

- **Compose**: the two sketches operate on different layers / surfaces and can both be implemented without modification. Keep both.
- **Subsume**: one sketch is a strict generalization of the other; the broader one's mechanism prevents everything the narrower one prevents. Keep the broader, discard the narrower (note the discard in the FDD record with the reason).
- **Conflict**: the two sketches require contradictory design choices — e.g., one requires a synchronous coordination point, the other requires fully async fire-and-forget. **This is a design decision** and must be resolved: either pick one with a one-line rationale, or — if the tradeoff is non-obvious and either choice is plausible — invoke [Divergent Design](divergent-design.md) as a sub-procedure (see "When to pivot" → DD). The failure modes from the two sketches become hard constraints in DD's diagnose step.

After pairwise reconciliation, produce a **feasible design record** with:

- **Design summary**: 2-4 sentences describing the merged structural choices.
- **Sketches retained**: list, with the failure entries each one covers.
- **Sketches discarded**: list with reason (subsume / conflict-lost / `[would-have-built-anyway]` deprioritized).
- **Conflicts resolved by DD**: pointer to the decision record (`docs/decisions/NNN-title.md`) if any conflict triggered the DD sub-procedure.
- **Coverage check**: every original catalog entry must map to either a retained sketch or be explicitly listed as "accepted residual risk" with a one-line reason. **No silent drops.**

**Done when...**
- [ ] Every pair of sketches has been classified as compose / subsume / conflict
- [ ] All conflicts have been resolved (either inline with a one-line rationale or via a DD sub-procedure with a linked decision record)
- [ ] The feasible design record exists with all required sections (summary, retained, discarded, DD pointer if any, coverage check)
- [ ] Every original catalog entry maps to a retained sketch OR is explicitly listed as accepted residual risk — no silent drops
- [ ] The design summary is concrete enough that the next step's RPI plan can name files and functions, not just goals

### 5. Reference into RPI plan — hand off, don't implement

FDD does not implement the design. Hand off to [`research-plan-implement.md`](research-plan-implement.md) with the FDD record as input:

- The RPI **research doc** cites the FDD record's failure catalog as the "Gotchas" / "Invariants" source — every retained sketch becomes an invariant the implementation must preserve.
- The RPI **plan doc** opens with `Research: docs/working/research-{topic}.md` (per RPI step 3), and the research doc in turn opens with a pointer back to `docs/working/fdd-{topic}.md`. This keeps the trail from "failure that motivated this work" → "research" → "plan" → "implementation commits" walkable in one direction.
- The RPI **test specification** must include at least one test case per retained sketch, framed as "verify that [failure entry F] cannot occur under [trigger conditions]." These tests are the falsifiable hypotheses from step 3 made executable.

Optionally, before triggering RPI, run [`what-if-analysis`](../skills/what-if-analysis.md) against the merged design (see the FDD → `what-if-analysis` compose path in "When to pivot"). The skill's output goes into `docs/reviews/what-if-analysis.md` and feeds back into the FDD record as either (a) new failure-catalog entries to absorb into a fresh prevention sketch, or (b) accepted residual risks the design knowingly does not prevent. Re-running steps 3-4 to incorporate the new entries is cheap; deferring the validation until after RPI implementation is expensive.

**Done when...**
- [ ] An RPI research doc exists that cites the FDD record by path
- [ ] Every retained sketch from step 4 appears as an invariant in the RPI research doc
- [ ] The RPI plan's test specification has at least one test per retained sketch, written as "[failure entry] cannot occur under [trigger]"
- [ ] If `what-if-analysis` was run, its findings have either been absorbed into the FDD record (new catalog entries → fresh sketch) or explicitly accepted as residual risk
- [ ] The FDD record's Task status is updated to `complete` and points to the RPI plan that now owns implementation

## When to skip or abbreviate

- **Single-failure motivation**: if the work is motivated by exactly one known failure mode, FDD is overkill — fix the failure via bug-diagnosis (one occurrence) or absorb it into an RPI loop (one invariant). FDD's value depends on a catalog of failures the design must jointly prevent.
- **Greenfield with no failure data**: if neither own-incident nor prior-bug entries are available, the catalog is fear-driven and likely miscalibrated. Run RPI or DD instead — once the system has some operating history, FDD becomes available retroactively.
- **Trivial scope**: a single-file change with one obvious failure mode doesn't need a catalog. Note the failure in the commit message and move on.
