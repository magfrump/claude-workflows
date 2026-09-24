# Change request CR-2291: Move the nightly settlement batch from 01:00 to 03:00

**Team:** Payments Core, Harrowgate Pay · **Risk class:** Low (schedule change only)

## Problem

The nightly settlement batch (`settle-nightly`) runs at 01:00 UTC. It reads the
day's captured card payments, nets them per merchant, and writes one row per
merchant into the `merchant_settlement` table, plus the payout file we send to
our sponsor bank. The batch takes 40-55 minutes.

Since the database team moved the full backup of the payments cluster to
00:30-02:30 UTC last month, the batch runs against a cluster under heavy read
load. Its runtime has grown to 70-95 minutes and twice it has timed out and
needed a manual rerun by the on-call engineer.

## Proposal

Move `settle-nightly` to 03:00 UTC, after the backup window closes. No code
changes: only the cron expression in the scheduler config changes.

## Why 03:00 is safe

- The sponsor bank's payout file cutoff is 06:00 UTC. A 03:00 start with a
  95-minute worst case finishes by 04:35, leaving 85 minutes of margin.
- Card captures after midnight belong to the next settlement day, so moving
  the start time does not change which payments fall into which day.
- Merchants see settlement on their dashboard from 07:00 UTC, as today.

## Environment

For reviewers unfamiliar with the overnight schedule, the jobs that touch the
payments cluster between midnight and 08:00 UTC are:

| Time (UTC) | Job | Owner |
|---|---|---|
| 00:30-02:30 | Full backup of the payments cluster | Database team |
| 01:00 | `settle-nightly` (this CR moves it to 03:00) | Payments Core |
| 02:15 | `warehouse-sync`: copies `merchant_settlement` and `payouts` into the finance warehouse | Data Platform |
| 04:00 | `fraud-model-refresh` | Risk |
| 06:00 | Sponsor bank payout file cutoff | External |
| 07:00 | Merchant dashboard settlement view refresh | Merchant Experience |

## Rollout

Change the cron expression on a Tuesday, watch the first run, and keep the
on-call engineer's manual-rerun runbook unchanged. Rolling back means
restoring the old cron expression.

## Testing

We ran the batch at 03:00 on a staging copy of production for five nights.
Runtime was 41-52 minutes each night, back to the pre-backup-change range. The
payout file was byte-identical to the one produced by a 01:00 run over the same
data.

## Out of scope

Moving the backup window itself. The database team has explained why 00:30 is
the only slot that works for the replica rotation, and we are not asking them
to change it.
