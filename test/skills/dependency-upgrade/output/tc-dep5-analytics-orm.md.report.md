## Dependency Upgrade Evaluation: strata-orm 1.8.2 → 3.2.0

### Summary
**Recommendation:** Upgrade soon
**Breaking change impact:** Moderate
**Estimated effort:** hours of hands-on work, split across two separate deploys
**Risk:** Medium if staged through 2.x; High if done as the single requested change
**Audit state:** Unverified

**Do not do this as one change.** Upgrade soon, but in two stages: first to 2.4.0, then run `strata migrate-meta`, then move to 3.2.0. A direct jump from 1.8.2 to 3.2.0 would leave production unable to read its own migration history. 3.x cannot read the 1.x `_strata_meta` layout, and 3.x also removed the only tool that converts it. That tool exists only in 2.x. The code changes are trivial. Nearly all the risk is in the migration-metadata conversion against the production database.

### Motivation
1.x stopped receiving fixes in June 2026, so the project is running an unpatched ORM. The request names no CVE, so this is an end-of-life upgrade. It should be planned, not done as an emergency. Nothing in 2.4–3.2 is needed today. Async sessions and column comments are optional extras. The case for upgrading is staying on a supported line, not getting new features.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| 3.0.0: reader for the 1.x `_strata_meta` layout removed. 3.x reads and writes only the 2.x layout. | Production `_strata_meta` (41 applied migrations, 1.x layout); `deploy/release.sh` (`strata upgrade head` runs on every deploy against prod) | Before any 3.x code reaches production, the table must be rewritten to the 2.x layout. If the first 3.x deploy runs `strata upgrade head` against a 1.x-layout table, the release notes don't say what happens. At best it fails the deploy. At worst it misreads the history, for example by treating the 41 migrations as unapplied and trying to re-run them. |
| 3.0.0: `strata migrate-meta` removed | Your only path off the 1.x layout | Run `strata migrate-meta` while on 2.x. It cannot be done from 3.x, so a single-step upgrade is impossible. |
| 2.0.0: new `_strata_meta` layout with per-migration checksums; `migrate-meta` rewrites it **in place** | Production `_strata_meta` | This is a one-way data change, and the release notes don't say 1.8.2 can read the 2.x layout. Back up the table before running it (see Rollback Plan). |

### Breaking Changes That Don't Affect This Project
- **3.0.0 `strata.connect()` requires a URL string; dicts no longer accepted.** `db.py` passes `settings.DATABASE_URL`, which is presumably a string. `settings` isn't shown, so confirm it isn't a dict or a URL object.
- **2.0.0 `Model.__tablename__` renamed to `Model.__table__`.** `models.py` already uses `__table__`, which has been supported since 1.6.
- `Column`, `Integer`, `String`, `DateTime`, `Model` and `sessionmaker` have no listed changes.
- 2.4.0 (autogenerate speedup), 3.1.0 (async sessions) and 3.2.0 (column comments) are additive only.

### Transitive Effects
- None identified. The release notes list no new runtime minimum, dropped Python version, or new dependency. The project requires Python ≥3.12, and the notes give no reason to expect a conflict. The resolved dependency tree is unverified (see below).
- The `strata` CLI in `deploy/release.sh` must come from the same environment as the pinned package, so the CLI version moves together with the pin at each stage.

### Execution Evidence

Nothing could be run in this session: no repository, shell, network or database access.

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `pip install "strata-orm==2.4.0"` (resolve/install check) | — | — | Unverified — recommended pre-merge check |
| `pip install "strata-orm==3.2.0"` (resolve/install check) | — | — | Unverified — recommended pre-merge check |
| `pip-audit` (or equivalent) against each stage's lockfile | — | — | Unverified — recommended pre-merge check |
| Project test suite on 2.4.0 and on 3.2.0 | — | — | Unverified — recommended pre-merge check |
| `strata migrate-meta` against a copy of the production DB | — | — | Unverified — recommended pre-merge check |
| `strata upgrade head` on 3.2.0 against the migrated copy (expect: no migrations applied, no errors) | — | — | Unverified — recommended pre-merge check |
| Search of the repo for other `strata` imports or CLI calls beyond the three files given | — | — | Unverified. This evaluation relies on the request's statement that these are all the call sites. |

### Risk Factors
- **Wrong migration history in production (High if staged incorrectly).** `release.sh` runs against prod on every deploy. Any deploy carrying 3.x before `migrate-meta` has completed hits the unreadable 1.x layout.
- **One-way metadata rewrite.** After `migrate-meta`, going back to 1.8.2 is only safe if the table is restored from backup. The release notes don't say 1.x tolerates the 2.x layout.
- **Checksum mismatches (unknown).** 2.x records a checksum for each applied migration. If `migrate-meta` computes checksums from the current migration files, any of the 41 historical migrations edited after being applied could cause checksum errors later in 3.x. The notes don't say how checksums are derived. Check this on the production-copy rehearsal.
- **New migrations during the transition.** The release notes don't say which layout 2.x writes when it applies a new migration to a 1.x-layout table. Freeze new schema migrations from the 2.4.0 deploy until `migrate-meta` is done and verified.
- **Unknown `migrate-meta` behaviour on re-run.** The notes don't say whether it is idempotent. Run it once, manually, not from `release.sh`.
- **Detectability.** The ORM code surface is tiny (one model, connect plus sessionmaker), so tests should catch API breakage immediately. Metadata problems only show up when `strata upgrade head` runs against a real database. Unit tests won't catch them, which is why the rehearsal has to use a copy of production.

### Rollback Plan (precondition — complete before starting Migration Plan)

The database engine isn't stated. The DB commands below assume PostgreSQL. Substitute your engine's equivalents.

**Exact rollback commands:**
```
# Stage 1 rollback (2.4.0 → 1.8.2), BEFORE migrate-meta has run:
git checkout <pre-upgrade-commit> -- pyproject.toml <lockfile>
pip install -e .            # or your project's exact install command
# deploy; release.sh's `strata upgrade head` now runs on 1.8.2 against the untouched 1.x table

# Stage 1 rollback AFTER migrate-meta has run (restore 1.x-layout table first):
psql "$DATABASE_URL" -c 'DROP TABLE _strata_meta;'
psql "$DATABASE_URL" -f strata_meta_1x_backup.sql
git checkout <pre-upgrade-commit> -- pyproject.toml <lockfile>
pip install -e .

# Stage 2 rollback (3.2.0 → 2.4.0); 2.x reads the 2.x layout, so no data restore:
git checkout <stage-1-commit> -- pyproject.toml <lockfile> metrics_hub/
pip install -e .
```

Required backup, taken immediately before `migrate-meta`:
```
pg_dump "$DATABASE_URL" --table=_strata_meta --clean --if-exists > strata_meta_1x_backup.sql
```

**Verification step** (run after rollback; must pass to confirm rollback worked):
1. `strata upgrade head` exits 0 and applies no migrations.
2. `SELECT count(*) FROM _strata_meta;` reflects all 41 applied migrations.
3. The app boots and a test that inserts and queries an `Event` through `Session` passes.

This would fail if the lockfile didn't revert, or if 1.8.2 were left facing a 2.x-layout table.

**Rehearsal status:** [ ] Not rehearsed. Rehearse both stages, including the post-`migrate-meta` restore, on a scratch branch against a restored copy of the production database. Record the date, branch and captured verification output here before starting.

### Migration Plan

**Stage 1 — 1.8.2 → 2.4.0 (own release)**
1. Freeze new schema migrations until Stage 1 is complete.
2. Pin `strata-orm==2.4.0` in `pyproject.toml` and regenerate the lockfile. No code changes are expected: `__table__` and the URL-string `connect()` are already in place.
3. Run the test suite. Deploy. `release.sh` runs `strata upgrade head` on 2.4.0, which still reads the 1.x layout.
4. Take the `_strata_meta` backup (see Rollback Plan).
5. Manually run `strata migrate-meta` once against production, after rehearsing it on the prod copy.
6. Verify: `strata upgrade head` on 2.4.0 is a no-op, the 41 migrations are recorded, and the app is healthy. Let it soak for at least one normal deploy cycle.

**Stage 2 — 2.4.0 → 3.2.0 (separate release, only after Stage 1 is verified)**
7. Gate: confirm production `_strata_meta` is in the 2.x layout. Consider adding a pre-flight check in `release.sh` that aborts if it isn't.
8. Confirm `settings.DATABASE_URL` is a plain string, as 3.0 requires.
9. Pin `strata-orm==3.2.0`, regenerate the lockfile, run tests, and run `strata upgrade head` against the migrated prod copy. Expect a no-op with no checksum errors.
10. Deploy. Watch the `release.sh` output and app health.
11. Optional later: adopt `async_sessionmaker()` or `Column(comment=...)` only if needed. They are not part of this upgrade.

A security-reviewer pass is not required. The upgrade isn't CVE-driven and doesn't touch crypto or auth packages.

### If Not Upgrading
Staying on 1.8.2 means running an ORM that has received no fixes since June 2026, with no patch path if a vulnerability is disclosed. If the 2.x line also reaches end-of-life before you move, the `migrate-meta` step may become harder to run on a supported version. The single bridging tool exists only in 2.x, so don't let the gap grow.
