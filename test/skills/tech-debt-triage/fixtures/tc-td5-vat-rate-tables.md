# Debt item: VAT rate lookup in the invoicing module

**Team:** Billing (Kestrel Workshop Supplies, B2B trade supplier) · **Written:** 2026-10-05 · **Raised by:** Ines R., billing engineer (joined 2026-08)

## What it is

`billing/legacy/vat_rates.py` returns the VAT rate for a product category and a
customer region. It is 780 lines of nested conditionals, with magic numbers, no
type hints, and variable names like `r2`, `flg` and `tmpcat`.

```python
def rate_for(cat, reg, flg=0):
    if reg == 1:
        if cat in (3, 4, 9, 14):
            r2 = 0.05
        elif cat == 7 and flg:
            r2 = 0.0
        else:
            r2 = 0.2
    elif reg == 2:
        # NI rules
        if cat in (3, 4):
            r2 = 0.05
        # ... 700 more lines ...
    return r2
```

Ines found it while reading the codebase during onboarding. Her note says it is
"the ugliest code in the repo, we should rewrite this before it bites us."

## History

`git log --format='%ad %s' --date=short billing/legacy/vat_rates.py`:

```
2024-03-14 Update cat 14 to reduced rate
2023-11-02 Add region 4
2023-01-20 Initial import from old invoicing system
```

- No incidents have ever been traced to this file.
- Table-driven tests cover every category and region combination (412 cases). They
  were generated from the finance team's rate sheet and are re-checked against it
  every quarter by finance.
- Rates change only when the law changes. Finance has no rate changes planned or
  announced.
- Nothing else in the codebase imports from `billing/legacy/` except the invoice
  builder's single call to `rate_for()`.

## Proposed fix

Rewrite it as a data file of rates plus a 40-line lookup, and re-verify against the
412 test cases. Estimated at 6 to 8 engineer-days, including finance sign-off on the
new data file.

## Team context

The billing team has four engineers. The Q4 priority is a customer-facing
self-service invoice portal, which does not touch VAT calculation.

Should we fix this?
