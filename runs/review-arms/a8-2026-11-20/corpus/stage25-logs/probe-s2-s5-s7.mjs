import { CorpusError, toWorkerError, isCorpusWorkerError } from "/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25-corpus/types.ts";
import { workspaceSlug, safeSegment, workspaceDir, sourcePath, customTypePath, artifactVersionPath } from "/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25-corpus/paths.ts";
import { createOpfsCorpusFs } from "/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25-corpus/opfsAdapter.ts";

// ---- S2 round trip, in-realm and across structuredClone (postMessage algorithm)
const kinds = [
  { kind: "not-found", path: "a/b" },
  { kind: "quota-exceeded", substrate: "opfs", needed: 10, available: 3 },
  { kind: "quota-exceeded", substrate: "fsa" },
  { kind: "unavailable", reason: "r" },
  { kind: "io", path: "p", reason: "why" },
  { kind: "fsa-permission-revoked" }, { kind: "remote-auth-expired" }, { kind: "browser-storage-cleared" },
  { kind: "git-conflict", path: "x" },
];
for (const d of kinds) for (const msg of [undefined, "custom msg"]) {
  const orig = new CorpusError(d, msg);
  const wire = structuredClone(toWorkerError(orig));
  const back = new CorpusError(wire.detail, wire.message);
  const same = isCorpusWorkerError(wire) && back instanceof CorpusError && back.name === orig.name && back.message === orig.message && JSON.stringify(back.detail) === JSON.stringify(orig.detail);
  if (!same) console.log("S2 MISMATCH", d, msg);
}
const o = new CorpusError({ kind: "io", path: "p", reason: "r" });
const w = toWorkerError(o);
const b = new CorpusError(w.detail, w.message);
console.log("S2 all 18 kind/message cases equal on name+message+detail+instanceof (no MISMATCH lines above)");
console.log("S2 stack preserved?", b.stack === o.stack, "; detail aliased in-realm (same object)?", w.detail === o.detail, "; own keys orig:", Object.keys(o), "back:", Object.keys(b));
o.cause = "c"; console.log("S2 cause carried by toWorkerError?", "cause" in toWorkerError(o));

// ---- S5 fuzz
const nastyStr = ["..", "../etc/passwd", "a/b", "a\\b", "\u0000", "a\u0000b", "\uFF0E\uFF0E", "\uFF0F", "\uFF3C", "\u2025", "\u2024\u2024", "...", ". .", "\uFF21\uFF22", "\u0130", "\u00DF", "\u212A", "\u216B", "\u00BD"];
let bad = 0, throws = 0;
const rnd = (n) => Array.from({ length: n }, () => String.fromCodePoint(Math.floor(Math.random() * 0x30000))).join("");
const inputs = [...nastyStr]; for (let i = 0; i < 200000; i++) inputs.push(rnd(1 + (i % 12)));
for (const t of inputs) {
  for (const [fn, re] of [[workspaceSlug, /^[a-z0-9_-]+$/], [safeSegment, /^[A-Za-z0-9_-]+$/]]) {
    try { const r = fn(t); if (!re.test(r) || r.includes("..")) { bad++; console.log("S5 BAD", fn.name, JSON.stringify(t), JSON.stringify(r)); } }
    catch (e) { if (!/empty/.test(e.message)) { bad++; console.log("S5 unexpected throw", e.message); } throws++; }
  }
}
console.log("S5 fuzz inputs:", inputs.length, "x2 fns; violations:", bad, "; empty-result throws:", throws);
for (const t of nastyStr) { let a, c; try { a = workspaceSlug(t); } catch (e) { a = "THROW"; } try { c = safeSegment(t); } catch (e) { c = "THROW"; } console.log("S5", JSON.stringify(t), "->", a, "|", c); }
for (const t of ["", "-", "---", "\u0000"]) { try { workspaceSlug(t); console.log("S5 no throw for", JSON.stringify(t)); } catch (e) { console.log("S5 throws for", JSON.stringify(t), e.constructor.name, e.message); } }
console.log("S5 built paths:", workspaceDir("../x"), sourcePath("../x", "../../y", "../z"), customTypePath("s", "..\\..\\q"), artifactVersionPath("s", "../t", 1));
const ext = sourcePath("s", "id", "."); console.log("S5 ext '.' ->", ext);

// ---- S7
function setNav(v) { Object.defineProperty(globalThis, "navigator", { configurable: true, value: v }); }
const methods = { readFile: f => f.readFile("x"), writeFile: f => f.writeFile("x", new Uint8Array()), readdir: f => f.readdir("x"), rm: f => f.rm("x"), stat: f => f.stat("x") };
for (const [label, nav] of [["navigator.storage undefined", { }], ["storage present, no getDirectory", { storage: {} }], ["getDirectory not a function", { storage: { getDirectory: 1 } }], ["no navigator global", undefined], ["getDirectory throws TypeError", { storage: { getDirectory: async () => { throw new TypeError("boom"); } } }], ["getDirectory throws SecurityError", { storage: { getDirectory: async () => { throw new DOMException("denied", "SecurityError"); } } }]]) {
  if (nav === undefined) { delete globalThis.navigator; Object.defineProperty(globalThis, "navigator", { configurable: true, value: undefined }); } else setNav(nav);
  const fs = createOpfsCorpusFs();
  const out = [];
  for (const [m, call] of Object.entries(methods)) {
    try { await call(fs); out.push(m + ":resolved"); } catch (e) { out.push(m + ":" + (e instanceof CorpusError ? e.detail.kind : "RAW " + e.constructor.name)); }
  }
  console.log("S7", label, "->", out.join(" "));
}
