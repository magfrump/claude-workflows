# Proposal: Launch a free tier of Ledgerline

**Owner:** Growth · **Stakeholders:** Product, Engineering, Finance · **Decision by:** end of month

## Summary

Ledgerline is bookkeeping software for small agencies. We have 2,100 paying
accounts on two plans (Studio at $39/month, Agency at $99/month) and no free
option beyond a 14-day trial. Trial-to-paid conversion is healthy at 22%, but
trial starts have been flat for three quarters.

We propose a permanent free tier, **Ledgerline Solo**: one user, up to 30
invoices a month, no bank feeds. The goal is 40,000 Solo sign-ups in the first
six months, converting to paid at 4% as their businesses grow.

## Why now

Two competitors launched free tiers this year. Our win/loss interviews show
prospects now expect to "just start using it" without a trial clock.

## What Solo users get

- Invoicing, expenses and a basic profit-and-loss report.
- The same product and the same in-app experience as paying customers,
  including the help centre and the in-app **Contact us** button, because we do
  not want Solo to feel like a second-class product.
- Upgrade prompts when they hit the invoice cap or try to connect a bank.

## Financial model

| Item | Month 6 |
|---|---|
| Solo accounts | 40,000 |
| Solo accounts converted to Studio (4%) | 1,600 |
| New MRR from conversions | $62,400 |
| Hosting cost per Solo account | $0.35/month |
| Total Solo hosting cost | $14,000/month |

Conversions pay for hosting more than four times over by month 6.

## Engineering work

- A plan entitlement for Solo (invoice cap, no bank feeds): 2 sprints.
- Sign-up flow without a card: 1 sprint.
- Load testing: our infrastructure is sized for 25x current accounts, so 42,000
  accounts total is within capacity.

## Team today

- Engineering: 11
- Customer support: 4 agents, handling about 900 conversations a month from
  paying accounts with a median first response of 3 hours.
- Growth and marketing: 3

## Launch plan

1. Soft launch to the waitlist (about 1,800 people).
2. Public launch with a Product Hunt post and partner newsletter swaps in week 3.
3. Review conversion at day 90.

## Risks

- **Cannibalisation:** some Studio customers may downgrade to Solo. Studio
  customers average 70 invoices a month, well over the Solo cap, so we expect
  this to be small.
- **Abuse:** automated sign-ups. Mitigated with email verification and a
  CAPTCHA.
- **Conversion below 4%:** at 2% conversion, new MRR is $31,200 and still
  covers hosting twice over.
