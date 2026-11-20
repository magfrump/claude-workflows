// S3 probe: not-found contract matrix, in-memory fake vs OPFS adapter over a
// stub root whose every lookup rejects NotFoundError (an empty OPFS).
const S = process.argv[2];
const { createOpfsCorpusFs } = await import(S + "/opfsAdapter.ts");
const { createInMemoryCorpusFs } = await import(S + "/inMemoryCorpusFs.ts");
const { CorpusError } = await import(S + "/types.ts");
const nf = () => { throw new DOMException("nf", "NotFoundError"); };
const emptyRoot = { async getFileHandle() { nf(); }, async getDirectoryHandle() { nf(); }, async removeEntry() { nf(); }, async *keys() {} };
Object.defineProperty(globalThis, "navigator", { configurable: true, value: { storage: { getDirectory: async () => emptyRoot } } });
const impls = { mem: createInMemoryCorpusFs(), opfs: createOpfsCorpusFs() };
const paths = ["absent.txt", "no/such/dir/f.txt", "/lead/slash.txt", "", "/"];
for (const p of paths) {
  const row = [];
  for (const [n, fs] of Object.entries(impls)) {
    for (const m of ["readFile", "stat", "readdir", "rm"]) {
      try { const r = await fs[m](p); row.push(`${n}.${m}=${JSON.stringify(r) ?? "undefined"}`); }
      catch (e) { row.push(`${n}.${m}=THROW(${e instanceof CorpusError ? e.detail.kind : e.constructor.name})`); }
    }
  }
  console.log(JSON.stringify(p), "->", row.join(" "));
}
