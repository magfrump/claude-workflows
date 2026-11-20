## Tech Debt Triage: VAT rate lookup in the invoicing module

**Location:** `billing/legacy/vat_rates.py` (`rate_for()`), called only from the invoice builder
**Nature:** Readability/structural debt: 780 lines of nested conditionals, magic numbers, opaque names (`r2`, `flg`, `tmpcat`), no type hints. Behaviour is correct and fully tested.
**Cost of Deferral:** `+0 (inert)`. Three commits in ~3.7 years, none since 2024-03-14. One call site, nothing else imports from `billing/legacy/`. No rate changes planned, so neither the debt nor the fix gets bigger with time.
**Failure Cost:** `Low × Med`. This is a tax-compliance path, so a wrong rate would mean under- or over-charged VAT, correctable with credit notes and amended returns. Probability is low because every category × region combination (412 cases) is tested against finance's rate sheet and re-checked quarterly, and no incident has ever been traced here.

### Carrying Cost: Low
The code is ugly but inert. Nobody has needed to change it in over two and a half years, and the quarterly finance check of the full test table catches drift. Day-to-day friction is close to zero because the Q4 portal work and other billing work don't go near it. The real cost is cognitive, and it appears only at edit time: whoever handles the next legal rate change has to work out what `reg == 2`, `cat 7` and `flg` mean in 780 lines. The exhaustive tests limit how much that costs.

### Fix Cost
- **Scope:** Localized. One file, one call site, no API change needed if `rate_for()` keeps its signature.
- **Effort:** Days. The team estimates 6–8 engineer-days, including finance sign-off on the new data file.
- **Risk:** Low–medium. The 412 tests make a mistranscribed rate unlikely to ship. Still, rewriting correct tax code adds risk to a file that currently carries almost none, and it pulls finance into a sign-off cycle.
- **Incremental?** Partly. Region by region is possible, but finance sign-off pushes toward a single coordinated cutover.

**Opportunity cost:** The billing team is four engineers, and 6–8 days is roughly 2 engineer-weeks out of a quarter whose priority is the self-service invoice portal.

### Urgency Triggers
- **A VAT rate or rule change in law.** None is announced. When one comes, someone has to edit this file anyway, so that is the cheapest moment to do the data-file rewrite, with finance already engaged.
- **A new region or category scheme.** The last one was region 4 in 2023-11. Each new nested branch makes the file harder to edit.
- **A new consumer of VAT logic**, e.g. if the portal or a later feature needs to show rates, explain them, or calculate them outside the invoice builder. That would end the single-call-site isolation.
- **None of these is imminent today.**

### Recommendation

**Recommendation:** Carry intentionally

The code looks bad, but every signal that matters here is reassuring: zero incidents, exhaustive tests re-verified quarterly by finance, no changes since 2024, a single call site, and no planned rate changes. Spending 6–8 engineer-days plus finance's time on it now would cut into the Q4 portal priority to "fix" correct, tested, untouched code, and the rewrite itself would be the riskiest thing to happen to this file in years. Ines's instinct makes sense for someone new to the repo, but "ugliest code" doesn't mean "about to bite us." The tests are what stop it biting, and they are already in place.

Two cheap things are worth doing now, at hours of effort with no formal plan needed:
1. **Add a short header comment or docstring** that maps the region codes (1, 2 = NI, …, 4), the category codes, and what `flg` means. This removes most of the edit-time cognitive cost for whoever handles the next change.
2. **Record a revisit trigger** next to the file or in the backlog: *"Do the data-file rewrite when the next statutory VAT change requires editing this file, or if a second caller of VAT logic appears."* That ties the 6–8 days to the moment finance is already involved and the file has to change anyway.
