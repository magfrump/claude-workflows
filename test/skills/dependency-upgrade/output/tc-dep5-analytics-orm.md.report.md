## Dependency Upgrade Evaluation: strata-orm 1.8.2 → 3.2.0

### Summary
**Recommendation:** Upgrade soon, but **not in one change**. A direct 1.8.2 → 3.2.0 jump breaks the deploy path. The upgrade has to go through 2.x in two separately deployed phases.
**Breaking change impact:** Moderate. The code changes are none to trivial. The work is a one-time, in-place rewrite of the production migration-metadata table, and it has to happen in a fixed order.
**Estimated effort:** Hours of work spread over at least two deploys. Calendar time is days, because every database (prod, staging, CI, local) must finish phase 1 before phase 2 ships.
**Risk:** High as a single jump. Medium with the staged plan below.
**Audit state:** Unverified. No shell or network access was available, so no audit was run.

### Motivation
1.x stopped receiving fixes in June 2026. This is an end-of-life upgrade, not a CVE response. You should plan it now rather than treat it as an emergency. The release notes describe no 3.x feature the project currently needs: async sessions and column comments are unused.

### Why a single jump breaks
The release notes combine into a hard ordering constraint:

1. Production `_strata_meta` uses the **1.x layout**, with 41 migrations recorded.
2. **3.0.0** removed the 1.x-layout reader. 3.x reads and writes only the 2.x layout.
3. **3.0.0** also removed `strata migrate-meta`, the only documented tool that converts 1.x → 2.x.
4. **2.0.0** introduced `migrate-meta` and reads both layouts.

So once 3.2.0 is installed, nothing in the installed package can read or convert the production metadata. `deploy/release.sh` runs `strata upgrade head` against production on every deploy, so the first 3.2.0 deploy would run 3.x against a table it cannot read.

The release notes **do not say** what 3.x does in that case. It might fail with an error. It might also treat `_strata_meta` as empty and try to re-apply all 41 migrations against a live schema. The second case could fail partway through or, for non-idempotent migrations, damage data. This is undocumented behaviour, so plan as if it is the dangerous case.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| 3.0.0: 1.x `_strata_meta` reader removed; `strata migrate-meta` removed | `deploy/release.sh` (`strata upgrade head` on prod); `_strata_meta` in **every** database (prod, staging, CI, developer machines) | Upgrade to 2.x first and run `strata migrate-meta` against every database. Upgrade to 3.2.0 only after that is confirmed everywhere. |
| 3.0.0: `strata.connect()` requires a URL string; dict no longer accepted | `metrics_hub/db.py`: `strata.connect(settings.DATABASE_URL)` | Probably no change. The name suggests a URL string, but `settings` was not provided, so I can't confirm the type. Check that `settings.DATABASE_URL` is a `str` in every environment's config, not a dict assembled from parts. |

### Breaking Changes That Don't Affect This Project
- **2.0.0: `__tablename__` → `__table__`.** `models.py` already uses `__table__`, which has been supported as an alias since 1.6. No change needed. The only call sites provided are the three files above, so no other model uses `__tablename__`.
- **2.4.0, 3.1.0, 3.2.0** are additive (faster autogenerate, `async_sessionmaker`, `Column(comment=...)`). They break nothing. `strata.sessionmaker`, `Column`, `Integer`, `String`, `DateTime`, `primary_key=` and `index=` all appear unchanged.

### Transitive Effects
- The release notes mention no changes to the minimum Python version or dependencies. That absence is not confirmation. Before each phase, check the `Requires-Python` and dependency metadata for 2.4.0 and 3.2.0 on PyPI against `requires-python = ">=3.12"`.
- None others identified from the material provided.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `pip-audit` (or equivalent) on the 1.8.2 and 3.2.0 lockfiles | — | — | Unverified. Recommended pre-merge check. |
| `pip install strata-orm==2.4.0` / `==3.2.0` in a Python 3.12 env | — | — | Unverified. Recommended pre-merge check. |
| Test suite under 2.4.0 and under 3.2.0 | — | — | Unverified. Recommended pre-merge check. |
| `strata migrate-meta` against a restored copy of the prod DB | — | — | Unverified. Recommended pre-merge check (essential). |
| `python -c "from metrics_hub.config import settings; print(type(settings.DATABASE_URL))"` (adjust import) in each env | — | — | Unverified. Recommended pre-merge check. |

Nothing above was executed. Every statement about behaviour comes from reading the release notes you provided.

### Risk Factors
- **The production metadata rewrite is in place and probably one-way.** 2.x reads both layouts. Nothing says 1.x can read the 2.x layout, so assume it can't. Once `migrate-meta` has run, rolling the code back to 1.8.2 also requires restoring `_strata_meta` from a backup.
- **Checksum backfill (assumption to verify).** The 2.x layout records a checksum per applied migration. The notes don't say how `migrate-meta` computes checksums for the 41 historical migrations. If any migration file was edited after it was applied, a mismatch could appear now or on a later `upgrade head`. Running `migrate-meta` against a prod restore will reveal this.
- **`migrate-meta` idempotency is undocumented.** Don't add it to `release.sh` for every deploy. Run it once per database, deliberately, and then verify.
- **Mixed-layout window.** If 2.x applies a *new* migration before `migrate-meta` has run, it's unspecified which layout the new row is written in. Avoid this by running `migrate-meta` before shipping any new migrations under 2.x.
- **Stragglers.** Any database still in 1.x layout when 3.2.0 lands (a forgotten staging DB, CI fixtures, developer machines) hits the same failure as prod, and `migrate-meta` is no longer available to fix it. You would have to temporarily install 2.4.0 to repair it.
- **Detectability.** The test suite probably won't catch the metadata problem unless tests build the DB from a 1.x-layout fixture. The real test is a dry run against a restored prod snapshot.

### Rollback Plan (precondition — complete before starting Migration Plan)

The database engine wasn't stated. The commands below assume PostgreSQL. Substitute your engine's equivalents and fill in the placeholders before you rehearse.

**Phase 1 rollback (2.4.0 → 1.8.2, after `migrate-meta` has run):**
```
# Taken BEFORE migrate-meta (part of Migration Plan step 3):
pg_dump "$DATABASE_URL" --table=_strata_meta --data-only --format=custom -f strata_meta_1x_backup.dump
pg_dump "$DATABASE_URL" --table=_strata_meta --schema-only -f strata_meta_1x_schema.sql

# Rollback:
git checkout <pre-upgrade-commit> -- pyproject.toml <lockfile>
pip install -e .            # or your project's install command
psql "$DATABASE_URL" -c 'DROP TABLE _strata_meta;'
psql "$DATABASE_URL" -f strata_meta_1x_schema.sql
pg_restore --data-only --table=_strata_meta -d "$DATABASE_URL" strata_meta_1x_backup.dump
```

**Phase 2 rollback (3.2.0 → 2.4.0):**
```
git checkout <phase-1-commit> -- pyproject.toml <lockfile> metrics_hub/db.py
pip install -e .
# No metadata change: 2.x reads the 2.x layout that 3.x writes.
```
This is safe only if 3.x has not changed the 2.x layout. The release notes say 3.x "reads and writes only the 2.x layout", which supports that, but confirm it in the rehearsal.

**Verification step** (run after each rollback; must pass):
```
strata upgrade head    # expect: no pending migrations, 41 recorded, exit 0
<smoke test that creates and reads an Event row via Session>
```
This fails if the metadata wasn't restored correctly or the installed version can't read it.

**Rehearsal status:** [ ] Rehearsed on {YYYY-MM-DD} on branch `{scratch-branch-name}` against a restored prod snapshot; verification step passed. Evidence: {evidence-file path or verbatim output}. *Not done: no execution environment was available for this evaluation.*

### Migration Plan

**Phase 1: 1.8.2 → 2.4.0 (latest 2.x in the release notes; check PyPI for a newer 2.x patch)**
1. Confirm `settings.DATABASE_URL` is a string in every environment. This costs nothing now and removes the phase 2 code risk.
2. Pin `strata-orm==2.4.0`. Run the test suite. No code changes should be needed.
3. Restore a recent prod snapshot to a scratch database. Back up `_strata_meta` there, then run `strata migrate-meta`. Verify that 41 rows are present, that `strata upgrade head` reports nothing pending, and that there are no checksum errors. Rehearse the phase 1 rollback against the same scratch DB.
4. Deploy 2.4.0 to production. `release.sh` stays unchanged, because 2.x reads the 1.x layout.
5. In a maintenance step before any new migration ships: back up `_strata_meta` on prod (the commands above), run `strata migrate-meta` once, then run `strata upgrade head` and confirm nothing is pending.
6. Repeat step 5 for staging, CI fixtures and seed DBs. Tell developers to run `strata migrate-meta` on their local DBs. Keep a checklist; every database must be ticked off.

**Phase 2: 2.4.0 → 3.2.0 (separate change, after phase 1 is complete everywhere)**
7. Pin `strata-orm==3.2.0`. Run the tests against a DB in 2.x layout, ideally the scratch prod restore from step 3.
8. On that scratch DB, confirm `strata upgrade head` under 3.2.0 reports nothing pending. Rehearse the phase 2 rollback.
9. Optional safety net: add a pre-flight to `release.sh` that aborts if `_strata_meta` is still in 1.x layout. How to detect the layout depends on the schema, which the notes don't describe; one example would be checking for the checksum column.
10. Deploy 3.2.0.

The security-reviewer skill isn't required. The upgrade isn't CVE-driven and doesn't touch crypto or auth. Run it anyway if you want a check on the `release.sh` change in step 9.

### If Not Upgrading
Staying on 1.8.2 means running an unpatched ORM that touches the production database. If you defer, do at least **phase 1 soon**. 2.4.0 is drop-in for this codebase, and finishing `migrate-meta` while 2.x still exists keeps the route to 3.x open. If a future release drops 2.x from support or yanks it, the only documented path from the 1.x metadata layout disappears with it.
