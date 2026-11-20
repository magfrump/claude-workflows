## Tech Debt Triage: Hand-ordered discount rule chain in checkout

**Location:** `checkout/pricing/discounts.py`, `apply_discounts()` (640 lines, 74 branches); sole caller is the checkout service
**Nature:** Structural. Promotion precedence and stacking are implicit in `if`/`elif` order and in shared mutable state (`total_off` read by `_gold_bonus`). None of it is declared or documented.
**Cost of Deferral:** `+1 pricing incident per ~2 months`. Four incidents fell between 2026-03-12 and 2026-09-08, with gaps of 51, 56 and 73 days. Each campaign change is a fresh chance to misplace a branch, and the file changes almost weekly (49 of the last 52 weeks).
**Failure Cost:** `High × High`. Incidents recur every couple of months. Each one is a silent mispricing on the money path at about 1,900 req/min peak, and it runs until someone notices. Observed losses were $4.1k–$18.4k plus refund labour and a paused campaign. The same failure during holiday peak would cost more.

### Carrying Cost: High
Almost every week someone edits the file. They have to reason about the precedence of 74 branches that nobody has written down, and only about 30 of those branches have tests. The cost is already visible: four incidents in six months, each post-incident review naming "hand-ordered branch precedence" as a contributing factor, and failure modes that are exactly what this structure predicts (reordering, guard bypass, order-dependent bonus, stale branches). Every new campaign adds cognitive load and bug risk.

### Fix Cost
- **Scope:** Localized. One module is replaced by a rule table plus an evaluator. The public signature is kept and there is a single caller.
- **Effort:** Days. The estimate is 4–5 engineer-days, but I'd add a margin for one part it leaves out (see Risk).
- **Risk:** Medium. Characterisation tests over real baskets lock in *current* behaviour, and current behaviour includes known-wrong precedence. Someone outside engineering (product or finance) has to decide the intended stacking rules for cases where today's behaviour is accidental, and that decision isn't in the 4–5 day estimate.
- **Incremental?** Partially. The cutover is one change, but the risk can be staged. Build the rule table, run it in shadow mode alongside the existing function, log any disagreements, and switch only when the diff is clean or every difference is an intended fix. At 1,900 req/min, a few days of shadow traffic covers far more baskets than last quarter's replay.

### Urgency Triggers
- **Holiday sale branches (due 2026-11-02): this trigger has already passed.** The write-up is dated 2026-10-05 and today is 2026-11-19, so the holiday branches have presumably been added to the existing chain and may be live now. Peak traffic (Black Friday/Cyber Monday, around Nov 27–30) is imminent. That raises the failure cost now, and it also makes a production cutover in the next ~2 weeks risky. If checkout has a holiday change freeze, it applies here.
- **Ongoing:** every campaign add or retire is a trigger. At almost one per week, the debt is continuously "due".
- **Knowledge risk:** the precedence lives in people's heads. If whoever understands the current ordering rotates off the team, carrying cost rises sharply.

### Recommendation

**Recommendation:** Fix now

Carrying cost is high, failure cost is severe and has been demonstrated four times, and the fix is localized and cheap (about a week) with no competing deadline. This is the clearest fix-now case the framework allows. One adjustment comes from the date: the planned window before the holiday branches has already closed. Start immediately on the work that carries no production risk: characterisation tests, a written precedence and stacking spec signed off by product or finance, and the rule-table implementation running in shadow mode. Do the actual cutover after the holiday peak (or freeze) ends. For now, review every holiday-sale branch change to this file against the four known failure patterns, especially guard placement and expiry checks.

Because the fix spans more than one file and its precedence semantics are unclear, it should go through the research-plan-implement workflow (`workflows/research-plan-implement.md`), using this triage as the input to the research phase.
