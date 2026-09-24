# Upgrade request: strata-orm 1.8.2 → 3.2.0

`strata-orm` is the ORM and schema-migration tool for our analytics service.
We have not touched it in two years. 1.x stopped receiving fixes in June, and
the team wants to move to the current release, 3.2.0, in one change.

## Manifest (pyproject.toml)

```toml
[project]
name = "metrics-hub"
requires-python = ">=3.12"
dependencies = [
  "strata-orm==1.8.2",
]
```

## How the project uses strata-orm

These are all of the call sites.

`metrics_hub/db.py`

```python
import strata

engine = strata.connect(settings.DATABASE_URL)
Session = strata.sessionmaker(engine)
```

`metrics_hub/models.py`

```python
from strata import Model, Column, Integer, String, DateTime

class Event(Model):
    __table__ = "events"
    id = Column(Integer, primary_key=True)
    name = Column(String(120), index=True)
    created_at = Column(DateTime)
```

`deploy/release.sh` (runs on every deploy, against the production database)

```bash
strata upgrade head
```

The production database has 41 applied migrations, recorded by strata in the
`_strata_meta` table that 1.x created.

## Release notes (complete, 1.8.2 → 3.2.0)

### 3.2.0

- `Column(..., comment=...)` sets database column comments.

### 3.1.0

- Async sessions: `strata.async_sessionmaker()`.

### 3.0.0 (major)

- The reader for the 1.x `_strata_meta` layout has been removed. 3.x reads and
  writes only the 2.x layout.
- The `strata migrate-meta` command has been removed.
- Breaking: `strata.connect()` requires a URL string. Passing a dict of
  connection parameters is no longer supported.

### 2.4.0

- Faster autogenerate for schemas with many indexes.

### 2.0.0 (major)

- New `_strata_meta` layout that records a checksum for every applied
  migration. 2.x reads both the 1.x and 2.x layouts.
- New command: `strata migrate-meta` rewrites `_strata_meta` from the 1.x
  layout to the 2.x layout in place.
- Breaking: `Model.__tablename__` renamed to `Model.__table__`. (Already
  supported as an alias since 1.6.)
