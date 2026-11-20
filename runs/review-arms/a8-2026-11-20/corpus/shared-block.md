# Review pass: shared context (identical for every agent in this pass)

User goal: A full code review (terminal pass, not a loop pass) of the change dc6dfb0..2dc403e in the meta-formalism-copilot repository, scoped to `app/`, so the owner learns what is wrong with it before it ships.

The reviewed state is checked out at /tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-corpus (detached HEAD 2dc403e). Run git commands there (for example `git -C <that path> diff dc6dfb0..2dc403e -- app/`). Do not modify, commit or check out anything in that worktree; it is read-only for you. You may read any file in it, including files outside the diff (consumers, callers, config).

Rules for this pass:
- Complete-unit reading rule: before verdicting a claim or filing a finding about code inside a function or method, read the entire enclosing unit, signature to final line, explicitly including the lines after the last line the finding cites, plus the flow of any value the analyzed lines produce to its first point of use. Any quoted excerpt that ends inside its enclosing unit must carry a truncation marker naming the remainder (for example `excerpt ends :99; enclosing getClient() continues to :108 — read`).
- Probe-cleanup rule: any process you start (a sleep, a FIFO reader, a background script, a dev server) runs under `timeout` and is killed before you report. Do not install packages or use the network.

Scope: the change dc6dfb0..2dc403e restricted to `-- app/` (15 files, +1166/-33). This is a partial scope. The branch's other 13 changed files in the same range (CLAUDE.md, docs/decisions/009-artifact-corpus-architecture.md, docs/thoughts/corpus-fs-seam.md, docs/spikes/*, docs/working/*, docs/reviews/architecture-review.md) are already committed — context only, not under review. Before flagging work as "missing", check the rest of the branch for it (`git -C <worktree> log dc6dfb0..2dc403e`, `git -C <worktree> diff dc6dfb0..2dc403e -- <path>`). That label marks provenance, not trustworthiness: a claim those files make about the code under review is still checkable.

## What this PR is trying to accomplish

Adds the S0+S1 slice of the DD-009 artifact-corpus architecture: a `CorpusFS` filesystem contract with an OPFS adapter and an in-memory fake held to one shared contract suite, the corpus folder-layout path builders and `workspace.json` manifest codec, and a default-off, dev-only flag that swaps the Zustand workspace store's persistence from debounced localStorage to a CorpusFS-backed single-blob storage. The default (flag off) path is meant to be byte-for-byte the prior behavior, guarded by a characterization test.

Commits in range touching `app/` (oldest first): ec7bbbc "feat(corpus): S0 contracts — CorpusFS interface, layout, manifest", 3da6747 "test(corpus): characterization baseline + CorpusFS contract/layout/manifest tests", f6361a3 "feat(corpus): OPFS adapter implementing CorpusFS + error-mapping tests", 00ba8c3 "feat(corpus): default-off flag + CorpusFS-typed store seam", 122d70f "refactor(corpus)+docs: rename layout.ts->paths.ts (Next reserved name); seam docs + OPFS smoke". Read their bodies with `git -C <worktree> log --format=%B -1 <sha>`; their factual claims are in scope.

## The diff (git diff dc6dfb0..2dc403e -- app/)

Delivery mode: inline-diff-only. The diff plus the post-change contents of the touched files came to 123,423 bytes (about 30.9k tokens at bytes/4), over the 25k-token shared-block budget, so only the diff is inlined. Read the enclosing files yourself as you need them; you have repo access.

```diff
diff --git a/app/lib/corpus/__tests__/corpusFs.contract.test.ts b/app/lib/corpus/__tests__/corpusFs.contract.test.ts
new file mode 100644
index 0000000..4d4f054
--- /dev/null
+++ b/app/lib/corpus/__tests__/corpusFs.contract.test.ts
@@ -0,0 +1,8 @@
+/** Runs the shared CorpusFS contract against the in-memory fake (DD-009 S1).
+ *  The OPFS adapter is held to the same suite out-of-CI (Playwright); jsdom has
+ *  no OPFS so the real adapter cannot run here. */
+
+import { defineCorpusFsContract } from "./corpusFsContract";
+import { createInMemoryCorpusFs } from "./inMemoryCorpusFs";
+
+defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());
diff --git a/app/lib/corpus/__tests__/corpusFsContract.ts b/app/lib/corpus/__tests__/corpusFsContract.ts
new file mode 100644
index 0000000..7931795
--- /dev/null
+++ b/app/lib/corpus/__tests__/corpusFsContract.ts
@@ -0,0 +1,82 @@
+/**
+ * Shared `CorpusFS` contract suite (DD-009 sub-task S1).
+ *
+ * Any `CorpusFS` implementation must pass this. Run against the in-memory fake
+ * in CI (corpusFs.contract.test.ts) and against the real OPFS adapter via
+ * out-of-CI Playwright (jsdom has no OPFS). Keeping the cases in one place means
+ * the fake and the adapter are held to identical behavior (substitutability).
+ */
+
+import { describe, it, expect, beforeEach } from "vitest";
+import type { CorpusFS } from "../types";
+
+/** @param makeFs returns a fresh, empty CorpusFS for each test. */
+export function defineCorpusFsContract(label: string, makeFs: () => CorpusFS | Promise<CorpusFS>): void {
+  describe(`CorpusFS contract: ${label}`, () => {
+    let fs: CorpusFS;
+    beforeEach(async () => {
+      fs = await makeFs();
+    });
+
+    it("returns null for a missing file (readFile) and missing stat", async () => {
+      expect(await fs.readFile("absent.txt")).toBeNull();
+      expect(await fs.stat("absent.txt")).toBeNull();
+    });
+
+    it("returns [] for a missing/empty directory (readdir)", async () => {
+      expect(await fs.readdir("nope")).toEqual([]);
+    });
+
+    it("round-trips all 256 byte values exactly", async () => {
+      const bytes = new Uint8Array(256);
+      for (let i = 0; i < 256; i++) bytes[i] = i;
+      await fs.writeFile("bin/all-bytes.dat", bytes);
+      const out = await fs.readFile("bin/all-bytes.dat");
+      expect(out).not.toBeNull();
+      // Compare as arrays for a readable diff on failure.
+      expect(Array.from(out!)).toEqual(Array.from(bytes));
+      expect((await fs.stat("bin/all-bytes.dat"))?.size).toBe(256);
+    });
+
+    it("creates intermediate directories and lists children at each level", async () => {
+      await fs.writeFile("workspaces/s/artifacts/semiformal/v0001.md", new TextEncoder().encode("x"));
+      expect(await fs.readdir("workspaces")).toEqual(["s"]);
+      expect(await fs.readdir("workspaces/s")).toEqual(["artifacts"]);
+      expect(await fs.readdir("workspaces/s/artifacts")).toEqual(["semiformal"]);
+      expect(await fs.readdir("workspaces/s/artifacts/semiformal")).toEqual(["v0001.md"]);
+    });
+
+    it("rm removes a file and is idempotent on a missing path", async () => {
+      await fs.writeFile("a.txt", new TextEncoder().encode("hi"));
+      await fs.rm("a.txt");
+      expect(await fs.readFile("a.txt")).toBeNull();
+      // Second rm (and rm of never-existed) must not throw.
+      await expect(fs.rm("a.txt")).resolves.toBeUndefined();
+      await expect(fs.rm("never-existed.txt")).resolves.toBeUndefined();
+    });
+
+    it("handles the S4 access pattern: 30 small files in one artifact dir (arch-review finding 4)", async () => {
+      const dir = "workspaces/s/artifacts/semiformal";
+      for (let v = 1; v <= 30; v++) {
+        const name = `v${String(v).padStart(4, "0")}.md`;
+        await fs.writeFile(`${dir}/${name}`, new TextEncoder().encode(`version ${v}`));
+      }
+      const names = await fs.readdir(dir);
+      expect(names).toHaveLength(30);
+      expect(names).toContain("v0001.md");
+      expect(names).toContain("v0030.md");
+      // Read each back and confirm content integrity.
+      for (let v = 1; v <= 30; v++) {
+        const name = `v${String(v).padStart(4, "0")}.md`;
+        const bytes = await fs.readFile(`${dir}/${name}`);
+        expect(new TextDecoder().decode(bytes!)).toBe(`version ${v}`);
+      }
+    });
+
+    it("overwrites an existing file in place", async () => {
+      await fs.writeFile("a.txt", new TextEncoder().encode("first"));
+      await fs.writeFile("a.txt", new TextEncoder().encode("second"));
+      expect(new TextDecoder().decode((await fs.readFile("a.txt"))!)).toBe("second");
+    });
+  });
+}
diff --git a/app/lib/corpus/__tests__/inMemoryCorpusFs.ts b/app/lib/corpus/__tests__/inMemoryCorpusFs.ts
new file mode 100644
index 0000000..55e2ba1
--- /dev/null
+++ b/app/lib/corpus/__tests__/inMemoryCorpusFs.ts
@@ -0,0 +1,53 @@
+/**
+ * Map-backed in-memory `CorpusFS` for tests (DD-009 sub-task S1).
+ *
+ * Lets corpus logic be verified in CI even though jsdom has no OPFS. The OPFS
+ * adapter and this fake are both asserted against the same shared contract suite
+ * (corpusFsContract.ts), so substitutability (LSP) is verified, not assumed.
+ *
+ * Directories are implicit: a file at "a/b/c.txt" makes "a" and "a/b" listable.
+ */
+
+import type { CorpusFS, CorpusStat } from "../types";
+
+function normalize(path: string): string {
+  return path.replace(/^\/+|\/+$/g, "");
+}
+
+export function createInMemoryCorpusFs(): CorpusFS {
+  const files = new Map<string, Uint8Array>();
+
+  return {
+    async readFile(path) {
+      return files.get(normalize(path)) ?? null;
+    },
+
+    async writeFile(path, bytes) {
+      // Copy so later mutation of the caller's array can't alter stored bytes.
+      files.set(normalize(path), bytes.slice());
+    },
+
+    async readdir(path) {
+      const dir = normalize(path);
+      const prefix = dir === "" ? "" : `${dir}/`;
+      const children = new Set<string>();
+      for (const key of files.keys()) {
+        if (prefix !== "" && !key.startsWith(prefix)) continue;
+        const rest = key.slice(prefix.length);
+        if (rest === "") continue;
+        const next = rest.split("/")[0];
+        if (next) children.add(next);
+      }
+      return [...children].sort();
+    },
+
+    async rm(path) {
+      files.delete(normalize(path)); // idempotent: Map.delete on a missing key is a no-op
+    },
+
+    async stat(path): Promise<CorpusStat | null> {
+      const bytes = files.get(normalize(path));
+      return bytes ? { size: bytes.byteLength } : null;
+    },
+  };
+}
diff --git a/app/lib/corpus/__tests__/manifest.test.ts b/app/lib/corpus/__tests__/manifest.test.ts
new file mode 100644
index 0000000..fdeedbf
--- /dev/null
+++ b/app/lib/corpus/__tests__/manifest.test.ts
@@ -0,0 +1,52 @@
+/** Manifest codec tests (DD-009 S0, test-strategy G11/G12). */
+
+import { describe, it, expect } from "vitest";
+import { createManifest, serializeManifest, parseManifest, MANIFEST_VERSION } from "../manifest";
+import { CorpusError } from "../types";
+
+describe("manifest round-trip (G12)", () => {
+  it("serialize -> parse is lossless for sources, artifact pointers, custom-type ids", () => {
+    const m = createManifest("My Workspace", "2026-06-01T00:00:00Z");
+    m.sources = [{ id: "s1", label: "Paper A", ext: "pdf" }];
+    m.artifacts = [
+      { type: "semiformal", currentVersion: 3 },
+      { type: "causal-graph", currentVersion: 1 },
+    ];
+    m.customTypeIds = ["custom-abc", "custom-def"];
+
+    const parsed = parseManifest(serializeManifest(m));
+    expect(parsed).toEqual(m);
+    expect(parsed.manifestVersion).toBe(MANIFEST_VERSION);
+  });
+});
+
+describe("manifest fail-loud parse (G11)", () => {
+  it("throws CorpusError on non-JSON instead of returning an empty manifest", () => {
+    const bytes = new TextEncoder().encode("{ not json");
+    expect(() => parseManifest(bytes)).toThrow(CorpusError);
+  });
+
+  it("throws on a JSON object missing required fields (not a silent default)", () => {
+    const bytes = new TextEncoder().encode("{}");
+    let caught: unknown;
+    try {
+      parseManifest(bytes);
+    } catch (e) {
+      caught = e;
+    }
+    // Diagnostic: assert on the typed detail, not a string match.
+    expect(caught).toBeInstanceOf(CorpusError);
+    expect((caught as CorpusError).detail.kind).toBe("io");
+  });
+
+  it("throws on a null input (absent file is the caller's null-check, not a default)", () => {
+    expect(() => parseManifest(null)).toThrow(CorpusError);
+  });
+
+  it("throws when sources entries are malformed", () => {
+    const bytes = new TextEncoder().encode(
+      JSON.stringify({ manifestVersion: 1, title: "t", sources: [{ id: "x" }], artifacts: [], customTypeIds: [] }),
+    );
+    expect(() => parseManifest(bytes)).toThrow(/source entry missing/);
+  });
+});
diff --git a/app/lib/corpus/__tests__/opfsAdapter.test.ts b/app/lib/corpus/__tests__/opfsAdapter.test.ts
new file mode 100644
index 0000000..b53ee7e
--- /dev/null
+++ b/app/lib/corpus/__tests__/opfsAdapter.test.ts
@@ -0,0 +1,83 @@
+/**
+ * OPFS adapter error-mapping tests (DD-009 S1, test-strategy G7/G8).
+ *
+ * jsdom has no real OPFS, so these stub `navigator.storage` to drive the
+ * adapter's error-reification logic. The adapter's *success* path is covered by
+ * the shared CorpusFS contract suite run against real OPFS out-of-CI (Playwright,
+ * step 9) — here we only assert that failures become typed CorpusErrors.
+ */
+
+import { describe, it, expect, afterEach } from "vitest";
+import { createOpfsCorpusFs } from "../opfsAdapter";
+import { CorpusError } from "../types";
+
+const original = Object.getOwnPropertyDescriptor(navigator, "storage");
+
+function setStorage(value: unknown): void {
+  Object.defineProperty(navigator, "storage", { configurable: true, value });
+}
+
+afterEach(() => {
+  if (original) Object.defineProperty(navigator, "storage", original);
+  else setStorage(undefined);
+});
+
+describe("OPFS adapter — unavailable guard (G8)", () => {
+  it("rejects with a typed unavailable error when getDirectory is absent (SSR/unsupported)", async () => {
+    setStorage({}); // storage present but no getDirectory
+    const fs = createOpfsCorpusFs();
+    let caught: unknown;
+    try {
+      await fs.readFile("x");
+    } catch (e) {
+      caught = e;
+    }
+    expect(caught).toBeInstanceOf(CorpusError);
+    // Diagnostic: assert on the discriminated kind, not a string match.
+    expect((caught as CorpusError).detail.kind).toBe("unavailable");
+  });
+
+  it("rejects unavailable for every method, not just readFile", async () => {
+    setStorage(undefined);
+    const fs = createOpfsCorpusFs();
+    await expect(fs.writeFile("x", new Uint8Array())).rejects.toBeInstanceOf(CorpusError);
+    await expect(fs.readdir("x")).rejects.toBeInstanceOf(CorpusError);
+    await expect(fs.stat("x")).rejects.toBeInstanceOf(CorpusError);
+    await expect(fs.rm("x")).rejects.toBeInstanceOf(CorpusError);
+  });
+});
+
+describe("OPFS adapter — quota reification (G7)", () => {
+  it("maps a QuotaExceededError on write to {kind:'quota-exceeded', substrate:'opfs'} (not swallowed)", async () => {
+    const fakeRoot = {
+      async getFileHandle() {
+        return {
+          async getFile() {
+            return { size: 0, async arrayBuffer() { return new ArrayBuffer(0); } };
+          },
+          async createWritable() {
+            throw new DOMException("quota", "QuotaExceededError");
+          },
+        };
+      },
+      async getDirectoryHandle() {
+        return fakeRoot;
+      },
+      async removeEntry() {},
+      async *keys() {},
+    };
+    setStorage({ getDirectory: async () => fakeRoot });
+
+    const fs = createOpfsCorpusFs();
+    let caught: unknown;
+    try {
+      await fs.writeFile("a.txt", new TextEncoder().encode("hi"));
+    } catch (e) {
+      caught = e;
+    }
+    expect(caught).toBeInstanceOf(CorpusError);
+    const detail = (caught as CorpusError).detail;
+    expect(detail.kind).toBe("quota-exceeded");
+    if (detail.kind === "quota-exceeded") expect(detail.substrate).toBe("opfs");
+  });
+});
diff --git a/app/lib/corpus/__tests__/paths.test.ts b/app/lib/corpus/__tests__/paths.test.ts
new file mode 100644
index 0000000..6e981b0
--- /dev/null
+++ b/app/lib/corpus/__tests__/paths.test.ts
@@ -0,0 +1,67 @@
+/** Layout path-builder + slug-sanitization tests (DD-009 S0, test-strategy G9/G10). */
+
+import { describe, it, expect } from "vitest";
+import {
+  workspaceSlug,
+  safeSegment,
+  workspaceManifestPath,
+  sourcePath,
+  artifactVersionPath,
+  artifactMetaPath,
+  customTypePath,
+  decompositionGraphLayoutPath,
+} from "../paths";
+
+describe("workspaceSlug sanitization (G10 — no traversal)", () => {
+  it("strips path separators and dot-segments so a title can't escape workspaces/", () => {
+    expect(workspaceSlug("../etc/passwd")).not.toContain("..");
+    expect(workspaceSlug("../etc/passwd")).not.toContain("/");
+    expect(workspaceSlug("a/b")).toBe("a-b");
+    expect(workspaceSlug("My Workspace!")).toBe("my-workspace");
+  });
+
+  it("collapses unsafe runs and trims hyphens", () => {
+    expect(workspaceSlug("  hello   world  ")).toBe("hello-world");
+    expect(workspaceSlug("a***b")).toBe("a-b");
+  });
+
+  it("throws on an all-unsafe title rather than producing an empty slug", () => {
+    // Diagnostic: a silent "" would let a workspace escape to workspaces/.
+    expect(() => workspaceSlug("////")).toThrow(/empty slug/);
+    expect(() => workspaceSlug("。。。")).toThrow(/empty slug/);
+  });
+});
+
+describe("safeSegment", () => {
+  it("keeps a normal custom-type id intact", () => {
+    expect(safeSegment("custom-abc123")).toBe("custom-abc123");
+  });
+  it("neutralizes traversal in an id", () => {
+    expect(safeSegment("../../secret")).not.toContain("..");
+    expect(safeSegment("../../secret")).not.toContain("/");
+  });
+});
+
+describe("path builders match DD-009 folder layout", () => {
+  const s = "my-slug";
+  it("manifest path", () => {
+    expect(workspaceManifestPath(s)).toBe("workspaces/my-slug/workspace.json");
+  });
+  it("source path with extension", () => {
+    expect(sourcePath(s, "src1", "pdf")).toBe("workspaces/my-slug/sources/src1.pdf");
+    expect(sourcePath(s, "src1", ".PDF")).toBe("workspaces/my-slug/sources/src1.pdf");
+  });
+  it("artifact version path is zero-padded to 4 digits", () => {
+    expect(artifactVersionPath(s, "semiformal", 1)).toBe("workspaces/my-slug/artifacts/semiformal/v0001.md");
+    expect(artifactVersionPath(s, "causal-graph", 42)).toBe("workspaces/my-slug/artifacts/causal-graph/v0042.md");
+  });
+  it("rejects a non-positive or non-integer version", () => {
+    expect(() => artifactVersionPath(s, "semiformal", 0)).toThrow();
+    expect(() => artifactVersionPath(s, "semiformal", 1.5)).toThrow();
+  });
+  it("artifact meta, custom-type, decomposition paths", () => {
+    expect(artifactMetaPath(s, "semiformal")).toBe("workspaces/my-slug/artifacts/semiformal/meta.json");
+    expect(customTypePath(s, "custom-x")).toBe("workspaces/my-slug/custom-types/custom-x.json");
+    expect(decompositionGraphLayoutPath(s)).toBe("workspaces/my-slug/decomposition/graph-layout.json");
+  });
+});
diff --git a/app/lib/corpus/flag.ts b/app/lib/corpus/flag.ts
new file mode 100644
index 0000000..717ad3d
--- /dev/null
+++ b/app/lib/corpus/flag.ts
@@ -0,0 +1,25 @@
+/**
+ * Corpus feature flag (DD-009 sub-task S1).
+ *
+ * DEFAULT OFF and DEV-ONLY. In S1 there is no localStorage->corpus migration
+ * (that is S4), so enabling this starts from an EMPTY corpus and does not carry
+ * existing localStorage work over. It exists only to let developers exercise the
+ * OPFS path; it must not be turned on for end users until S4 ships migration.
+ *
+ * Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime
+ * in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`.
+ */
+
+export const CORPUS_FLAG_KEY = "corpus-fs-enabled";
+
+export function isCorpusEnabled(): boolean {
+  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
+  if (typeof window !== "undefined") {
+    try {
+      return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
+    } catch {
+      return false;
+    }
+  }
+  return false;
+}
diff --git a/app/lib/corpus/manifest.ts b/app/lib/corpus/manifest.ts
new file mode 100644
index 0000000..3776d8f
--- /dev/null
+++ b/app/lib/corpus/manifest.ts
@@ -0,0 +1,115 @@
+/**
+ * `workspace.json` manifest schema + codec (DD-009 sub-task S0).
+ *
+ * The manifest is the index for one workspace folder: it lists the sources, the
+ * current-version pointer per artifact type, and the custom-type ids present.
+ * The per-version artifact bytes live in files (artifacts/<type>/v####.md), not
+ * here — the manifest only points at the current version so a consumer can open
+ * a workspace without scanning every file.
+ *
+ * Codec contract (arch-review / test-strategy G11): parsing is FAIL-LOUD. A
+ * malformed or absent manifest must surface as a typed `CorpusError` of kind
+ * "io" or "browser-storage-cleared", never a silent default-empty manifest that
+ * would masquerade as "this workspace has no work in it" and mask data loss.
+ */
+
+import { CorpusError } from "./types";
+
+export const MANIFEST_VERSION = 1;
+
+/** Pointer to the current version of one artifact type. `currentVersion` is the
+ *  1-based version number whose file is artifacts/<type>/v####.md. */
+export interface ArtifactPointer {
+  type: string;
+  currentVersion: number;
+}
+
+export interface SourceRef {
+  id: string;
+  label: string;
+  /** File extension (no dot) of the stored source bytes under sources/. */
+  ext: string;
+}
+
+export interface WorkspaceManifest {
+  manifestVersion: number;
+  title: string;
+  createdAt: string;
+  updatedAt: string;
+  sources: SourceRef[];
+  artifacts: ArtifactPointer[];
+  customTypeIds: string[];
+}
+
+export function createManifest(title: string, now = new Date().toISOString()): WorkspaceManifest {
+  return {
+    manifestVersion: MANIFEST_VERSION,
+    title,
+    createdAt: now,
+    updatedAt: now,
+    sources: [],
+    artifacts: [],
+    customTypeIds: [],
+  };
+}
+
+export function serializeManifest(m: WorkspaceManifest): Uint8Array {
+  return new TextEncoder().encode(JSON.stringify(m, null, 2));
+}
+
+function isObject(v: unknown): v is Record<string, unknown> {
+  return typeof v === "object" && v !== null && !Array.isArray(v);
+}
+
+function fail(reason: string): never {
+  // Manifest parse failure is an i/o-class corruption of the workspace index.
+  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
+}
+
+/**
+ * Parse + validate manifest bytes. Throws a `CorpusError` on any malformation —
+ * a `null` input (file absent) is the caller's responsibility to detect via
+ * `CorpusFS.readFile` returning `null`; passing `null` here is itself an error.
+ */
+export function parseManifest(bytes: Uint8Array | null): WorkspaceManifest {
+  if (bytes === null) fail("manifest file is absent");
+  let raw: unknown;
+  try {
+    raw = JSON.parse(new TextDecoder().decode(bytes));
+  } catch (e) {
+    fail(`not valid JSON (${(e as Error).message})`);
+  }
+  if (!isObject(raw)) fail("top-level value is not an object");
+  if (typeof raw.title !== "string") fail("missing required field: title");
+  if (typeof raw.manifestVersion !== "number") fail("missing required field: manifestVersion");
+
+  const sources: SourceRef[] = Array.isArray(raw.sources)
+    ? raw.sources.filter(isObject).map((s) => {
+        if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
+        return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
+      })
+    : fail("missing or invalid field: sources");
+
+  const artifacts: ArtifactPointer[] = Array.isArray(raw.artifacts)
+    ? raw.artifacts.filter(isObject).map((a) => {
+        if (typeof a.type !== "string" || typeof a.currentVersion !== "number") {
+          fail("artifact pointer missing type/currentVersion");
+        }
+        return { type: a.type as string, currentVersion: a.currentVersion as number };
+      })
+    : fail("missing or invalid field: artifacts");
+
+  const customTypeIds: string[] = Array.isArray(raw.customTypeIds)
+    ? raw.customTypeIds.filter((x): x is string => typeof x === "string")
+    : fail("missing or invalid field: customTypeIds");
+
+  return {
+    manifestVersion: raw.manifestVersion,
+    title: raw.title,
+    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
+    updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
+    sources,
+    artifacts,
+    customTypeIds,
+  };
+}
diff --git a/app/lib/corpus/opfsAdapter.ts b/app/lib/corpus/opfsAdapter.ts
new file mode 100644
index 0000000..cec8e02
--- /dev/null
+++ b/app/lib/corpus/opfsAdapter.ts
@@ -0,0 +1,176 @@
+/**
+ * OPFS-backed `CorpusFS` adapter (DD-009 sub-task S1).
+ *
+ * Implements the corpus filesystem over the Origin Private File System
+ * (`navigator.storage.getDirectory()`). This is the always-on local working
+ * copy; FSA mirror (S2) and git (S3) layer on top.
+ *
+ * Two contracts this file is responsible for (test-strategy G7/G8, arch-review):
+ *  - SSR / unavailable guard: any call in an environment without
+ *    `navigator.storage.getDirectory` rejects with a typed `CorpusError`
+ *    ({kind:"unavailable"}), never a raw `TypeError`.
+ *  - Failure reification: a quota failure rejects with {kind:"quota-exceeded",
+ *    substrate:"opfs"} — it is NOT swallowed with console.warn the way the
+ *    legacy localStorage adapter does (workspaceStore.ts:44-46).
+ *
+ * OPFS handle types are declared locally rather than relying on lib.dom, whose
+ * OPFS surface (notably async `keys()`) varies by TypeScript version — keeping
+ * our own minimal shapes makes the build stable across upgrades.
+ */
+
+import type { CorpusFS, CorpusStat } from "./types";
+import { CorpusError } from "./types";
+
+// --- Minimal local OPFS typings ---
+interface OpfsWritable {
+  // We only ever write Uint8Array; typing it narrowly avoids the lib.dom
+  // BufferSource/ArrayBufferLike strictness mismatch across TS versions.
+  write(data: Uint8Array): Promise<void>;
+  close(): Promise<void>;
+}
+interface OpfsFileHandle {
+  getFile(): Promise<{ size: number; arrayBuffer(): Promise<ArrayBuffer> }>;
+  createWritable(): Promise<OpfsWritable>;
+}
+interface OpfsDirHandle {
+  getFileHandle(name: string, opts?: { create?: boolean }): Promise<OpfsFileHandle>;
+  getDirectoryHandle(name: string, opts?: { create?: boolean }): Promise<OpfsDirHandle>;
+  removeEntry(name: string, opts?: { recursive?: boolean }): Promise<void>;
+  keys(): AsyncIterableIterator<string>;
+}
+
+function isNotFound(e: unknown): boolean {
+  return e instanceof DOMException && (e.name === "NotFoundError" || e.name === "TypeMismatchError");
+}
+function isQuota(e: unknown): boolean {
+  return e instanceof DOMException && (e.name === "QuotaExceededError" || e.name === "QUOTA_EXCEEDED_ERR");
+}
+
+async function getRoot(): Promise<OpfsDirHandle> {
+  const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
+  if (!storage || typeof storage.getDirectory !== "function") {
+    throw new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" });
+  }
+  return (await storage.getDirectory()) as unknown as OpfsDirHandle;
+}
+
+function splitPath(path: string): { dirs: string[]; name: string } {
+  const parts = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
+  const name = parts.pop();
+  if (!name) throw new CorpusError({ kind: "io", path, reason: "path has no file component" });
+  return { dirs: parts, name };
+}
+
+/** Walk (optionally creating) directory handles for the given segments. Returns
+ *  null when `create` is false and a segment is missing. */
+async function walkDir(root: OpfsDirHandle, dirs: string[], create: boolean): Promise<OpfsDirHandle | null> {
+  let cur = root;
+  for (const d of dirs) {
+    try {
+      cur = await cur.getDirectoryHandle(d, { create });
+    } catch (e) {
+      if (!create && isNotFound(e)) return null;
+      throw e;
+    }
+  }
+  return cur;
+}
+
+function wrap(path: string, e: unknown): never {
+  if (e instanceof CorpusError) throw e;
+  if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
+  throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
+}
+
+export function createOpfsCorpusFs(): CorpusFS {
+  return {
+    async readFile(path) {
+      try {
+        const root = await getRoot();
+        const { dirs, name } = splitPath(path);
+        const dir = await walkDir(root, dirs, false);
+        if (!dir) return null;
+        let fh: OpfsFileHandle;
+        try {
+          fh = await dir.getFileHandle(name, { create: false });
+        } catch (e) {
+          if (isNotFound(e)) return null;
+          throw e;
+        }
+        const file = await fh.getFile();
+        return new Uint8Array(await file.arrayBuffer());
+      } catch (e) {
+        wrap(path, e);
+      }
+    },
+
+    async writeFile(path, bytes) {
+      try {
+        const root = await getRoot();
+        const { dirs, name } = splitPath(path);
+        const dir = await walkDir(root, dirs, true);
+        const fh = await dir!.getFileHandle(name, { create: true });
+        const w = await fh.createWritable();
+        try {
+          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
+          await w.write(bytes);
+        } finally {
+          await w.close();
+        }
+      } catch (e) {
+        wrap(path, e);
+      }
+    },
+
+    async readdir(path) {
+      try {
+        const root = await getRoot();
+        const dirs = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
+        const dir = await walkDir(root, dirs, false);
+        if (!dir) return [];
+        const names: string[] = [];
+        for await (const key of dir.keys()) names.push(key);
+        return names.sort();
+      } catch (e) {
+        wrap(path, e);
+      }
+    },
+
+    async rm(path) {
+      try {
+        const root = await getRoot();
+        const { dirs, name } = splitPath(path);
+        const dir = await walkDir(root, dirs, false);
+        if (!dir) return; // idempotent: parent dir missing -> nothing to remove
+        try {
+          await dir.removeEntry(name);
+        } catch (e) {
+          if (isNotFound(e)) return; // idempotent: file already gone
+          throw e;
+        }
+      } catch (e) {
+        wrap(path, e);
+      }
+    },
+
+    async stat(path): Promise<CorpusStat | null> {
+      try {
+        const root = await getRoot();
+        const { dirs, name } = splitPath(path);
+        const dir = await walkDir(root, dirs, false);
+        if (!dir) return null;
+        let fh: OpfsFileHandle;
+        try {
+          fh = await dir.getFileHandle(name, { create: false });
+        } catch (e) {
+          if (isNotFound(e)) return null;
+          throw e;
+        }
+        const file = await fh.getFile();
+        return { size: file.size };
+      } catch (e) {
+        wrap(path, e);
+      }
+    },
+  };
+}
diff --git a/app/lib/corpus/paths.ts b/app/lib/corpus/paths.ts
new file mode 100644
index 0000000..901e42c
--- /dev/null
+++ b/app/lib/corpus/paths.ts
@@ -0,0 +1,110 @@
+/**
+ * Corpus folder-layout path builders (DD-009 sub-task S0).
+ *
+ * The on-disk shape (DD-009 §Folder layout):
+ *
+ *   <corpus-root>/
+ *   ├── settings.json
+ *   └── workspaces/<slug>/
+ *       ├── workspace.json
+ *       ├── sources/<source-id>.<ext>
+ *       ├── artifacts/<type>/v####.md   (+ meta.json per type)
+ *       ├── custom-types/<custom-type-id>.json
+ *       └── decomposition/...
+ *
+ * All builders return POSIX-style paths relative to the corpus root (no leading
+ * slash), suitable for passing straight to a `CorpusFS`. The only source of
+ * corpus paths is this module — callers must never hand-concatenate, so the
+ * traversal guard in `workspaceSlug` is the single choke point that keeps
+ * untrusted workspace titles inside `workspaces/`.
+ */
+
+/** Width of the zero-padded version number in artifact filenames (v0001.md). */
+const VERSION_PAD = 4;
+
+/** Characters allowed in a sanitized slug or id segment. Everything else is
+ *  collapsed to a hyphen so a value can never contain "/", "\\", "." runs, or
+ *  control characters that would let it escape its directory. */
+const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;
+
+/**
+ * Sanitize a workspace title into a filesystem-safe slug that cannot escape
+ * `workspaces/`. Strips path separators, dot-segments, and unicode; collapses
+ * runs of unsafe characters to a single hyphen; trims leading/trailing hyphens.
+ * Throws if nothing safe remains (an all-unsafe title must not silently become "").
+ */
+export function workspaceSlug(title: string): string {
+  const slug = title
+    .normalize("NFKD")
+    .replace(SAFE_SEGMENT, "-")
+    .replace(/-{2,}/g, "-")
+    .replace(/^-+|-+$/g, "")
+    .toLowerCase();
+  if (!slug) {
+    throw new Error(`workspace title produced an empty slug: ${JSON.stringify(title)}`);
+  }
+  return slug;
+}
+
+/** Sanitize an arbitrary id (source id, custom-type id, artifact type) for use
+ *  as a single path segment. Same guarantees as `workspaceSlug` but preserves
+ *  case (ids are typically already safe, e.g. "custom-abc123"). */
+export function safeSegment(id: string): string {
+  const seg = id.normalize("NFKD").replace(SAFE_SEGMENT, "-").replace(/-{2,}/g, "-").replace(/^-+|-+$/g, "");
+  if (!seg) {
+    throw new Error(`id produced an empty path segment: ${JSON.stringify(id)}`);
+  }
+  return seg;
+}
+
+/** Sanitize a file extension to alphanumerics; defaults to "bin" if empty. */
+function safeExt(ext: string): string {
+  const e = ext.replace(/^\.+/, "").replace(/[^a-zA-Z0-9]+/g, "").toLowerCase();
+  return e || "bin";
+}
+
+// --- Path builders (all relative to corpus root) ---------------------------
+
+export const SETTINGS_PATH = "settings.json";
+
+export function workspaceDir(slug: string): string {
+  return `workspaces/${workspaceSlug(slug)}`;
+}
+
+export function workspaceManifestPath(slug: string): string {
+  return `${workspaceDir(slug)}/workspace.json`;
+}
+
+export function sourcePath(slug: string, sourceId: string, ext: string): string {
+  return `${workspaceDir(slug)}/sources/${safeSegment(sourceId)}.${safeExt(ext)}`;
+}
+
+export function artifactDir(slug: string, artifactType: string): string {
+  return `${workspaceDir(slug)}/artifacts/${safeSegment(artifactType)}`;
+}
+
+/** Zero-padded version file, e.g. artifactVersionPath(s,"semiformal",1) ->
+ *  "workspaces/<s>/artifacts/semiformal/v0001.md". `version` is 1-based. */
+export function artifactVersionPath(slug: string, artifactType: string, version: number): string {
+  if (!Number.isInteger(version) || version < 1) {
+    throw new Error(`artifact version must be a positive integer, got ${version}`);
+  }
+  const v = String(version).padStart(VERSION_PAD, "0");
+  return `${artifactDir(slug, artifactType)}/v${v}.md`;
+}
+
+export function artifactMetaPath(slug: string, artifactType: string): string {
+  return `${artifactDir(slug, artifactType)}/meta.json`;
+}
+
+export function customTypePath(slug: string, customTypeId: string): string {
+  return `${workspaceDir(slug)}/custom-types/${safeSegment(customTypeId)}.json`;
+}
+
+export function decompositionDir(slug: string): string {
+  return `${workspaceDir(slug)}/decomposition`;
+}
+
+export function decompositionGraphLayoutPath(slug: string): string {
+  return `${decompositionDir(slug)}/graph-layout.json`;
+}
diff --git a/app/lib/corpus/storeAdapter.ts b/app/lib/corpus/storeAdapter.ts
new file mode 100644
index 0000000..3be49c2
--- /dev/null
+++ b/app/lib/corpus/storeAdapter.ts
@@ -0,0 +1,76 @@
+/**
+ * Storage-seam selection for the Zustand workspace store (DD-009 sub-task S1).
+ *
+ * `resolveWorkspaceStorage()` returns the zustand persist storage: the existing
+ * debounced localStorage adapter by default, or a CorpusFS-backed storage when
+ * the dev flag is on. The injection seam is typed as `CorpusFS` (arch-review
+ * finding 3) so the S3 worker-proxy implementation drops in here without the
+ * store ever knowing which adapter it talks to.
+ *
+ * In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode) —
+ * the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not
+ * used by the store until S4. This keeps S1 a pure substrate swap.
+ */
+
+import type { StateStorage } from "zustand/middleware";
+import type { CorpusFS } from "./types";
+import { createOpfsCorpusFs } from "./opfsAdapter";
+import { isCorpusEnabled } from "./flag";
+
+// ---------------------------------------------------------------------------
+// Default: debounced localStorage (moved verbatim from workspaceStore.ts so the
+// OFF path is byte-for-byte the prior behavior — see the characterization test).
+// Reads are synchronous (instant); writes are debounced by 300ms.
+// ---------------------------------------------------------------------------
+export function createDebouncedLocalStorage(): StateStorage {
+  let pending: ReturnType<typeof setTimeout> | null = null;
+  return {
+    getItem: (name) => localStorage.getItem(name),
+    setItem: (name, value) => {
+      if (pending) clearTimeout(pending);
+      pending = setTimeout(() => {
+        try {
+          localStorage.setItem(name, value);
+        } catch (e) {
+          console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
+        }
+        pending = null;
+      }, 300);
+    },
+    removeItem: (name) => {
+      if (pending) clearTimeout(pending);
+      pending = null;
+      localStorage.removeItem(name);
+    },
+  };
+}
+
+// ---------------------------------------------------------------------------
+// Corpus-backed storage: stores the persist blob as one file under `state/`.
+// The seam type is CorpusFS, not a concrete adapter (arch-review finding 3).
+// ---------------------------------------------------------------------------
+export function createCorpusBackedStorage(fs: CorpusFS): StateStorage {
+  const enc = new TextEncoder();
+  const dec = new TextDecoder();
+  const pathFor = (name: string) => `state/${name}.json`;
+  return {
+    getItem: async (name) => {
+      const bytes = await fs.readFile(pathFor(name));
+      return bytes ? dec.decode(bytes) : null;
+    },
+    setItem: async (name, value) => {
+      await fs.writeFile(pathFor(name), enc.encode(value));
+    },
+    removeItem: async (name) => {
+      await fs.rm(pathFor(name));
+    },
+  };
+}
+
+/** Selected once when the store's persist middleware initializes. */
+export function resolveWorkspaceStorage(): StateStorage {
+  if (isCorpusEnabled()) {
+    return createCorpusBackedStorage(createOpfsCorpusFs());
+  }
+  return createDebouncedLocalStorage();
+}
diff --git a/app/lib/corpus/types.ts b/app/lib/corpus/types.ts
new file mode 100644
index 0000000..358519d
--- /dev/null
+++ b/app/lib/corpus/types.ts
@@ -0,0 +1,125 @@
+/**
+ * Corpus filesystem abstraction (DD-009 sub-task S0+S1).
+ *
+ * `CorpusFS` is the single FS seam every later sub-task binds to:
+ *   - S1 OPFS adapter implements it (always-on local cache)
+ *   - S2 FSA folder mirror writes through it
+ *   - S4 migration + session model reads/writes the folder layout through it
+ *
+ * Design notes (see docs/decisions/009-artifact-corpus-architecture.md and
+ * docs/reviews/architecture-review.md):
+ *  - Bytes + paths, not strings + keys. Sources are binary (PDFs), so the
+ *    interface is `Uint8Array`-oriented; do not narrow it to strings.
+ *  - Async everywhere. OPFS and FSA are both async, and DD-009 mandates the
+ *    writer eventually run in a worker (S3). An async interface makes that a
+ *    transport swap, not an interface change — so consumers MUST bind to this
+ *    interface, never to a concrete adapter (arch-review finding 3).
+ *  - "Not found" is `null` from `readFile`/`stat` and `[]` from `readdir`;
+ *    everything else rejects with a `CorpusError`. Callers never see `undefined`.
+ *  - GIT IS NOT PART OF THIS INTERFACE. S3's commit/log/push/pull belong on a
+ *    separate `CorpusGit` interface that operates *over* a `CorpusFS`. Do not add
+ *    git methods here — that would force the in-memory fake and every non-git
+ *    consumer to stub operations they don't use (arch-review finding 2, ISP).
+ */
+
+// ---------------------------------------------------------------------------
+// Error model — one source of truth for the kind set (arch-review finding 1).
+// `CorpusError` is the thrown form; `CorpusWorkerError` is its postMessage-
+// serializable twin. They differ only in transport, never in the kind set.
+// ---------------------------------------------------------------------------
+
+/** Which substrate raised a space/quota failure. Substrate-neutral so S2 (FSA)
+ *  and future caches reuse the same `quota-exceeded` kind rather than minting
+ *  adapter-specific kinds the exhaustive switches would all have to learn. */
+export type CorpusSubstrate = "opfs" | "fsa" | "remote";
+
+/**
+ * The complete set of corpus failure kinds. Every exhaustive `switch` over a
+ * corpus error binds to this union; adding a kind here forces every consumer to
+ * handle it at compile time (the failure-driven-UI mandate, DD-009 §Failure-driven).
+ */
+export type CorpusErrorKind =
+  | { kind: "not-found"; path: string }
+  | { kind: "quota-exceeded"; substrate: CorpusSubstrate; needed?: number; available?: number }
+  | { kind: "unavailable"; reason: string } // e.g. SSR / no navigator.storage
+  | { kind: "io"; path: string; reason: string }
+  | { kind: "fsa-permission-revoked" }
+  | { kind: "remote-auth-expired" }
+  | { kind: "browser-storage-cleared" }
+  | { kind: "git-conflict"; path: string };
+
+/** Thrown form of a corpus failure. `detail` carries the discriminated kind. */
+export class CorpusError extends Error {
+  readonly detail: CorpusErrorKind;
+  constructor(detail: CorpusErrorKind, message?: string) {
+    super(message ?? describeCorpusError(detail));
+    this.name = "CorpusError";
+    this.detail = detail;
+  }
+}
+
+/** Serializable twin for crossing a worker boundary (S3). Reconstruct with
+ *  `new CorpusError(payload.detail, payload.message)` on the main thread. */
+export type CorpusWorkerError = {
+  __corpusError: true;
+  detail: CorpusErrorKind;
+  message: string;
+};
+
+export function toWorkerError(err: CorpusError): CorpusWorkerError {
+  return { __corpusError: true, detail: err.detail, message: err.message };
+}
+
+export function isCorpusWorkerError(v: unknown): v is CorpusWorkerError {
+  return typeof v === "object" && v !== null && (v as { __corpusError?: unknown }).__corpusError === true;
+}
+
+/** Human-readable default message for a kind (used when no override is given). */
+export function describeCorpusError(d: CorpusErrorKind): string {
+  switch (d.kind) {
+    case "not-found": return `corpus path not found: ${d.path}`;
+    case "quota-exceeded": return `corpus storage quota exceeded (${d.substrate})`;
+    case "unavailable": return `corpus storage unavailable: ${d.reason}`;
+    case "io": return `corpus i/o error at ${d.path}: ${d.reason}`;
+    case "fsa-permission-revoked": return "corpus folder permission was revoked";
+    case "remote-auth-expired": return "corpus remote authentication expired";
+    case "browser-storage-cleared": return "corpus browser storage was cleared";
+    case "git-conflict": return `corpus git conflict at ${d.path}`;
+    default: return assertNever(d);
+  }
+}
+
+/** Compile-time exhaustiveness guard. Reaching this at runtime means a kind was
+ *  added to `CorpusErrorKind` without updating a switch — TS flags it first. */
+export function assertNever(x: never): never {
+  throw new Error(`unhandled corpus error kind: ${JSON.stringify(x)}`);
+}
+
+// ---------------------------------------------------------------------------
+// The filesystem interface.
+// ---------------------------------------------------------------------------
+
+export interface CorpusStat {
+  size: number;
+}
+
+/**
+ * Async, bytes-and-paths filesystem seam. Paths are POSIX-style, relative to the
+ * corpus root, using "/" separators and no leading slash (e.g.
+ * "workspaces/my-slug/artifacts/semiformal/v0001.md"). Implementations create
+ * intermediate directories on write.
+ */
+export interface CorpusFS {
+  /** Returns file bytes, or `null` if the path does not exist. Rejects with a
+   *  `CorpusError` for any other failure. */
+  readFile(path: string): Promise<Uint8Array | null>;
+  /** Writes bytes, creating intermediate directories as needed. */
+  writeFile(path: string, bytes: Uint8Array): Promise<void>;
+  /** Lists immediate child names of a directory; `[]` if the directory is
+   *  missing or empty. Names only, not full paths. */
+  readdir(path: string): Promise<string[]>;
+  /** Removes a file. Idempotent: resolves (no-op) if the path does not exist. */
+  rm(path: string): Promise<void>;
+  /** Returns `{ size }` for an existing file, or `null` if it does not exist. */
+  stat(path: string): Promise<CorpusStat | null>;
+}
diff --git a/app/lib/stores/__tests__/workspaceStore-characterization.test.ts b/app/lib/stores/__tests__/workspaceStore-characterization.test.ts
new file mode 100644
index 0000000..7aa786f
--- /dev/null
+++ b/app/lib/stores/__tests__/workspaceStore-characterization.test.ts
@@ -0,0 +1,106 @@
+/**
+ * Characterization baseline for the CURRENT localStorage persistence behavior
+ * (DD-009 sub-task S1, test-strategy G16).
+ *
+ * This is the equivalence target: when the corpus/OPFS path is wired (S4), the
+ * round-trip it produces must match what this test locks in. It asserts the
+ * existing behavior as-is — if a change to the store breaks one of these, that's
+ * a deliberate decision to make, not a silent drift.
+ */
+
+import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
+import { useWorkspaceStore } from "../workspaceStore";
+import type { ArtifactRecord } from "@/app/lib/types/artifactStore";
+import type { CustomArtifactTypeDefinition } from "@/app/lib/types/customArtifact";
+
+const STORE_KEY = "workspace-zustand-v1";
+
+beforeEach(() => {
+  vi.useFakeTimers();
+  localStorage.clear();
+  useWorkspaceStore.setState(useWorkspaceStore.getInitialState());
+});
+
+afterEach(() => {
+  vi.useRealTimers();
+});
+
+function threeVersionRecord(): ArtifactRecord {
+  return {
+    type: "causal-graph",
+    currentVersionIndex: 2,
+    versions: [
+      { id: "v1", content: '{"variables":["a"]}', createdAt: "2026-01-01T00:00:00Z", source: "generated" },
+      { id: "v2", content: '{"variables":["a","b"]}', createdAt: "2026-01-02T00:00:00Z", source: "ai-edit", editInstruction: "add b" },
+      { id: "v3", content: '{"variables":["a","b","c"]}', createdAt: "2026-01-03T00:00:00Z", source: "manual-edit" },
+    ],
+  };
+}
+
+function customTypes(): { defs: CustomArtifactTypeDefinition[]; data: Record<string, string | null> } {
+  const defs: CustomArtifactTypeDefinition[] = [
+    { id: "custom-eth", name: "Ethical Analysis", chipLabel: "Ethics", description: "d", whenToUse: "w", systemPrompt: "p1", outputFormat: "text", createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:00:00Z" },
+    { id: "custom-risk", name: "Risk Map", chipLabel: "Risk", description: "d", whenToUse: "w", systemPrompt: "p2", outputFormat: "json", createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:00:00Z" },
+  ];
+  const data: Record<string, string | null> = { "custom-eth": "eth output", "custom-risk": '{"risks":[]}' };
+  return { defs, data };
+}
+
+describe("current localStorage persistence — characterization (G16)", () => {
+  it("persists a 3-version artifact record with all versions and currentVersionIndex intact", async () => {
+    useWorkspaceStore.setState({ artifacts: { "causal-graph": threeVersionRecord() } });
+    vi.advanceTimersByTime(300); // flush debounced write
+
+    const raw = localStorage.getItem(STORE_KEY);
+    expect(raw).not.toBeNull();
+    const rec = JSON.parse(raw!).state.artifacts["causal-graph"] as ArtifactRecord;
+    // Diagnostic: full record is serialized, not flattened to current version.
+    expect(rec.versions).toHaveLength(3);
+    expect(rec.currentVersionIndex).toBe(2);
+    expect(rec.versions.map((v) => v.content)).toEqual([
+      '{"variables":["a"]}',
+      '{"variables":["a","b"]}',
+      '{"variables":["a","b","c"]}',
+    ]);
+  });
+
+  it("persists custom artifact type definitions and their generated data", async () => {
+    const { defs, data } = customTypes();
+    useWorkspaceStore.setState({ customArtifactTypes: defs, customArtifactData: data });
+    vi.advanceTimersByTime(300);
+
+    const state = JSON.parse(localStorage.getItem(STORE_KEY)!).state;
+    expect(state.customArtifactTypes).toHaveLength(2);
+    expect(state.customArtifactData["custom-eth"]).toBe("eth output");
+    expect(state.customArtifactData["custom-risk"]).toBe('{"risks":[]}');
+  });
+
+  it("sanitizes transient verificationStatus 'verifying' to 'none' on persist", async () => {
+    useWorkspaceStore.getState().setVerificationStatus("verifying");
+    vi.advanceTimersByTime(300);
+    const state = JSON.parse(localStorage.getItem(STORE_KEY)!).state;
+    expect(state.verificationStatus).toBe("none");
+  });
+
+  it("rehydrates a full round-trip: versions and custom types survive a reload", async () => {
+    const { defs, data } = customTypes();
+    useWorkspaceStore.setState({
+      sourceText: "src",
+      artifacts: { "causal-graph": threeVersionRecord() },
+      customArtifactTypes: defs,
+      customArtifactData: data,
+    });
+    vi.advanceTimersByTime(300);
+
+    // Simulate a reload: drop in-memory state, then rehydrate from localStorage.
+    useWorkspaceStore.setState(useWorkspaceStore.getInitialState());
+    await useWorkspaceStore.persist.rehydrate();
+
+    const s = useWorkspaceStore.getState();
+    expect(s.sourceText).toBe("src");
+    expect(s.getArtifactContent("causal-graph")).toBe('{"variables":["a","b","c"]}');
+    expect(s.artifacts["causal-graph"]?.versions).toHaveLength(3);
+    expect(s.customArtifactTypes).toHaveLength(2);
+    expect(s.customArtifactData["custom-eth"]).toBe("eth output");
+  });
+});
diff --git a/app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts b/app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts
new file mode 100644
index 0000000..566daaf
--- /dev/null
+++ b/app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts
@@ -0,0 +1,83 @@
+/**
+ * Storage-seam flag routing (DD-009 S1, test-strategy G13/G14/G15).
+ *
+ * Verifies the OFF default is unchanged (localStorage, OPFS never touched) and
+ * that the CorpusFS-backed storage routes through the injected CorpusFS rather
+ * than localStorage. Uses the in-memory fake so no real OPFS is needed.
+ */
+
+import { describe, it, expect, afterEach, vi } from "vitest";
+import {
+  resolveWorkspaceStorage,
+  createCorpusBackedStorage,
+} from "@/app/lib/corpus/storeAdapter";
+import { CORPUS_FLAG_KEY } from "@/app/lib/corpus/flag";
+import { createInMemoryCorpusFs } from "@/app/lib/corpus/__tests__/inMemoryCorpusFs";
+
+const originalStorage = Object.getOwnPropertyDescriptor(navigator, "storage");
+
+afterEach(() => {
+  localStorage.clear();
+  if (originalStorage) Object.defineProperty(navigator, "storage", originalStorage);
+});
+
+describe("flag OFF (default) — localStorage, OPFS never touched (G13)", () => {
+  it("routes writes to localStorage and never calls navigator.storage.getDirectory", () => {
+    const getDirectory = vi.fn();
+    Object.defineProperty(navigator, "storage", { configurable: true, value: { getDirectory } });
+
+    vi.useFakeTimers(); // install before setItem so the debounce uses fake timers
+    const storage = resolveWorkspaceStorage();
+    storage.setItem("workspace-zustand-v1", '{"state":{"sourceText":"x"},"version":0}');
+    vi.advanceTimersByTime(300); // flush debounced localStorage write
+    vi.useRealTimers();
+
+    expect(localStorage.getItem("workspace-zustand-v1")).toContain('"sourceText":"x"');
+    expect(getDirectory).not.toHaveBeenCalled();
+  });
+});
+
+describe("CorpusFS-backed storage routes through the injected CorpusFS (G14)", () => {
+  it("writes/reads bytes via CorpusFS, not localStorage", async () => {
+    const fs = createInMemoryCorpusFs();
+    const storage = createCorpusBackedStorage(fs);
+
+    await storage.setItem("workspace-zustand-v1", '{"hello":"corpus"}');
+    // Not in localStorage:
+    expect(localStorage.getItem("workspace-zustand-v1")).toBeNull();
+    // Present in the corpus FS at the state/ path:
+    const bytes = await fs.readFile("state/workspace-zustand-v1.json");
+    expect(new TextDecoder().decode(bytes!)).toBe('{"hello":"corpus"}');
+    // getItem round-trips:
+    expect(await storage.getItem("workspace-zustand-v1")).toBe('{"hello":"corpus"}');
+    // removeItem is idempotent and clears it:
+    await storage.removeItem("workspace-zustand-v1");
+    expect(await storage.getItem("workspace-zustand-v1")).toBeNull();
+    await expect(storage.removeItem("workspace-zustand-v1")).resolves.toBeUndefined();
+  });
+});
+
+describe("flag ON — resolver selects the OPFS-backed path (G15 wiring)", () => {
+  it("routes to navigator.storage.getDirectory when the dev flag is set", async () => {
+    localStorage.setItem(CORPUS_FLAG_KEY, "1");
+    const fakeRoot = {
+      async getFileHandle() {
+        return {
+          async getFile() { return { size: 0, async arrayBuffer() { return new ArrayBuffer(0); } }; },
+          async createWritable() { return { async write() {}, async close() {} }; },
+        };
+      },
+      async getDirectoryHandle() { return fakeRoot; },
+      async removeEntry() {},
+      async *keys() {},
+    };
+    const getDirectory = vi.fn(async () => fakeRoot);
+    Object.defineProperty(navigator, "storage", { configurable: true, value: { getDirectory } });
+
+    const storage = resolveWorkspaceStorage();
+    await storage.setItem("workspace-zustand-v1", "{}");
+
+    expect(getDirectory).toHaveBeenCalled();
+    expect(localStorage.getItem("workspace-zustand-v1")).toBeNull(); // not the localStorage path
+  });
+});
diff --git a/app/lib/stores/workspaceStore.ts b/app/lib/stores/workspaceStore.ts
index 670eb36..8338be6 100644
--- a/app/lib/stores/workspaceStore.ts
+++ b/app/lib/stores/workspaceStore.ts
@@ -22,38 +22,7 @@ import type { CustomArtifactTypeDefinition, CustomArtifactTypeId } from "@/app/l
 import { loadWorkspace, sanitizeVerificationStatus, sanitizeNodeStatus, coerceDecomposition } from "@/app/lib/utils/workspacePersistence";
 import { WORKSPACE_KEY } from "@/app/lib/types/persistence";
 import type { PropositionNode } from "@/app/lib/types/decomposition";
-
-// ---------------------------------------------------------------------------
-// Debounced localStorage adapter — avoids JSON.stringify on every keystroke.
-// Reads are synchronous (instant); writes are debounced by 300ms.
-// ---------------------------------------------------------------------------
-
-function createDebouncedStorage(): {
-  getItem: (name: string) => string | null;
-  setItem: (name: string, value: string) => void;
-  removeItem: (name: string) => void;
-} {
-  let pending: ReturnType<typeof setTimeout> | null = null;
-  return {
-    getItem: (name) => localStorage.getItem(name),
-    setItem: (name, value) => {
-      if (pending) clearTimeout(pending);
-      pending = setTimeout(() => {
-        try {
-          localStorage.setItem(name, value);
-        } catch (e) {
-          console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
-        }
-        pending = null;
-      }, 300);
-    },
-    removeItem: (name) => {
-      if (pending) clearTimeout(pending);
-      pending = null;
-      localStorage.removeItem(name);
-    },
-  };
-}
+import { resolveWorkspaceStorage } from "@/app/lib/corpus/storeAdapter";
 
 // ---------------------------------------------------------------------------
 // Rehydration validation — coerce deserialized localStorage data to safe types.
@@ -524,7 +493,10 @@ export const useWorkspaceStore = create<WorkspaceState & WorkspaceActions>()(
     }),
     {
       name: "workspace-zustand-v1",
-      storage: createJSONStorage(createDebouncedStorage),
+      // Storage seam is selected here (DD-009 S1): debounced localStorage by
+      // default, or a CorpusFS-backed adapter when the dev flag is on. The seam
+      // is typed as CorpusFS so the S3 worker-proxy is a drop-in.
+      storage: createJSONStorage(resolveWorkspaceStorage),
       // SSR safe: render defaults first, hydrate in useEffect via rehydrate()
       skipHydration: true,
       // Validate deserialized localStorage data before merging into the store.
```
