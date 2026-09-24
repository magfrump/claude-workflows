# Upgrade request: tarnish 2.3.1 → 2.3.4

`tarnish` is the archive library behind our "import project bundle" feature.
A teammate asked whether the patch releases since our pinned version are worth
taking now or can wait for the quarterly dependency sweep.

## Manifest (pyproject.toml)

```toml
[project]
name = "sketchbook-server"
requires-python = ">=3.11"
dependencies = [
  "tarnish==2.3.1",
  "starlite-web>=4.2",
]
```

## How the project uses tarnish

These are all of the call sites.

`sketchbook/bundles/importer.py`

```python
import tarnish

from sketchbook.storage import workspace_dir


async def import_bundle(upload, account_id):
    """Unpack a .skb bundle uploaded through the web UI into the account's workspace."""
    dest = workspace_dir(account_id)
    with tarnish.open(upload.file) as archive:
        archive.extract_all(dest)
    return dest
```

`sketchbook/api/routes.py`

```python
@router.post("/bundles/import")
async def import_route(file: UploadFile, account=Depends(current_account)):
    dest = await import_bundle(file, account.id)
    return {"workspace": str(dest)}
```

Any signed-in account can call this route. Bundles are produced by other
people's exports and shared by email or chat.

## Release notes (complete, 2.3.1 → 2.3.4)

### 2.3.4

- Security: fixes TARN-2026-0117. `extract_all()` did not reject entries whose
  names contain `..` components or absolute paths, so a crafted archive could
  write files outside the destination directory. Entries like these now raise
  `UnsafeEntryError`. Versions 2.0.0 through 2.3.3 are affected.

### 2.3.3

- Faster listing of archives with more than 10,000 entries.

### 2.3.2

- `tarnish.open()` accepts `os.PathLike` objects.
- Documentation fixes.

No release in this range contains a breaking change.
