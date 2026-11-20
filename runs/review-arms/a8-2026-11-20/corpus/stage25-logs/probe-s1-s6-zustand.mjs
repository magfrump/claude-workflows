// S1/S6 probe: zustand 5.0.13 persist + createJSONStorage, run directly.
import { createStore } from "/workspace/external/cc-review-eval/mfc-corpus/node_modules/zustand/esm/vanilla.mjs";
import { persist, createJSONStorage } from "/workspace/external/cc-review-eval/mfc-corpus/node_modules/zustand/esm/middleware.mjs";
import { createDebouncedLocalStorage, createCorpusBackedStorage } from "/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25-corpus/storeAdapter.ts";
import { createInMemoryCorpusFs } from "/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25-corpus/inMemoryCorpusFs.ts";

// minimal localStorage shim for the debounced adapter
const ls = new Map();
globalThis.localStorage = { getItem: k => ls.has(k) ? ls.get(k) : null, setItem: (k,v) => ls.set(k,String(v)), removeItem: k => ls.delete(k) };

let stringifyCalls = 0;
const origStringify = JSON.stringify;
JSON.stringify = function (...a) { stringifyCalls++; return origStringify.apply(this, a); };

function mk(getStorage, mergeSpy) {
  return createStore(persist((set) => ({ text: "", setText: (t) => set({ text: t }) }), {
    name: "k", storage: createJSONStorage(getStorage), skipHydration: true,
    merge: (p, c) => { mergeSpy.push(p); return { ...c, ...(p && typeof p === "object" ? p : {}) }; },
  }));
}

// S1: count stringify per set() with the debounced adapter (flag-off path)
{
  const merges = [];
  const store = mk(createDebouncedLocalStorage, merges);
  stringifyCalls = 0;
  for (let i = 0; i < 10; i++) store.getState().setText("x".repeat(i));
  console.log("S1 debounced: 10 set() calls ->", stringifyCalls, "JSON.stringify calls; localStorage writes so far:", ls.size);
  await new Promise(r => setTimeout(r, 350));
  console.log("S1 debounced: after 350ms localStorage value:", ls.get("k"));
}
{
  const merges = [];
  const fs = createInMemoryCorpusFs();
  const store = mk(() => createCorpusBackedStorage(fs), merges);
  stringifyCalls = 0;
  for (let i = 0; i < 10; i++) store.getState().setText("y".repeat(i));
  console.log("S1 corpus: 10 set() calls ->", stringifyCalls, "JSON.stringify calls");
}
JSON.stringify = origStringify;

// S6: corpus-backed hydrate passes the parsed blob through merge
{
  const merges = [];
  const fs = createInMemoryCorpusFs();
  await fs.writeFile("state/k.json", new TextEncoder().encode(origStringify({ state: { text: "from-corpus", evil: 1 }, version: 0 })));
  const store = mk(() => createCorpusBackedStorage(fs), merges);
  let cbErr = "unset";
  store.persist.setOptions({ onRehydrateStorage: () => (_s, e) => { cbErr = e; } });
  await store.persist.rehydrate();
  console.log("S6 valid blob: merge called", merges.length, "time(s) with", origStringify(merges[0]), "; state.text =", store.getState().text, "; cb error =", cbErr);
}
// S6: async getItem returning non-JSON
{
  const merges = [];
  const fs = createInMemoryCorpusFs();
  await fs.writeFile("state/k.json", new TextEncoder().encode("{ not json"));
  const store = mk(() => createCorpusBackedStorage(fs), merges);
  let cbErr = "unset";
  store.persist.setOptions({ onRehydrateStorage: () => (_s, e) => { cbErr = e; } });
  let threw = null;
  try { await store.persist.rehydrate(); } catch (e) { threw = e; }
  await new Promise(r => setTimeout(r, 10));
  console.log("S6 non-JSON: rehydrate() rejected?", threw ? threw.constructor.name : "no", "; merge calls", merges.length, "; state.text =", origStringify(store.getState().text), "; onRehydrateStorage error =", cbErr && cbErr.constructor ? cbErr.constructor.name + ": " + cbErr.message : cbErr, "; hasHydrated =", store.persist.hasHydrated());
}
// S6: valid JSON but non-object state (e.g. a string) -> merge receives it
{
  const merges = [];
  const fs = createInMemoryCorpusFs();
  await fs.writeFile("state/k.json", new TextEncoder().encode(origStringify({ state: "str", version: 0 })));
  const store = mk(() => createCorpusBackedStorage(fs), merges);
  await store.persist.rehydrate();
  console.log("S6 non-object state: merge calls", merges.length, "arg", origStringify(merges[0]));
}
