# Media library — storage port and its clients, concatenated into one file for review.
#
# Architecture: ports and adapters.
#   media/ports/           abstract interfaces the application depends on
#   media/application/     use cases (thumbnails, archive browsing)
#   media/infrastructure/  concrete adapters (S3, read-only mirror)
#
# Each "# ---- file: <path> ----" marker starts a separate module.


# ---- file: media/ports/storage.py ----
from datetime import timedelta
from typing import Iterator, Protocol


class BlobStore(Protocol):
    def get(self, key: str) -> bytes: ...
    def put(self, key: str, data: bytes, content_type: str) -> None: ...
    def delete(self, key: str) -> None: ...
    def exists(self, key: str) -> bool: ...
    def list(self, prefix: str) -> Iterator[str]: ...
    def copy(self, src: str, dst: str) -> None: ...
    def move(self, src: str, dst: str) -> None: ...
    def set_acl(self, key: str, acl: str) -> None: ...
    def get_acl(self, key: str) -> str: ...
    def presigned_url(self, key: str, ttl: timedelta) -> str: ...
    def start_multipart(self, key: str) -> str: ...
    def upload_part(self, upload_id: str, part_no: int, data: bytes) -> str: ...
    def complete_multipart(self, upload_id: str, etags: list[str]) -> None: ...
    def set_lifecycle_rule(self, prefix: str, expire_after_days: int) -> None: ...
    def usage_bytes(self, prefix: str) -> int: ...


# ---- file: media/application/thumbnails.py ----
from media.ports.storage import BlobStore


class ThumbnailGenerator:
    def __init__(self, store: BlobStore, resize) -> None:
        self._store = store
        self._resize = resize

    def generate(self, key: str) -> str:
        original = self._store.get(key)
        thumb_key = f"thumbs/{key}"
        self._store.put(thumb_key, self._resize(original, 256), "image/jpeg")
        return thumb_key


# ---- file: media/application/archive_browser.py ----
from typing import Iterator

from media.ports.storage import BlobStore


class ArchiveBrowser:
    def __init__(self, store: BlobStore) -> None:
        self._store = store

    def entries(self, year: int) -> Iterator[str]:
        return self._store.list(f"archive/{year}/")

    def read(self, key: str) -> bytes:
        return self._store.get(key)


# ---- file: media/infrastructure/mirror_store.py ----
from datetime import timedelta
from pathlib import Path
from typing import Iterator


class ReadOnlyMirrorStore:
    """Serves blobs from a local rsync mirror of the archive bucket."""

    def __init__(self, root: Path) -> None:
        self._root = root

    def get(self, key: str) -> bytes:
        return (self._root / key).read_bytes()

    def exists(self, key: str) -> bool:
        return (self._root / key).is_file()

    def list(self, prefix: str) -> Iterator[str]:
        base = self._root / prefix
        for p in sorted(base.rglob("*")):
            if p.is_file():
                yield str(p.relative_to(self._root))

    def put(self, key: str, data: bytes, content_type: str) -> None:
        raise NotImplementedError

    def delete(self, key: str) -> None:
        raise NotImplementedError

    def copy(self, src: str, dst: str) -> None:
        raise NotImplementedError

    def move(self, src: str, dst: str) -> None:
        raise NotImplementedError

    def set_acl(self, key: str, acl: str) -> None:
        raise NotImplementedError

    def get_acl(self, key: str) -> str:
        raise NotImplementedError

    def presigned_url(self, key: str, ttl: timedelta) -> str:
        raise NotImplementedError

    def start_multipart(self, key: str) -> str:
        raise NotImplementedError

    def upload_part(self, upload_id: str, part_no: int, data: bytes) -> str:
        raise NotImplementedError

    def complete_multipart(self, upload_id: str, etags: list[str]) -> None:
        raise NotImplementedError

    def set_lifecycle_rule(self, prefix: str, expire_after_days: int) -> None:
        raise NotImplementedError

    def usage_bytes(self, prefix: str) -> int:
        raise NotImplementedError


# ---- file: media/main.py ----
from pathlib import Path

from media.application.archive_browser import ArchiveBrowser
from media.infrastructure.mirror_store import ReadOnlyMirrorStore


def build_archive_browser() -> ArchiveBrowser:
    return ArchiveBrowser(ReadOnlyMirrorStore(Path("/srv/mirror")))
