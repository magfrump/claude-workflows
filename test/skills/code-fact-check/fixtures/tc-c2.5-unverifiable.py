import threading
from typing import Callable

from ringbuf import SpscRing  # vendored wheel; the compiled module is not in this repo


class EventPump:
    def __init__(self, capacity: int = 4096) -> None:
        # SpscRing is lock-free and safe with one producer thread and one
        # consumer thread running at the same time, so the ring needs no lock.
        self._ring = SpscRing(capacity)
        self._handlers: list[Callable[[bytes], None]] = []
        self._handlers_lock = threading.Lock()

    def on_event(self, handler: Callable[[bytes], None]) -> None:
        with self._handlers_lock:
            self._handlers.append(handler)

    def push(self, payload: bytes) -> bool:
        return self._ring.try_push(payload)

    def drain(self) -> int:
        count = 0
        while (payload := self._ring.try_pop()) is not None:
            with self._handlers_lock:
                handlers = list(self._handlers)
            for handler in handlers:
                handler(payload)
            count += 1
        return count
