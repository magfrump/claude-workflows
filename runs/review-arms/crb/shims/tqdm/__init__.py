"""Offline shim for tqdm — pass-through iterator/context, no dependency needed."""


class tqdm:  # noqa: N801 - matches the real API name
    def __init__(self, iterable=None, total=None, desc=None, **kwargs):
        self.iterable = iterable
        self.total = total

    def __iter__(self):
        yield from (self.iterable or [])

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False

    def update(self, n=1):
        pass

    def set_description(self, *a, **k):
        pass

    def set_postfix(self, *a, **k):
        pass

    def close(self):
        pass
