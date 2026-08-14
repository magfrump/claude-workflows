# E6 ultrareview cost ledger

**Resolution 2026-08-14 (author):** the 2026-08-14 sweep's three runs consumed the
account's free-tier allotment (3 free ultrareviews on Pro/Max), so **billed cost = $0**
and no per-run figure exists to record. Account usage views are unlabeled and
confounded, so paid-run costs are not measurable there either; the only handles for a
future paid run are the launch dialog's estimate and bill deltas. The ~$5-25/run figure
from docs remains an UNVERIFIED list-price placeholder.

**All further ultra runs bill real usage credits** (free tier exhausted) - including
any secdeps or deploy re-run.

| instance | date | billed cost | free-run? | session status |
|---|---|---|---|---|
| mfc-csp | 2026-08-14 | $0 | yes (1/3) | nonzero exit; bugs.json intact (4 of 5 verified findings persisted) |
| mfc-deploy | 2026-08-14 | $0 | yes (2/3) | nonzero exit; empty payload - abstention vs failure unresolved |
| mfc-secdeps | 2026-08-14 | $0 | yes (3/3) | crashed before producing findings |
