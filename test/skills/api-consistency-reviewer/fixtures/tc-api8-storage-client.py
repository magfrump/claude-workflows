"""Public API of the `blobkit` storage client library."""

from dataclasses import dataclass
from typing import Iterator, Optional

from blobkit._transport import Transport
from blobkit.errors import NotFoundError

__all__ = [
    "Bucket",
    "BlobObject",
    "StorageClient",
]


@dataclass(frozen=True)
class Bucket:
    name: str
    region: str
    created_at: str


@dataclass(frozen=True)
class BlobObject:
    bucket: str
    key: str
    size_bytes: int
    etag: str
    created_at: str


class StorageClient:
    def __init__(self, transport: Transport):
        self._transport = transport

    def get_bucket(self, name: str) -> Bucket:
        """Return the bucket called ``name``. Raises NotFoundError if absent."""
        resp = self._transport.request("GET", f"/buckets/{name}")
        if resp.status == 404:
            raise NotFoundError(f"bucket {name!r} not found")
        return Bucket(**resp.json())

    def list_buckets(self, *, prefix: Optional[str] = None, page_size: int = 100) -> Iterator[Bucket]:
        """Yield every bucket, optionally filtered by name prefix."""
        for item in self._transport.paginate("/buckets", params={"prefix": prefix}, page_size=page_size):
            yield Bucket(**item)

    def delete_bucket(self, name: str) -> None:
        """Delete the bucket called ``name``. Raises NotFoundError if absent."""
        resp = self._transport.request("DELETE", f"/buckets/{name}")
        if resp.status == 404:
            raise NotFoundError(f"bucket {name!r} not found")

    # BEGIN CHANGE UNDER REVIEW
    def get_object(self, bucket: str, key: str) -> BlobObject:
        """Return metadata for ``key`` in ``bucket``. Raises NotFoundError if absent."""
        resp = self._transport.request("GET", f"/buckets/{bucket}/objects/{key}")
        if resp.status == 404:
            raise NotFoundError(f"object {key!r} not found in bucket {bucket!r}")
        return BlobObject(**resp.json())

    def list_objects(
        self, bucket: str, *, prefix: Optional[str] = None, page_size: int = 100
    ) -> Iterator[BlobObject]:
        """Yield every object in ``bucket``, optionally filtered by key prefix."""
        for item in self._transport.paginate(
            f"/buckets/{bucket}/objects", params={"prefix": prefix}, page_size=page_size
        ):
            yield BlobObject(**item)

    def delete_object(self, bucket: str, key: str) -> None:
        """Delete ``key`` from ``bucket``. Raises NotFoundError if absent."""
        resp = self._transport.request("DELETE", f"/buckets/{bucket}/objects/{key}")
        if resp.status == 404:
            raise NotFoundError(f"object {key!r} not found in bucket {bucket!r}")
    # END CHANGE UNDER REVIEW
