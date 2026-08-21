# Plan: skill-text changes from the mfc-pipeline-e8 false-negative trace

**Source evidence:** trace of the 15 FNs in
`runs/review-arms/crb/offline-work-50/results/claude-opus-4-5-20251101/evaluations.json`
against the surviving run artifacts in `/workspace/external/crb-eval/*/docs/reviews/`
(session 2026-08-21). Bug labels below: KC=keycloak-PR36880, SE=sentry-greptile-PR5,
GR=grafana-PR79265, DG=discourse-graphite-PR4, CC=cal_com-PR11059.

**Scope note:** the two no-critics cells (keycloak: dispatch prohibited; sentry: cost
ceiling after Stage 1) are benchmark-harness artifacts, out of scope here. The levers
below address the misses that occurred inside healthy pipeline runs, plus the merge/
synthesis behaviors that would still have lost findings even in healthy cells.

---

## Lever 1 — Merge semantics: most-severe-wins must be annotation-union

**Target:** `~/.claude/skills/code-review/SKILL.md`, §"Merging replicate verdicts
(most-severe-wins)" (currently lines 440–491).

**Failure it fixes:** SE4 (r3 found the analytics-before-flag bug in a placement note +
escalation note; merge carried the cluster as bare "Verified" and dropped both), DG1
(r1 and r3 both attached "does not establish the value is validated as a URL" to the
Verified claim; merge dropped both caveats). Note DG1 caveats were in 2 of 3 reps —
the loss is not a minority-report problem, it's that the merge discards *annotations*
wholesale while merging *verdicts*.

**Root cause in the text:** step 2 says "Carry the evidence and reasoning from the
replicate that assigned the winning verdict." Everything a non-winning replicate wrote —
scope caveats, placement notes, escalation notes — is structurally deleted. The doc's
own rationale ("the observed failure mode is under-calling") argues *for* preserving
this material; the current mechanics contradict the stated spirit.

**Proposed changes:**

1. Rewrite step 2's carry rule: most-severe-wins selects the **verdict and headline
   evidence**; annotations merge by **union**, never by winner. Add a seventh per-claim
   field to the merged schema:
   `**Replicate annotations:** r1: <caveat/note or —> · r2: … · r3: …`
   carrying every scope caveat, placement note, "does not establish X" disclaimer, and
   escalation note verbatim (or a tight quote), attributed by replicate. Explicit rule:
   *an annotation is never dropped because its replicate lost the verdict merge, and
   never dropped because the winning verdict is Verified.* A Verified claim with a
   caveat is a different object than a clean Verified.
2. Add a merged-report section `## Escalations` that aggregates all replicate
   escalation notes (the "route to security-reviewer / test-strategy" items) into one
   list with locations. Downstream contract: Stage 2 critic prompts already embed the
   merged summary — extend the embed (step 6 of prompt assembly, ~line 257) to include
   this section so escalations actually reach the named critics.
3. **Dead-letter rule:** if Stage 2 is skipped, short-circuited, or degraded for any
   reason (budget, gate, dispatch failure), the `## Escalations` section and every
   caveat-bearing Verified claim MUST be force-surfaced in the rubric — escalations as
   🟡 rows tagged `Severity: Unrouted-Escalation`, caveats in the claim's rubric row.
   Rationale to cite in-text: sentry r3 routed four escalations to critics that never
   ran; the channel was a dead letter and a found bug died in it.
4. Update the merge's self-description: it currently calls itself "mechanical collation,
   not analysis." Keep that — annotation union is *more* mechanical than winner-takes-
   evidence, which requires deciding what the winner's "reasoning" includes.

**Acceptance check:** re-run the merge step on the surviving sentry replicate reports
(`external/crb-eval/sentry-greptile-PR5/docs/reviews/code-fact-check-report-r{1,2,3}.md`);
the merged output must contain r3's placement note on the preprod analytics cluster and
all four escalation notes. Same for discourse r1/r3's URL-validation caveat on Claim 23.
Add a bats case to the merge-format suite asserting the `**Replicate annotations:**`
field exists on every multi-replicate cluster.

---

## Lever 2 — Verified verdicts must state the verified property

**Targets:** `~/.claude/skills/code-fact-check/SKILL.md` step 3 (verdict definitions)
and output-format rules; `~/.claude/skills/code-review/SKILL.md` §"Confirmed Good is a
claim, not an output" (~line 1122).

**Failure it fixes:** DG2 (Claim 25 "Verified" checked message *shape*, never
targetOrigin semantics — then promoted to ✅ Confirmed Good, the pipeline's only
affirmative endorsement of the buggy behavior). KC1 (inline pass verified the guard
can't invoke V2 stubs, cleared the guard as Confirmed Good; never asked what happens
when the guard is false). Pattern: a Verified on a narrow property reads downstream as
an endorsement of the whole construct, actively suppressing critic suspicion.

**Root cause in the text:** the Verified verdict is defined as "Code behavior matches
the claim. Evidence confirms it." — no requirement to state *which reading* of the
claim was checked. The existing "How to handle ambiguity" section already gestures at
this ("if the claim is only true under a narrow reading, flag that") but has no
structural teeth: nothing forces the scope statement into a parseable field, so the
merge and the rubric can't preserve what was never captured.

**Proposed changes (code-fact-check):**

1. Add two mandatory bolded fields to every claim verdicted `Verified` or `Mostly
   accurate`:
   - `**Property verified:**` — one line, the exact property the evidence establishes
     (e.g. "sent message shape `{type, height}` matches receiver destructuring").
   - `**Not established:**` — adjacent properties a reasonable reader would assume the
     verdict covers but the evidence does not reach (e.g. "targetOrigin argument
     semantics; whether the browser delivers the message"). `—` is permitted but must
     be earned: writing `—` asserts the natural broad reading was fully checked.
2. Reframe the Verified definition: *Verified is a claim about a property, not about a
   line of code. The verdict endorses exactly the property stated; downstream
   consumers must not read it as clearance of the surrounding construct.*
3. Fold into the ambiguity section: when a claim admits a broader reading than what was
   checked, the narrow reading goes in `Property verified` and the residue goes in
   `Not established` — this replaces the current soft "flag that."

**Proposed changes (code-review):**

4. The Confirmed-Good cross-check gains one question per candidate row: *quote the
   underlying claim's `Property verified` line and state whether that property entails
   the safety being asserted by this row.* If it does not entail it, the row is not
   Confirmed Good — it is at most a Verified-narrow observation, and the gap
   (`Not established` content) is a candidate finding to hand to critics.
5. `Not established` content participates in Lever 1's annotation union — the two
   levers compose: fact-check captures the scope residue, the merge preserves it, the
   rubric surfaces it.

**Acceptance check:** replaying DG2's claim under the new fields, `Not established`
must contain the targetOrigin residue, and the Confirmed-Good cross-check must reject
the promotion. Format bats: `Property verified` present on every Verified/Mostly-
accurate claim.

---

## Lever 3 — Read complete syntactic units

**Targets:** `~/.claude/skills/code-fact-check/SKILL.md` "How to check each claim"
step 2 (Behavioral claims); `~/.claude/skills/code-review/SKILL.md` shared critic-brief
assembly (~line 230); optionally each critic skill's evidence rules.

**Failure it fixes:** CC1 (performance-reviewer's excerpt of the Salesforce refresh
block stops at line 99; the stale-token bug is at 101–108, in the same function), SE2
(the Verified detector-owner cluster's evidence quote begins at `detector.py:66`; the
bug is at `:64`, in the same `update()` method). Two independent cells, same shape:
analysis truncated at an excerpt boundary one line from the defect, with nothing
marking the truncation.

**Proposed changes:**

1. **Analysis rule (the substantive one):** before verdicting a claim or filing a
   finding about code inside a function/method, read the *entire enclosing unit* —
   from its signature to its final line — plus the flow of any value the analyzed
   lines produce to its first point of use. Wording to include: *bugs concentrate at
   the edges of the region you happened to excerpt; the excerpt that justified the
   finding is not the unit you were required to read.* Cite CC1/SE2 as the measured
   pattern (one-line-short truncation, twice, independently).
2. **Visibility rule (the cheap enforcement):** any evidence quote that truncates
   inside an enclosing unit must end with an explicit truncation marker naming the
   unread remainder: `(excerpt ends :99; enclosing getClient() continues to :108 —
   read: yes/no)`. A bare truncated quote is treated like an untagged paraphrase under
   the existing quoted-evidence-or-paraphrase rule — i.e., not allowed. This makes
   silent truncation auditable by the synthesis stage without re-reading the code.
3. Put rule 1 in code-fact-check (Behavioral claims bullet: strengthen "read the
   implementation end-to-end" — define end-to-end as the enclosing unit, explicitly
   including lines *after* the last line the claim cites) and in the shared critic
   brief so all Stage-2 critics inherit it once, rather than editing five critic
   skills. Rule 2 goes wherever evidence-quoting rules live (fact-check output rules;
   critic shared brief).

**Acceptance check:** the truncation-marker rule is grep-testable in bats (any fenced
quote whose end line ≠ a unit boundary must be followed by the marker is hard to test
mechanically — instead test the weaker invariant: reports must contain zero fenced
evidence quotes citing a `:N-M` range where a later finding-relevant sibling range in
the same function appears nowhere; practical proxy: spot-audit in the review-fix loop).
Primary validation is replay: CC1's refresh-block analysis under the new rule must
reach :101–108.

---

## Lever 4 — Provenance demotion: add evidence-gated lift channels

**Target:** `~/.claude/skills/code-review/SKILL.md` §"Unified Severity Mapping" +
§"Contextual critics are advisory" (~lines 1188–1227) + the Soundness-Contradiction
Channel as the design template.

**Why the rule exists (answer to "why does this exist at all?"):** documented in the
skill and decision 028/031 — the critics are the same model differing only by role
prompt, so cross-critic agreement is correlated, and the measured failure mode of
giving contextual critics blocking power was true-but-unwanted escalations (n≈5, one
waived by the human with the *most* convergence). The advisory rule is a guard against
unvalidated blocking authority, not a claim that contextual findings are unimportant.
So: don't abolish it — extend the skill's own existing pattern (evidence-gated lift,
per the Soundness-Contradiction Channel) with channels for the two observed loss modes.

**Failure it fixes:** DG4 (ERB `end if`: ui-visual rated it Critical, proposed a
one-command verification `ruby -c`, demoted to 🟢 because its sole critic is
contextual), DG5 (`i.content.scrub` nil crash: unanimous fact-check "highest-value
unresolved risk", verdict Unverifiable → mapped to 🟢 by the severity table). Both were
*found and correctly diagnosed*, then routed to the advisory bucket by provenance
rather than by evidence. Under the benchmark's 🔴/🟡-only export they scored as FNs;
under real use a 🟢 is ~70% never-actioned by the skill's own numbers.

**Proposed changes:**

1. **Executable-Defect Channel** (new, sibling to Soundness-Contradiction). Trigger,
   all parts required in the critic report itself: (a) the finding asserts a
   *deterministic* failure — syntax/parse error, guaranteed exception on a named
   plausible input, type-contract violation that cannot not fire; (b) the report names
   a concrete one-command or one-test verification (`ruby -c <file>`, a fixture test,
   a REPL one-liner); (c) the mechanism is quoted with `path:line`. On trigger: the
   orchestrator FIRST attempts the verification itself when the sandbox permits
   (Stage 3 gains a "run the cheap checks" step); on pass→confirmed, the finding maps
   by its native severity through the standard table *as if from a core critic*. If
   the sandbox cannot execute it, lift to 🟡 with `Severity: Unexecuted-Deterministic`
   — terminal at 🟡, mirroring the Soundness channel's ceiling, so blocking authority
   still requires execution or a human.
2. **Unverifiable is an evidence state, not a severity.** Amend the Unified Severity
   Mapping's Fact-Check column: `Unverifiable` maps to 🟢 *only when no replicate
   attached a High-severity failure mode*. An Unverifiable claim whose stated failure
   mode is a crash/data-loss/security consequence on plausible input maps to 🟡 with
   `Severity: Unverified-High-Risk`, carrying the "what would be needed to verify"
   line as its author note. Rationale to cite: DG5 — evidence-absence was read as
   low-severity; the two axes were conflated by the mapping table.
3. Both channels: lift-only (never demote a row already higher), excluded from
   escalation-corroboration counting, and logged in the rubric with the channel name —
   same bookkeeping discipline as the Soundness channel, so the new mechanisms stay
   auditable and falsifiable.

**Acceptance check:** replay DG4 and DG5 through the amended mapping: DG4 must land
🔴-or-🟡-pending-execution (and `ruby -c` in this repo's sandbox does run → 🔴); DG5
must land 🟡. Confirm no change to the routine case: a test-strategy "add coverage"
finding with no deterministic failure stays 🟢.

---

## Lever 5 — Security reviewer: classify every input source, sweep every primitive

**Target:** `~/.claude/skills/security-reviewer/SKILL.md`, §move 1 "Trace the trust
boundaries" + the Trust Boundary Map output requirement (~lines 109–357).

**Failure it fixes:** DG1 (Critical SSRF): the reviewer built a boundary map, analyzed
the `Kernel#open` command-injection primitive for two sibling paths (`import_remote`,
disqus.thor), and never applied it to the third and only unguarded call — because the
map classified `feed_polling_url` as admin-configured ⇒ trusted-enough. The user's
instinct is right that "site settings are untrusted" is over-specific; the general
versions of the two gaps:

**Proposed changes:**

1. **The boundary map must enumerate and classify every input *source*, with
   justification.** Extend the existing Trust Boundary Map spec: before drawing
   arrows, list each distinct source feeding the changed code — request data, DB
   fields, config/settings mutable at runtime, environment, filesystem, third-party
   responses, message payloads — one line each: `S3: SiteSetting.feed_polling_url —
   runtime-mutable by admin role → UNTRUSTED for SSRF/exec sinks (mutable-at-runtime
   rule), TRUSTED for availability`. Two standing classification rules to state in the
   skill (general, not Discourse-specific):
   - *Trust is per-consequence, not per-source.* A source can be trusted for one sink
     class and untrusted for another; the classification line must name the sink class
     it applies to. (DG1's map trusted the setting in general; for the fetch sink
     specifically that was the wrong grain.)
   - *Runtime-mutable ⇒ compromise-reachable.* Any value changeable through the
     application's own UI/API after deploy (settings, DB-backed config, feature
     params) is reachable by whoever compromises a session with that permission —
     including via the very vulnerabilities under review — and is classified untrusted
     toward high-consequence sinks (fetch/exec/deserialize/HTML). Code-constant and
     deploy-time values may stay trusted.
2. **Primitive sweep (completeness move).** New numbered cognitive move: when the
   analysis engages a dangerous primitive anywhere in the diff (`open`/fetch, exec,
   deserialize, raw SQL, HTML interpolation, path join), grep the diff scope for *all*
   occurrences of that primitive and emit a disposition table — every call site, its
   input source label (S1…Sn), guarded/unguarded, finding-or-cleared. An analyzed
   primitive with an undisposed sibling call site is an incomplete review by
   definition. This converts DG1's failure (right primitive, 2-of-3 call sites) into a
   mechanical omission the report format makes visible.

**Acceptance check:** replay on discourse-graphite-PR4: the source table must classify
`feed_polling_url` untrusted-toward-fetch under the runtime-mutable rule, and the
`Kernel#open` disposition table must contain `poll_feed.rb:32` as unguarded → the SSRF
finding forms. Regression guard: the per-consequence rule should *not* newly flag
benign uses of settings in non-dangerous sinks (check FP delta on the same cell's
existing findings).

---

## Sequencing and validation

1. Lever 2 before Lever 1 (the merge preserves fields that fact-check must first emit);
   Levers 3–5 independent. Suggested order: 2 → 1 → 4 → 5 → 3 (3 is lowest-confidence
   wording; validate by replay before formalizing bats).
2. Each lever's replay uses surviving artifacts in `/workspace/external/crb-eval/` —
   no new sweep needed for first-pass validation (per the no-big-compute-before-A8
   constraint).
3. Bats surface: extend the existing format suites (`test/skills/code-fact-check-format
   .bats`, merge-format suite) for the new mandatory fields; the behavioral rules
   (units, sweep) validate by replay + review-fix loop spot audit, not grep.
4. Expected FN coverage if all five land, against the 13 real misses: Lever 2 → KC1,
   DG2 (+feeds L1); Lever 1 → SE4, DG1(caveat path); Lever 4 → DG4, DG5; Lever 5 →
   DG1(formation path); Lever 3 → CC1, SE2; GR1 (synthesis integration) is partially
   addressed by L1's annotation union carrying Claim 6's mechanism next to Claim 7's
   consequence, but full credit needs a synthesis-stage "compose fragments citing the
   same lines" rule — flagged as an open question, not planned here. Charter expansion
   for implicit behavioral claims (KC2, KC3, DG3, CC1's claim-side) was discussed and
   deliberately deferred by the user in favor of these four levers; CC1/SE2 are
   covered via Lever 3's read-the-unit rule instead.

---

## Replay log (implementation session 2026-08-21)

### Lever 2 — implemented
Discovered on implementation: the workspace skill (unlike the Aug 7 baked image the e8
run used) already carries the per-claim `Scope:` field and Confirmed-Good provenance
rule 5. Lever 2 therefore narrowed to: (i) Verified verdict definition now binds the
verdict to exactly the Scope-named property, never the construct; (ii) ambiguity rule
forces narrow readings into the Scope field (prose flags don't survive merge); (iii)
Scope residue guidance names the three observed residue classes (argument semantics
beyond those checked / behavior when the verified condition is false / unread sibling
call sites); (iv) code-review Confirmed-Good cross-check gains the entailment test and
routes narrowed/dropped-row residue to Coverage and Escalations.
- **DG2 replay:** Claim 25's residue class is "argument semantics beyond the ones
  checked" (targetOrigin) — now a mandatory does-not-establish entry; the entailment
  test's own example text rejects the "sender/receiver contract matches" ✅ promotion.
  Blocked at both stages. PASS.
- **KC1 replay:** the Confirmed-Good row "guard cannot invoke V2 stubs" fails
  entailment (cannot-throw does not entail guard-correct); residue class
  "behavior when the verified condition is false" forces the orphaned-cleanup question
  into the record. PASS.
- **Negative control:** grafana Claim 22 (CountDevices SQL-window comment, genuinely
  correct) — covers clause matches a row asserting exactly that property; entailment
  holds; no over-fire. PASS.
- Bats: code-fact-check format/edge suites + 5 code-review suites, 0 failures.

### Lever 4 — implemented
New Executable-Defect Channel (sibling to Soundness-Contradiction, same house shape:
three-part trigger, run-verification-first, lift-only, terminal-🟡 without execution,
excluded from escalation corroboration) + Stage-3 executable-defect cross-check +
"Unverifiable is an evidence state, not a severity" mapping rule (blocking-grade
failure mode → 🟡 Unverified-High-Risk). The two "only path" statements now enumerate
both evidence-gated exits.
- **DG4 replay:** trigger fires (deterministic parse error, `ruby -c` named,
  mechanism quoted). Ruby absent in this sandbox too → unexecutable path → 🟡
  `Unexecuted-Deterministic` naming the blocker. Was 🟢; now exports as a benchmark
  comment. PASS.
- **DG5 replay:** Unverifiable with a named crash-on-plausible-input failure mode →
  🟡 `Unverified-High-Risk` via the mapping rule. PASS.
- **Negative controls:** a test-strategy add-coverage finding names no deterministic
  failure → no trigger, stays 🟢; sentry's W3C-spec-URL Unverifiable claims carry no
  blocking-grade failure mode → stay 🟢. PASS.
- Bats: new suite test/skills/code-review-executable-defect.bats (9 tests); two
  soundness-crosscheck tests updated for the deliberate one-path → two-paths contract
  change; 96 ok across all code-review suites.

### Lever 5 — implemented
security-reviewer move #1 gains per-consequence trust + runtime-mutable ⇒
compromise-reachable classification rules; Trust Boundary Map gains the S-labeled
source table; new move #12 (primitive sweep) + required Primitive sweep report
section. Replay by construction — the skill's examples encode the DG1 case; negative
control: untrusted classification scoped to high-consequence sinks only.

### Lever 3 — implemented
Fact-check behavioral-claim rule now defines end-to-end as the complete enclosing
unit including lines after the last cited line, plus produced-value flow to first
use; truncation-marker rule added to the evidence discipline (untagged truncated
quote = untagged paraphrase). code-review goal preamble (shared prefix part 1) must
carry the complete-unit reading rule so every replicate and critic inherits it.
- **CC1 replay:** the refresh-block analysis (`:75-99`) sits inside getClient()
  ending `:108`; the rule compels reading `:100-108`, where the stale
  `credentialKey.access_token`/`instance_url` wiring is; the truncation marker makes
  the old stop-at-:99 excerpt inadmissible without a `— read` continuation. PASS.
- **SE2 replay:** the detector-owner quote (`:66-79`) sits inside update(); the
  enclosing unit starts at `:60`, forcing `:64` (the `detector_type` wrong-key line)
  into the read. PASS.
- **Anti-noise:** rule binds only when verdicting/filing on code *inside* a unit;
  whole-file or structural claims unaffected.

### Lever 1 — implemented + replayed on real replicates
Merge rewritten: most-severe-wins selects the verdict only; annotations merge by union
into the `Replicate annotations` field (dedup on substance, one line per distinct
residue); `## Escalations` aggregation (routing contract, embedded in critic prompts
via shared-prefix part 6); dead-letter rule force-surfaces unrouted escalations as 🟡
`Unrouted-Escalation` rows (terminal, non-corroborating).
- **Acceptance replay** (subagent re-merged the surviving sentry + discourse replicate
  reports under the new text; outputs in session scratchpad):
  - A. Sentry preprod-analytics cluster: r3's placement note (the SE4 bug, verbatim)
    + r1's independent corroboration both survive on the ×3-Verified cluster. PASS.
  - B. All four r3 escalations (incl. "Analytics fires before authorization") land in
    `## Escalations` with routing attribution. PASS.
  - C. Discourse feed_polling_url cluster: all three URL-validation/scheme residues
    survive (the DG1 SSRF driver). PASS.
  - Counterfactual: old winner-takes-evidence merge drops every one of A/B/C items.
  - D. Anti-noise: annotations field populated on ~55-70% of clusters (not "mostly
    none" as the plan guessed) because replicates rarely word residues identically —
    but entries are one-line and attributed; acceptance target revised to "one line
    per distinct residue", now stated in the rule.
- **7 wording ambiguities** surfaced by the replay, all fixed in text: same-verdict
  tie-break (most-specific Scope, then lowest replicate number); finest-granularity
  claim emission with `(compound)` verdict annotation; substance-dedup of identical
  residues; escalation dedup with multi-replicate attribution; Out-of-scope bullets
  naming a critic count as escalations, addressee-less entries go to `orchestrator`;
  unbolded `Commit:` accepted on replicate reports (merged header stays parsed-bold);
  severity-order compound interaction handled by the granularity rule.
