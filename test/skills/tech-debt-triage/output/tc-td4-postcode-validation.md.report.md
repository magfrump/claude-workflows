## Tech Debt Triage: Postcode validation copied into three handlers

**Location:** `fulfilment/delivery/create_slot.py`, `update_address.py`, `quote_delivery.py`
**Nature:** Duplication with drift (three slightly different copies of one validation rule)
**Cost of Deferral:** `+0 — inert`. The postcode rules aren't expected to change, no new postcode-validating handler is on the roadmap, and the three files see only a handful of commits a quarter. The copies don't spread, and the fix doesn't get harder over time.
**Failure Cost:** Not material. The one incident affected about 30 customers on a quote page and was hotfixed the same day.

### Carrying Cost: Low

The duplication is real and has already caused one bug. But the files are rarely touched, the rules are stable, and each copy has passing tests. The cost is mostly the risk of more drift, and the code excerpt shows drift is still present:

- **Leading/trailing whitespace.** `create_slot` uppercases but doesn't strip, so `"SW1A 1AA "` fails `fullmatch`. `quote_delivery` strips, and `update_address` removes all spaces, so both accept it. This is the same class of bug as the April incident. It looks like the hotfix added `.strip()` to `quote_delivery`, which moved the inconsistency to `create_slot` instead of removing it. That holds unless something upstream of `create_slot` already strips input.
- **Internal spaces.** `update_address` removes every space, so it accepts `"SW1A  1AA"` (double space) and odd spacing such as `"S W1A1AA"`. The other two reject these.
- **Error paths differ.** Two handlers raise `InvalidPostcode`; `quote_delivery` returns `QuoteResponse.error("postcode")`. Its `len(pc) < 5` check is redundant because the regex's minimum match is already 5 characters.

### Fix Cost
- **Scope:** Localized. One new helper in `address.py`, three call sites, and the tests moved.
- **Effort:** Hours. The 2–3 hour estimate is plausible. Reconciling the differing whitespace behaviour may need a short product decision on which inputs to accept.
- **Risk:** Low. The worst case is a behaviour change at the edges, for example `create_slot` starting to accept padded input or `update_address` starting to reject odd spacing. Each handler's existing tests, plus a few new edge-case tests on the shared helper, would catch this.
- **Incremental?** Yes. Each handler can be switched over separately. Each must keep its own error response (raise vs. `QuoteResponse.error`), so the shared helper should validate and normalise, and leave the response to the caller.

### Urgency Triggers
- **FUL-1187 (webargs → pydantic).** This rewrites every line of all three validation blocks. It's not an escalation, but it is the natural moment to fix the duplication, because a standalone fix done before it would be largely rewritten.
- No other triggers: the rules are stable, no new handlers are planned, and nothing suggests a scaling or compliance problem.

**Check first: the dates have moved.** This write-up is from 2026-10-05, and FUL-1187 was scheduled for the sprint starting 2026-10-19. That sprint started a month ago. Before acting, check FUL-1187's status:
- **Not started or in progress:** do the consolidation as part of it.
- **Already merged:** see whether it consolidated the validation. If it carried three copies over into three pydantic models, the debt still exists in a new form. The fix is still a few hours of work and can be done the next time anyone touches these models.

### Recommendation

**Recommendation:** Fix opportunistically

The carrying cost is low and the debt doesn't compound (`+0 — inert`), so it doesn't justify its own ticket. The fix is cheap, though, and FUL-1187 already rewrites exactly these lines. The best approach is to fold it into that ticket as a single shared pydantic type or validator in `fulfilment/delivery/address.py` (for example an `Annotated[str, AfterValidator(normalise_postcode)]`), used by all three request models. That avoids doing the work twice and settles the whitespace rules once.

One small exception: if FUL-1187 is still weeks away, spend ten minutes confirming whether `create_slot` really rejects postcodes with surrounding whitespace in production. If it does, a one-line `.strip()` there closes a repeat of the April bug now, without waiting for the larger change.
