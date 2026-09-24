---
name: sql-migration-review
description: >
  Review a database schema migration for production risk before it ships:
  table locks held during ALTERs, full-table rewrites, missing or unsafe
  rollback (down) migrations, backfills without batching, and index builds that
  block writes. Produces a findings list with a severity per finding and a
  safe-rollout recommendation (expand/contract, batch size, online index
  build). Use when the user asks to "review this migration", "is this
  migration safe", "will this lock the table", or when a diff adds a file under
  migrations/.
---

# SQL Migration Review

For each statement in the migration:

1. **Lock check** — which lock does it take, and for how long on a table of this size?
2. **Rewrite check** — does it rewrite the table (type change, default on old Postgres)?
3. **Rollback check** — is there a down migration, and does it lose data?
4. **Backfill check** — is any UPDATE unbatched?
5. **Index check** — is the index built concurrently?

Output: `## Finding N` sections, each with `**Severity:** Critical|High|Medium|Low`,
then a **Safe rollout** section.
