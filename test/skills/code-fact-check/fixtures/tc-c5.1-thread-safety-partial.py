# Test fixture for TC-C5.1: Thread-safety claim with partial truth
# Function itself uses no shared state, but calls one that does

import threading

_shared_counter = 0
_lock = threading.Lock()

def increment_shared():
    global _shared_counter
    with _lock:
        _shared_counter += 1

# thread-safe
def process_item(item):
    """Process a single item. Thread-safe."""
    result = transform(item)
    # This call touches shared state — the claim is misleading in context
    increment_shared()
    return result

def transform(item):
    return item.upper()
