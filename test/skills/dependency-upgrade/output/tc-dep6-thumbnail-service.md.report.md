## Dependency Upgrade Evaluation: pixelgrain 4.2.0 → 5.0.0

### Summary
**Recommendation:** Upgrade soon. No code changes are needed. Finish the rollback rehearsal and a benchmark first.
**Breaking change impact:** None
**Estimated effort:** Hours (zero source edits; the time goes to rollback rehearsal, the test run, and a before/after benchmark)
**Risk:** Low
**Audit state:** Unverified. No shell or registry access in this session, so no audit was run.

### Motivation
The thumbnail queue backs up during evening peaks, and 5.0.0 claims 30–45% faster `resize()` for JPEG and PNG on x86-64 and arm64. This is a performance motivation, not a security or end-of-life one. The upgrade is only worth taking if it relieves the backlog. Three caveats limit that:

- **Only `resize()` gets faster.** The notes say nothing about decode, encode (`toFile` at quality 82), or file I/O. If those dominate `makeThumb`, end-to-end throughput will improve by much less than 30–45%.
- **HEIC input gets no claimed speedup.** The SIMD claim covers only JPEG and PNG. If most evening uploads are phone photos in HEIC, the gain on the actual peak workload could be small.
- **The backlog may not be CPU-bound in pixelgrain at all.** Worker concurrency, I/O, or queue configuration could be the real limit.

So the ask is low-risk, but the payoff is unproven for this workload. Measure before attributing peak relief to it.

### Breaking Changes That Affect This Project

No breaking changes affect this project's usage.

The only call site, `src/thumbs.js`, uses three things:
- `grain.open(path)`
- `.resize(320, 320, { fit: "cover" })`
- `.toFile(path, { quality: 82 })`

None of these changed signature in 5.0.0.

### Breaking Changes That Don't Affect This Project

| Change | Why it doesn't apply |
|---|---|
| `grain.stream()` removed | Not used. The project opens file paths. |
| `composite(layers)` now array-of-objects only | `composite` not used. |
| Node.js 16 and 18 dropped; Node 20+ required | Runtime is `node:22-slim` (Dockerfile and CI), and `engines` is already `>=20`. |
| `grain.cache(false)` global removed | Not used. Caching is left at defaults. |
| 4.3.0: HEIC decoding moved into the main package | 4.2 already bundled HEIC on Linux, which is where production and CI run, so HEIC support continues. Non-Linux dev machines get HEIC that 4.2 only offered as an optional add-on. |

**Behavioral note:** 5.0.0 states that `resize()` output is pixel-identical for the `cover` fit, which is the fit this project uses. `test/thumbs.test.js` (dimensions plus perceptual hash against checked-in thumbnails) will confirm this. Treat it as a vendor claim until that test passes on 5.0.0.

### Transitive Effects
- **Runtime:** none. Node 22 meets the new Node 20+ minimum.
- **Peer dependencies:** none stated in the release notes.
- **Native binary:** the SIMD path implies architecture-specific code. Prebuilt binaries for `node:22-slim` on x86-64 or arm64 should be covered by the stated support. Confirm with a clean `npm ci` in the image.
- **Lockfile resolution is unknown.** No lockfile was provided. Because the range is `^4.2.0`, the installed version may already be 4.3.x rather than 4.2.0. Either way, 4.3.0 introduces nothing that affects this project.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---|---|---|---|
| `npm ci` in `node:22-slim` after bumping to `pixelgrain@^5.0.0` | — | — | Unverified. Recommended pre-merge check. |
| `npm test -- test/thumbs.test.js` on 5.0.0 (JPEG/PNG/HEIC dimensions and perceptual hash) | — | — | Unverified. Recommended pre-merge check. |
| `npm audit` (or equivalent) against the 5.0.0 lockfile | — | — | Unverified. Recommended pre-merge check. |
| Before/after benchmark of `makeThumb` on a representative upload mix | — | — | Unverified. Recommended pre-merge check. |
| Rollback rehearsal and verification (see below) | — | — | Unverified. Recommended pre-merge check. |

No command was run in this session. There was no shell, repository, or network access. Every statement above about compatibility comes from reading the provided manifest, source, and release notes. None of it is an observed execution result.

### Risk Factors
- **Low API risk.** The used surface is unchanged.
- **Visual-output risk is low and well detected.** The vendor claims pixel-identical `cover` output, and the perceptual-hash test covers all three input formats in use.
- **New SIMD code path.** This is a fresh native code path in a major release, so edge-case inputs (unusual color profiles, very large images, odd EXIF orientations) may behave differently even if the fixtures pass. If production has a broad input mix, consider a canary or a staged rollout.
- **Expectation risk.** The main risk is that the upgrade ships and the evening backlog persists, because resize wasn't the bottleneck or because HEIC dominates. The benchmark below addresses this.
- **Security review:** not required by the skill's triggers, since this is not CVE-motivated and not a crypto/auth package. Image decoders are attack surface, though, so a quick look at the audit result is worthwhile.

### Rollback Plan (precondition: complete before starting the Migration Plan)

**Exact rollback commands:**
```
git checkout -- package.json package-lock.json
npm ci
# No data or config changes are made by this upgrade; nothing else to unwind.
```
(If the project uses a different lockfile, e.g. `yarn.lock` or `pnpm-lock.yaml`, substitute it and the matching `yarn install --frozen-lockfile` / `pnpm install --frozen-lockfile`.)

**Verification step** (run after rollback; must pass to confirm the rollback worked):
```
node -e "console.log(require('pixelgrain/package.json').version)"   # must print the pre-upgrade 4.x version
npm test -- test/thumbs.test.js                                     # must pass against checked-in thumbnails
```
The version check fails if the lockfile didn't fully revert. The thumbnail test exercises the project's only use of pixelgrain.

**Rehearsal status:** [ ] Not yet rehearsed. Rehearse on a scratch branch (e.g. `scratch/pixelgrain-5-rollback`): upgrade, run the rollback commands, run the verification step, and capture the output as evidence.

### Migration Plan
1. Complete and record the rollback rehearsal above.
2. **Baseline benchmark on 4.x:** time `makeThumb` over a representative sample of real uploads, with the actual production mix of JPEG, PNG, and HEIC, in the `node:22-slim` image. Also note where time goes per call (decode / resize / encode).
3. Bump the dependency: `npm install pixelgrain@^5.0.0`, then commit `package.json` and the lockfile.
4. Run `npm ci` in the CI image to confirm the native/SIMD binary installs cleanly.
5. Run `npm test -- test/thumbs.test.js`. Dimensions and perceptual hashes must match the checked-in thumbnails for all three formats.
6. Run the audit and record its timestamp and advisory-DB state. Re-run at merge time if more than 24h have passed or the lockfile changed.
7. Re-run the benchmark from step 2 on 5.0.0 and compare. If the HEIC share is high or resize is a small fraction of per-call time, set expectations accordingly and look at concurrency or queue tuning alongside this upgrade.
8. Ship. Optionally canary on a fraction of the queue workers first, and watch error rates and queue depth during the next evening peak.

No source changes to `src/thumbs.js` are expected.

### If Not Upgrading
There is no urgency: no security advisory, no end-of-life notice, and 4.x works on the current runtime. If the step-2 benchmark shows resize is a negligible share of `makeThumb` time, or the peak traffic is mostly HEIC, deferring is reasonable. Address the backlog through worker concurrency or queue scaling instead, and revisit the upgrade when a 5.x feature is needed or 4.x stops receiving fixes.
