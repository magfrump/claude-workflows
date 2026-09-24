# Debt item: discount rule evaluation in checkout

**Team:** Checkout (Tallowfield Goods, online retail) · **Written:** 2026-10-05 · **Raised by:** Priya N., checkout on-call lead

## What it is

`checkout/pricing/discounts.py` decides which promotions apply to a basket. Every
checkout request calls `apply_discounts()`, about 1,900 requests per minute at peak.
Promotions are encoded as branches in one 640-line function. Each new campaign adds
another `elif`, and precedence between promotions depends on the order of the branches.

```python
def apply_discounts(basket, customer, now):
    total_off = Decimal("0")
    if customer.is_staff and not basket.has_gift_card:
        total_off += basket.subtotal * Decimal("0.20")
    elif basket.promo_code == "AUTUMN15" and now < AUTUMN_END:
        total_off += basket.subtotal * Decimal("0.15")
    elif basket.promo_code and basket.promo_code.startswith("REF-"):
        total_off += min(basket.subtotal * Decimal("0.10"), Decimal("25"))
    # ... 71 more branches ...
    if basket.subtotal > FREE_SHIPPING_MIN and not _shipping_already_discounted(basket):
        total_off += basket.shipping
    if loyalty_tier(customer) == "gold":
        total_off += _gold_bonus(basket, total_off)   # reads total_off, so order matters
    return min(total_off, basket.subtotal + basket.shipping)
```

## History

- 214 commits over the file's life. It was touched in 49 of the last 52 weeks,
  almost always to add or retire a campaign.
- There are unit tests for about 30 of the 74 branches. Nobody has written down the
  intended precedence order.

## Incidents traced to this file

| ID | Date | Summary | Cost |
|---|---|---|---|
| INC-2231 | 2026-03-12 | Staff discount stacked with AUTUMN15 after a branch was reordered | ~$18,400 in over-discounting before rollback |
| INC-2270 | 2026-05-02 | Gold bonus computed on a total that already included free shipping | 6 hours of manual refunds and adjustments |
| INC-2298 | 2026-06-27 | New referral branch placed above the gift-card guard, so gift cards were discounted | Campaign paused for 2 days |
| INC-2340 | 2026-09-08 | Expired campaign branch left in place, still applied to one SKU family | ~$4,100 over-discounted |

Each post-incident review lists "hand-ordered branch precedence in discounts.py" as a
contributing factor.

## Proposed fix

Replace the branch chain with a table of promotion rules. Each rule has an explicit
priority and stacking policy. Keep the public signature of `apply_discounts()`.
Estimated at 4 to 5 engineer-days, including characterisation tests over last quarter's
real baskets. Only the checkout service calls it.

## Team context

The checkout team has five engineers. There is no competing deadline this month. The
next large campaign, the holiday sale, has its branches due on 2026-11-02.

Should we fix this?
