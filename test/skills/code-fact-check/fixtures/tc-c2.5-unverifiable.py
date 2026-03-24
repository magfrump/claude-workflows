# Test fixture for TC-C2.5: Unverifiable verdict
# Comment claims thread-safety due to GIL, but the code has complex concurrency

import threading
import queue

# thread-safe due to GIL
class TaskQueue:
    def __init__(self):
        self._queue = queue.Queue()
        self._results = {}
        self._lock = threading.Lock()

    def submit(self, task_id, fn, *args):
        self._queue.put((task_id, fn, args))

    def process(self):
        while not self._queue.empty():
            task_id, fn, args = self._queue.get()
            result = fn(*args)
            with self._lock:
                self._results[task_id] = result

    def get_result(self, task_id):
        with self._lock:
            return self._results.get(task_id)
