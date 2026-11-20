## Tech Debt Triage: Postcode validation copied into three handlers

**Location:** `fulfilment/delivery/create_slot.py`, `update_address.py`, `quote_delivery.py`
**Nature:** Duplication with behavioural drift (structural)
**Cost of Deferral:** `+0 — inert`. The postcode rules aren't expected to change, no new postcode-validating handler is planned, and the files get only a handful of commits a quarter. Carrying it longer costs nothing extra.

### Carrying Cost: Medium

The copies have already caused one defect: in 2026-04, about 30 customers hit a quote-page error. The drift is still live. Reading the three snippets:

- **`create_slot`** does `pc.upper()` with no `strip()`. It rejects `"SW1A 1AA "` (trailing space) and `"SW1A  1AA"` (double space).
- **`quote_delivery`** strips first, so it accepts the trailing space. Its `len(pc) < 5` check is redundant, because the regex can't match fewer than 5 characters.
- **`update_address`** removes all spaces, so it accepts the trailing space, the double space and odd spacing like `"SW 1A1AA"`.

So a customer can get a quote and save an address, then fail at slot creation. That is the same class of bug as April, just moved to a different handler. Day-to-day friction is low because the code is small and rarely touched. The cost is in user-facing inconsistency, not developer time.

The error contracts also differ. Two handlers raise `InvalidPostcode`, while `quote_delivery` returns `QuoteResponse.error("postcode")`. Any shared helper has to leave that difference at the call site.

### Fix Cost
- **Scope:** Localized: one new helper plus three call sites, all in `fulfilment/delivery/`.
- **Effort:** Hours. The 2–3h estimate is reasonable. Add a short decision on which behaviour is canonical. I'd suggest the most lenient one: strip, uppercase, collapse internal whitespace, then validate. Rejecting valid input is the failure you've actually seen.
- **Risk:** Low. Choosing the lenient behaviour could accept slightly odd input in `create_slot` that it rejects today. That's unlikely to matter, and each handler already has tests.
- **Incremental?** Yes. It can land one handler at a time, but it's small enough to do in one change.

### Urgency Triggers
- **FUL-1187 (webargs → pydantic)** rewrites every line of all three validation blocks. Doing the extraction separately beforehand means the work gets rewritten a few weeks later. In pydantic, the natural fix is a shared annotated type, e.g. `Postcode = Annotated[str, AfterValidator(normalise_postcode)]`, used by all three request models. That is less code than the migration would otherwise produce.
- No other triggers: the rules aren't changing, no new handlers are planned, and there's no security or compliance exposure. I left Failure Cost blank because a postcode rejection is a recoverable user error, not an incident.

### Recommendation

**Recommendation:** Fix opportunistically

Do it as part of FUL-1187, not as a separate task. FUL-1187 touches exactly these lines, and a shared pydantic `Postcode` type is the clean way to write the new models anyway, so the extra effort is close to zero. A standalone fix now would be thrown away during the rewrite.

**Check FUL-1187's status first.** This write-up is dated 2026-10-05 and that sprint started 2026-10-19, so it's already a month in:
- **Still in progress:** add the shared type to its scope.
- **Already merged:** check whether it kept three validators. If it did, the 2–3h extraction is now a standalone task on fresh code. Still worth doing, ideally next time someone is in the area.
- **Slipped indefinitely:** at minimum, add `.strip()` to `create_slot` now. It's a one-line fix for the live trailing-space inconsistency.
