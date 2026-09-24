---
name: migration-safety-check
description: >
  Check a database migration for production safety before it is deployed:
  locks taken by ALTER TABLE, table rewrites, missing down migrations, large
  unbatched backfills, and non-concurrent index creation. Outputs findings with
  a severity each and a recommended rollout (expand/contract, batching,
  concurrent index). Use when the user asks "is this migration safe", "check
  this migration", "will this lock the table", or when a diff touches
  migrations/.
---

# Migration Safety Check

Walk every statement in the migration and check:

1. Locks — what lock, held how long, on how big a table?
2. Rewrites — does the statement rewrite the table?
3. Rollback — is there a down migration; does it lose data?
4. Backfills — are UPDATEs batched?
5. Indexes — created concurrently?

Output: `## Finding N` sections with `**Severity:** Critical|High|Medium|Low`,
followed by a **Recommended rollout** section.
