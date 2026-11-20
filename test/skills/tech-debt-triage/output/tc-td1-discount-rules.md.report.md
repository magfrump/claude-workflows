## Tech Debt Triage: Hand-ordered discount precedence in `apply_discounts()`

**Location:** `checkout/pricing/discounts.py` (`apply_discounts()`, 640 lines, 74 branches)
**Nature:** Structural. Business rules (precedence and stacking) are encoded only in the order of `if/elif` branches, with no written specification and partial test coverage.
**Cost of Deferral:** `+1 hand-ordered branch per week`. The file was touched in 49 of the last 52 weeks, and each new branch adds precedence interactions with all existing ones. Incidents are running at about 1 per 7 weeks.
**Failure Cost:** `High × Med`. There have been four incidents in about six months. That is a realised rate, not speculation. Each one cost money or caused operational disruption: roughly $22.5k over-discounted in total, 6 hours of manual refunds, and a campaign paused for 2 days. A failure during peak traffic (about 1,900 req/min) costs more than the past incidents did.

### Carrying Cost: High
This is not ergonomic debt. It is actively producing defects, and all four post-incident reviews name the same root cause. Every campaign change requires an engineer to reason correctly about where a branch sits relative to 70+ others. They have to do this without a precedence spec and with tests covering only about 30 of 74 branches. The `total_off` dependency in `_gold_bonus` means order matters even outside the `elif` chain, which is hidden complexity that looks simple. The file changes almost weekly, so the team pays this cost constantly.

### Fix Cost
- **Scope:** Localized. One module, the public signature is preserved, and the checkout service is the only caller.
- **Effort:** Days. The 4–5 day estimate is plausible for the mechanical work. Budget extra time to settle intended precedence, because characterisation tests will capture *current* behaviour, including any latent bugs. Someone with product or pricing authority has to rule on the cases where current and intended behaviour differ.
- **Risk:** Medium. A subtle stacking or precedence change could mis-price live orders. Characterisation tests over real baskets reduce this risk, and so would a shadow run that compares old and new engine outputs on live traffic before cutover.
- **Incremental?** Partly. The table and characterisation tests can be built and shadow-run alongside the existing function. The final cutover is a single switch, and it can sit behind a flag for instant rollback.

### Urgency Triggers
- **Holiday sale (branches were due 2026-11-02): already passed.** The write-up is dated 2026-10-05 and today is 2026-11-20. The window to fix this *before* holiday branches went in has closed. Those branches are presumably in the chain now and about to run through peak (Black Friday 2026-11-27 / Cyber Monday 2026-11-30).
- **Peak-season change freeze.** If the team has one, cutover must wait until it lifts. Even without a freeze, swapping pricing logic during the highest-traffic week is poor timing.
- **Ongoing campaign cadence.** Every weekly campaign change remains another chance for a precedence error until the fix lands.
- **Team-context staleness.** "No competing deadline this month" was true in October. Check whether it still holds.

### Recommendation

**Recommendation:** Fix now

Carrying cost is high, failure cost is realised and recurring, and the fix is localized and modest relative to one incident's cost: about 5 days versus about $18k for INC-2231 alone. Starting now means starting the work now, not cutting over during peak. Write the precedence spec and characterisation tests now, including coverage of the newly added holiday branches. Build the rule table and shadow-run it against live traffic through the sale. Cut over after peak, behind a flag. Until then, require a second reviewer on any `discounts.py` change and add tests for each holiday branch.

The fix touches more than one file (rules table, engine, tests, shadow harness) and needs a precedence decision, so it is non-trivial. Hand it to the research-plan-implement workflow (`workflows/research-plan-implement.md`) and use this triage as input to the research phase.
