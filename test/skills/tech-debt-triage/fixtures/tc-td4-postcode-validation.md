# Debt item: postcode validation copied into three handlers

**Team:** Fulfilment (Elderbrook Pantry, grocery delivery) · **Written:** 2026-10-05 · **Raised by:** Marcus O., fulfilment engineer

## What it is

Three request handlers in `fulfilment/delivery/` each carry their own copy of the
postcode check: `create_slot.py`, `update_address.py` and `quote_delivery.py`. The
copies have drifted a little.

```python
# create_slot.py
if not re.fullmatch(r"[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}", pc.upper()):
    raise InvalidPostcode(pc)

# update_address.py
if not re.fullmatch(r"[A-Z]{1,2}[0-9][A-Z0-9]?[0-9][A-Z]{2}", pc.upper().replace(" ", "")):
    raise InvalidPostcode(pc)

# quote_delivery.py
pc = pc.strip().upper()
if len(pc) < 5 or not re.fullmatch(r"[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}", pc):
    return QuoteResponse.error("postcode")
```

## History

- The three handlers see a handful of commits a quarter between them, mostly for
  unrelated delivery-slot logic.
- One minor bug in 2026-04: `quote_delivery` rejected postcodes with a trailing
  space that the other two accepted. About 30 customers saw an error on the quote
  page before a hotfix went out the same day.
- Each handler has its own tests, and all three pass.

## Proposed fix

Extract a single `normalise_postcode()` into `fulfilment/delivery/address.py`, call
it from all three handlers, and move the tests next to it. Estimated at 2 to 3
hours.

## Planned work in the same area

Ticket FUL-1187 is scheduled for the sprint starting 2026-10-19. It moves all three
handlers from the old `webargs` request parsing to the team's standard `pydantic`
request models. Every line of the three validation blocks above sits inside the
request-parsing code that FUL-1187 rewrites. The postcode rules themselves are not
expected to change, and no new handler that validates postcodes is on the roadmap.

## Team context

The fulfilment team has six engineers and a normal feature load.

Should we fix this?
