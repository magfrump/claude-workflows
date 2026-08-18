// D5 write-race probe (Stage 2.5 submitted-claim SC2).
// Question: does zustand@5.0.13 persist middleware await the prior async
// storage.setItem before firing the next on a subsequent set()? If not, two
// rapid set() calls put two OPFS writeFile sequences in flight concurrently
// against the same key (lost-update hazard).
//
// Mechanics: build a real persist store using the clone's zustand, back it with
// a StateStorage whose setItem mirrors the app's createCorpusBackedStorage:
// an async that awaits a slow multi-step "writeFile" and logs enter/exit so
// overlap is directly observable. Fire two set() calls back-to-back (no await
// between them, exactly as two keystrokes arrive) and watch for interleave.

import { createRequire } from "node:module";
const require = createRequire(
  "/workspace/external/cc-review-eval/mfc-corpus/"
);
const { createStore } = require("zustand/vanilla");
const { persist, createJSONStorage } = require("zustand/middleware");

const log = [];
let inFlight = 0;
let maxConcurrent = 0;
const order = [];

// Mirror of createCorpusBackedStorage.setItem: a bare `await writeFile` with a
// multi-await body and NO cross-call queue/lock. Slow (10ms) so a second call
// issued synchronously after the first will overlap if persist doesn't await.
const rawStorage = {
  getItem: async () => null,
  setItem: async (name, value) => {
    const id = ++order.length;
    inFlight++;
    maxConcurrent = Math.max(maxConcurrent, inFlight);
    log.push(`ENTER writeFile #${id} value=${JSON.parse(value).state.n} inFlight=${inFlight}`);
    // simulate the ~6 sequential OPFS awaits (getRoot/getDirHandle/.../close)
    for (let i = 0; i < 6; i++) await new Promise((r) => setTimeout(r, 2));
    inFlight--;
    log.push(`EXIT  writeFile #${id} value=${JSON.parse(value).state.n} inFlight=${inFlight}`);
  },
  removeItem: async () => {},
};

const store = createStore(
  persist(() => ({ n: 0 }), {
    name: "workspace-zustand-v1",
    storage: createJSONStorage(() => rawStorage),
    partialize: (s) => ({ n: s.n }),
  })
);

// Two keystrokes arriving back-to-back: two synchronous set() calls, NO await
// between them (this is exactly how the persist middleware receives editor
// setState calls — fire-and-forget).
store.setState({ n: 1 });
store.setState({ n: 2 });

// Let both writes drain.
await new Promise((r) => setTimeout(r, 100));

console.log("=== D5 write-race probe: zustand persist un-awaited setItem ===");
console.log("zustand version:", require("zustand/package.json").version);
for (const line of log) console.log(line);
console.log("---");
console.log("maxConcurrent writeFile sequences in flight:", maxConcurrent);
console.log(
  "VERDICT:",
  maxConcurrent >= 2
    ? "CONFIRMED — two writeFile sequences overlapped; persist does NOT await the prior setItem before firing the next. Completion order is not guaranteed to match issue order -> lost-update hazard."
    : "REFUTED — writes serialized; persist awaited the prior setItem."
);
