## Dependency Upgrade Evaluation: ledgerline 1.9.0 → 2.0.0

### Summary
**Recommendation:** Don't merge this PR this week. Close it or hold it until the runtime is on Node 22 or later. After that runtime change ships, this bump becomes a low-risk merge.
**Breaking change impact:** None at the call site. The runtime requirement is a hard blocker.
**Estimated effort:** Minutes for the bump itself. Hours for the Node 20 → 22 runtime upgrade it depends on.
**Risk:** High if merged as-is. Predicted: the worker crashes when the module loads. Low after the runtime upgrade.
**Audit state:** Unverified. No shell or registry access in this session, and no code-fact-check report was provided.

### Motivation
This is a routine Dependabot bump. No feature is waiting on it, and no security advisory was cited. The release notes list no security fixes, so "stay current" is the only reason to take it. By itself that is not enough to justify a major-version bump that needs a runtime change.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| Requires Node.js ≥ 22. Uses `process.getBuiltinModule()` and **throws at import time** on older runtimes. | `Dockerfile` (`FROM node:20-alpine`), `.ci/pipeline.yml` (same image), `package.json` (`engines.node: ">=18"`). The throw happens at `require("ledgerline")` in `src/render/invoice.js`. | Move the image to `node:22-alpine` (or `node:24-alpine`) and set `engines.node` to `">=22"`. Do this as a separate change, ship it, and only then take this bump. |

Expected failure mode (a prediction from the release notes, not observed): npm does not enforce `engines` by default, so `npm ci --omit=dev` on Node 20 most likely succeeds, with at most an `EBADENGINE` warning. The worker then fails when it loads `src/render/invoice.js`. If `worker.js` requires that module at startup, the container crash-loops. If it requires it lazily, invoice rendering fails at runtime. CI uses the same image, so it catches this only if a test actually loads `src/render/invoice.js`. Confirm that before relying on CI as the safety net.

### Breaking Changes That Don't Affect This Project
- **Removed `Document#image()` alias.** Not used. The only call site uses `heading`, `table`, `total` and `toBuffer`.
- **`doc.table()` no longer accepts a bare array of column names.** Not affected. We already pass `{ columns: ["description", "qty", "amount"] }`.

### Transitive Effects
- **Runtime floor rises to Node 22.** This is the change that matters, covered above.
- **The Node 20 runtime is past end of life.** Node 20 left support on 2026-04-30, roughly seven months before today, 2026-11-20. That is a reason to do the runtime upgrade on its own merits. Doing so also unblocks this bump.
- **Existing manifest floor is too low.** `doc.total(..., { currency })` uses an option added in **1.10.0**, but `package.json` allows `^1.9.0`, and Dependabot reports the current version as 1.9.0. Two possibilities:
  - The lockfile actually resolves to 1.10.x. Then the `^1.9.0` floor is just inaccurate.
  - The lockfile really resolves to 1.9.0. Then the `currency` option may be ignored today, which is a live bug in invoice output.

  Unverified. Check the lockfile with `npm ls ledgerline`. Either way, raise the floor to `^1.10.0` now, independent of this PR.
- **No peer dependency changes** are listed in the release notes.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `npm ls ledgerline` (resolved version in lockfile) | — | — | Unverified. Recommended pre-merge check. |
| `npm audit` | — | — | Unverified. Recommended pre-merge check. |
| `npm ci --omit=dev` on `node:20-alpine` with 2.0.0 | — | — | Unverified. Recommended pre-merge check. |
| `node -e 'require("ledgerline")'` on `node:20-alpine` with 2.0.0 (confirms the import-time throw) | — | — | Unverified. Recommended pre-merge check. |
| Test suite on `node:22-alpine` with 2.0.0 | — | — | Unverified. Recommended pre-merge check. |
| Check whether any test loads `src/render/invoice.js` | — | — | Unverified. Recommended pre-merge check. |

No command was run in this session. Every behavioral statement above comes from the provided release notes and code, and should be read as a prediction.

### Risk Factors
- **Crash on Node 20.** Certain per the release notes, and possibly not caught by CI (see above).
- **Font subsetting is now on by default.** This changes PDF bytes and file sizes. It will break any byte- or hash-based snapshot tests of rendered invoices. It can also matter if invoice PDFs are edited, filled or stamped downstream, because a subset font lacks glyphs that were never rendered. Compare a few rendered invoices visually and check any downstream PDF processing after the bump.
- **The Node 22 upgrade carries its own risk** (native modules, Alpine base changes). It should be a separate, separately tested change, not bundled into a batch of dependency PRs.

### Rollback Plan (precondition: complete before starting the Migration Plan)

**Exact rollback commands** (for the ledgerline bump step):
```
git checkout <pre-bump-commit> -- package.json package-lock.json
npm ci --omit=dev
```
For the runtime step (a separate change), revert the `FROM` line in `Dockerfile` and the `engines` field, rebuild the image, and redeploy the previous image tag.

**Verification step** (run after rollback; must pass): render one invoice through `renderInvoice()` with a non-default `currency` and confirm the output is a valid PDF, for example via a focused test like `npm test -- src/render`. This would fail if the lockfile did not fully revert and 2.0.0 were still loaded on Node 20.

**Rehearsal status:** [ ] Not rehearsed. There was no execution environment in this session. Rehearse on a scratch branch before starting.

### Migration Plan
Do these in order, as separate PRs.
1. **Now, independent of this PR:** change `"ledgerline": "^1.9.0"` to `"^1.10.0"` so the manifest matches the `currency` option the code relies on. Confirm with `npm ls ledgerline` what is actually installed today.
2. **Runtime upgrade PR:** change `FROM node:20-alpine` to `node:22-alpine` (or `node:24-alpine`) in `Dockerfile` and the CI image, and set `engines.node` to `">=22"`. Run the full suite and deploy. This is also worth doing because Node 20 is end of life.
3. Make sure a test loads `src/render/invoice.js` and renders an invoice, so an import-time failure would turn CI red.
4. Rehearse the rollback (above) on a scratch branch.
5. **Then** rebase or re-open the Dependabot bump to `^2.0.0`. No code changes are needed in `src/render/invoice.js`.
6. Run tests. Visually diff a few rendered invoices for font and layout changes from subsetting. Update any byte or snapshot fixtures.

### If Not Upgrading
Staying on 1.10.x costs nothing functionally, because no feature needs 2.0.0. Revisit when either of these happens:
- The Node 22+ runtime upgrade lands. The bump then becomes a minutes-long, low-risk merge.
- 1.x stops receiving fixes, or a security advisory is published against 1.x.
