## Tech Debt Triage: VAT rate lookup in the invoicing module

**Location:** `billing/legacy/vat_rates.py` (`rate_for()`), called once from the invoice builder
**Nature:** Structural / readability. 780 lines of nested conditionals with magic numbers, no type hints, and opaque names (`r2`, `flg`, `tmpcat`).
**Cost of Deferral:** `+0 — inert`. The file has 3 commits in ~3.5 years, the last in March 2024. It has one caller, nothing else imports from `billing/legacy/`, and no rate changes are planned.
**Failure Cost:** `Low × Med`. Wrong VAT on B2B invoices would mean credit notes, re-issued invoices and possibly a tax correction. The probability is low because the code isn't changing, and 412 table-driven cases are re-checked against finance's rate sheet every quarter.

### Carrying Cost: Low
The code is unpleasant to read, but almost nobody has to read it. Day-to-day friction is close to zero because it changes only when tax law changes, and that has happened twice since import. It has never caused an incident. The tests are unusually strong: every category × region combination is covered and finance revalidates them quarterly. Any behavioural regression would be caught, whether it came from an edit or a rewrite. The real cost is cognitive load at the rare moment someone has to edit it. For example, the meaning of `flg` for category 7 and the integer region and category codes are undocumented. That cost only arises at an edit, not continuously.

### Fix Cost
- **Scope:** Localized. One file and one call site, with a clean boundary.
- **Effort:** Days. 6–8 engineer-days including finance sign-off, which is about 10% of the team's capacity for a quarter where the self-service portal is the priority.
- **Risk:** Medium. Transcribing 780 lines of branching into a data file can introduce errors in edge cases like `flg`. The 412 tests reduce this risk a lot, but the rewrite is still the most likely way this file would cause an incident in the near term.
- **Incremental?** Mostly no. The code could technically be migrated region by region, but finance sign-off on the data file makes it effectively one coordinated change.

### Urgency Triggers
- **The next legislated VAT rate change**, or a new region or category. This is the natural time to fix it: the file must be touched, finance sign-off is needed anyway, and the marginal cost of converting to a data file is lowest then. Nothing is currently announced.
- **Northern Ireland (region 2) rule changes**, e.g. further Windsor Framework adjustments. This is a specific case of the trigger above, worth watching because those rules are the most likely to diverge.
- **Knowledge loss.** No one on the team appears to own the semantics of `flg` and the code mappings. If the team turns over before the next rate change, a future editor faces the full cognitive load.
- No imminent trigger exists today.

### Recommendation

**Recommendation:** Carry intentionally

The file is ugly but inert. It has a single caller, has never caused an incident, has stayed unchanged for over two years, and has test coverage that finance verifies every quarter. Spending 6–8 days of a four-person team's Q4 on it would take capacity from the portal and add more short-term risk than leaving it alone. Ines's instinct about the code quality is right, but the evidence doesn't support "before it bites us": the safeguards that would catch it biting are already in place.

Two low-cost actions are worth taking now:
1. **Record the decision** with the revisit condition: *"Convert to a data-driven table as part of the next VAT rate change, region addition, or category addition."* The fix then happens when the file has to be opened anyway.
2. **Optionally add a short header comment** (an hour or two, done in place) mapping the region and category codes and explaining `flg`. This removes most of the cognitive-load risk for whoever makes the next legal change, without touching behaviour.
