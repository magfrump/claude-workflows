# Decision brief: card-not-present fraud rules for Pellam Pay

**Decision.** Pellam Pay is choosing how to build the rule set that screens
card-not-present payments for its 2,400 online merchants. Options: (a) a
hand-written rules engine of about 180 rules, (b) a vendor's pre-built rule
pack configured to our thresholds, or (c) a gradient-boosted scoring model
trained on the last twelve months of labelled chargebacks.

**Who is deciding.** The risk engineering team of four, with sign-off from the
Chief Risk Officer.

**Context.** Chargeback losses were 0.41% of volume last year. The attack mix
has turned over three times in the past twelve months: card-testing bursts in
Q1, account-takeover via reused passwords in Q2, and refund abuse through
marketplace sellers from Q3 onward. Each wave took roughly six weeks to show
up in labelled chargebacks. Two of our largest merchants are launching
buy-now-pay-later and gift-card products next quarter, which we have not seen
attacked yet.

**How we are framing it.** We want to pick the option that best fits the fraud
we see today. The plan is a six-week build, a back-test against last year's
labelled data, and then a handover of the finished rules to the operations
team, which will run them as-is. Risk engineering moves to the merchant
onboarding project straight after handover, and there is no budget line for
re-tuning or retraining after launch.

**Criteria.**

1. Back-tested catch rate on the last twelve months of chargebacks.
2. False-decline rate on the same data.
3. Explainability of each decline to merchants.
4. Build effort within six weeks.

**Constraints.** The card scheme requires our fraud rate under 0.5% by the end
of next quarter. Operations has no engineers who can write or change rules.
