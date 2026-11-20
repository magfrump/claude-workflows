## Dependency Upgrade Evaluation: ledgerline 1.9.0 → 2.0.0

### Summary
**Recommendation:** Defer
**Breaking change impact:** Moderate. No call-site changes are needed, but the Node.js 22 runtime requirement breaks the current `node:20-alpine` image.
**Estimated effort:** hours, after the runtime has moved to Node 22. The ledgerline bump itself is minutes.
**Risk:** High if merged as-is, because the worker throws at import time on Node 20. Low once the project runs on Node 22.
**Audit state:** Unverified. No audit was run because there was no shell or registry access in this session.

**Short answer for this week's batch:** do not merge this Dependabot PR. Hold or close it. Move the runtime to Node 22 as its own change first, then re-open the bump.

### Motivation
There isn't a strong one. No feature request depends on 2.0.0, and the release notes list no security fixes. The only gain is smaller PDFs from default font subsetting. This is a "keeping current" upgrade, so it has low urgency and must justify its cost. The cost here is a runtime upgrade.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| Requires Node.js ≥22. Uses `process.getBuiltinModule()` and **throws at import time** on older runtimes. `engines.node` is `>=22`. | `Dockerfile` (`FROM node:20-alpine`), the CI pipeline (same image), `package.json` (`"engines": { "node": ">=18" }`), and every process that `require("ledgerline")`s, i.e. `src/render/invoice.js` and through it the worker. | Move the base image to `node:22-alpine` (or later), set `engines.node` to `>=22`, and run the full suite on the new image. Do this in a **separate PR** before the ledgerline bump. |

The failure is at import, not at render time. If `src/worker.js` loads the renderer eagerly, the container will crash on boot. If it loads lazily, the failure will appear on the first invoice render. Either way, invoices will stop being produced.

### Breaking Changes That Don't Affect This Project
- **`Document#image()` alias removed.** The project never calls `image()` or `picture()`. Not affected.
- **`doc.table()` no longer accepts a bare array of column names.** `invoice.js` already passes `{ columns: ["description", "qty", "amount"] }`, which is the supported form. Not affected.

### Transitive Effects
- **Runtime floor rises from 18 to 22.** Our `engines` declaration (`>=18`) would become false. Node 18 and Node 20 are both past end-of-life as of today (2026-11-20), based on my knowledge of the Node release schedule. I have not verified this in this session. So the runtime move to 22 is worth doing on its own merits, separate from ledgerline.
- **`npm ci` may not catch this.** By default npm only *warns* on an `engines` mismatch (EBADENGINE) unless `engine-strict` is set. This is a prediction from npm's documented behaviour and was not observed here. So the build step can succeed and the failure only shows at runtime.
- **CI should catch it, if a test imports the renderer.** CI runs on the same Node 20 image. If the Dependabot PR's CI is **green**, treat that as a test-coverage gap to investigate, not as evidence the upgrade is safe.
- **Peer dependencies or conflicts:** none are mentioned in the release notes. Unverified against the lockfile.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `npm audit` (on 1.9.x lockfile and on Dependabot branch) | — | — | Unverified. Recommended pre-merge check. |
| `npm ls ledgerline` (resolved version in current lockfile) | — | — | Unverified. Recommended pre-merge check. |
| `npm ci --omit=dev` on `node:20-alpine` with ledgerline 2.0.0 | — | — | Unverified. Recommended pre-merge check. |
| `node -e 'require("ledgerline")'` on `node:20-alpine` with 2.0.0 (expected to throw per release notes) | — | — | Unverified. Recommended pre-merge check. |
| CI result of the Dependabot PR | — | — | Unverified. Recommended pre-merge check. |
| Test suite on `node:22-alpine` with 2.0.0 | — | — | Unverified. Recommended pre-merge check. |

None of these commands were run in this session, because no shell, registry, or repository access was available.

### Risk Factors
- **Hard failure on the current runtime.** This is the deciding factor, covered above.
- **Font subsetting changes output bytes.** Subsetting is normally invisible to anyone viewing the PDF. Check the following:
  - Byte-level or hash-based snapshot tests of rendered PDFs will break and need regenerating.
  - Any downstream step that edits or stamps the PDFs, or appends text, may lack glyphs that were not in the original subset.
  - Do a visual spot-check of invoices with non-ASCII content (customer names, currency symbols) to confirm glyphs render.
- **Latent issue on the current version, independent of this PR.** `invoice.js` calls `doc.total(invoice.total, { currency: invoice.currency })`, but the `{ currency }` option was added in **1.10.0**. The manifest floor `^1.9.0` lets a lockfile resolve to 1.9.x, where that option is unsupported and may be silently ignored. If so, invoices would render without the intended currency formatting. Check the resolved version (`npm ls ledgerline`, Unverified above). Regardless of the result, raise the floor to `^1.10.0` now, staying within 1.x.
- **Detectability:** the import-time throw is loud and immediate, given test coverage of the renderer. Font-subsetting effects are quiet and would only show up in visual review or downstream tooling.

### Rollback Plan (precondition — complete before starting Migration Plan)

**Exact rollback commands** (for the later ledgerline 2.0.0 bump, once on Node 22):
```
git checkout <pre-upgrade-commit> -- package.json package-lock.json
npm ci --omit=dev
docker build -t billing-worker:rollback-check .
# No data or config changes are part of this upgrade; nothing else to unwind.
```
If the Node 22 runtime PR also needs reverting, restore the `Dockerfile` the same way: `git checkout <pre-runtime-commit> -- Dockerfile package.json package-lock.json`. Then rebuild.

**Verification step** (run after rollback; must pass to confirm rollback worked):
```
docker run --rm billing-worker:rollback-check node -e '
  require("./src/render/invoice.js").renderInvoice({
    number: "RB-1", currency: "EUR", total: 10,
    lines: [{ description: "x", qty: 1, amount: 10 }]
  }).then(b => { if (!b || b.length === 0) process.exit(1); console.log("ok", b.length); })'
```
This exercises the only call site. It would fail if the lockfile still resolved 2.0.0 on a Node 20 image (throws at import), or if rendering were broken. Also confirm that `npm ls ledgerline` shows the 1.x version.

**Rehearsal status:** [ ] Not rehearsed. Rehearse on a scratch branch (e.g. `scratch/ledgerline-2-rollback`) and capture the verification output before starting the migration below.

### Migration Plan
When you take this up, keep the runtime change and the dependency bump separate:

1. **Now, independent of this PR:** change `"ledgerline": "^1.9.0"` to `"^1.10.0"` and confirm the lockfile resolves ≥1.10.0, so the `{ currency }` option used in `invoice.js` is actually supported.
2. **Runtime PR:** change `FROM node:20-alpine` to `FROM node:22-alpine` in the `Dockerfile` and the CI image, and set `"engines": { "node": ">=22" }`. Run the full suite and boot the worker. Ship it and let it settle.
3. **Make sure a test imports and calls `renderInvoice`,** so CI would catch an import-time failure.
4. **Rehearse the rollback** above on a scratch branch.
5. **Re-open the ledgerline bump:** set `"ledgerline": "^2.0.0"`, run `npm install` to regenerate the lockfile, then `npm ci`.
6. **No call-site edits are needed.** `invoice.js` already uses the `{ columns }` form and does not use `image()`.
7. **Run tests.** Regenerate any PDF byte or hash snapshots and review the diff.
8. **Visually compare** a few rendered invoices from before and after, including ones with non-ASCII text and several currencies. Check whether any downstream PDF post-processing is affected by font subsetting.
9. **Run `npm audit`** on the new lockfile and record the advisory-DB state. A security-reviewer pass is not required, since this isn't CVE-driven and isn't a security-relevant package.

### If Not Upgrading
Staying on 1.x costs nothing functionally today. 1.10.x supports everything the project uses. Revisit when either:
- the runtime moves to Node 22, which is warranted anyway because Node 20 is past EOL, or
- a 1.x security advisory appears with no 1.x patch.

When either happens, the ledgerline bump becomes a low-risk, minutes-sized change. The step to do this week is raising the floor to `^1.10.0`.
