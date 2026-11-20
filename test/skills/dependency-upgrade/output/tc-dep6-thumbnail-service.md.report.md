## Dependency Upgrade Evaluation: pixelgrain 4.2.0 → 5.0.0

### Summary
**Recommendation:** Upgrade soon
**Breaking change impact:** None (no 5.0 breaking change touches the project's single call site)
**Estimated effort:** hours (bump, test, benchmark, rehearse the rollback)
**Risk:** Low
**Audit state:** Unverified (no shell or registry access in this session, so no audit was run)

### Motivation
The thumbnail queue backs up during evening peaks, and 5.0 claims `resize()` is 30–45% faster for JPEG and PNG input on x86-64 and arm64. This is a performance upgrade, not a security or end-of-life upgrade. There is no deadline, but the operational problem is real, which is why the recommendation is "soon" rather than "defer."

Two caveats limit how much the upgrade can help the queue:

1. **The speedup only covers JPEG and PNG.** The release notes make no performance claim for HEIC, and the test fixtures show HEIC is an accepted input. If evening uploads are mostly phone photos (often HEIC), the real-world gain may be much smaller than 30–45%.
2. **The speedup is to `resize()` only.** `makeThumb` also decodes (`open`) and encodes (`toFile` with `quality: 82`). The notes claim no speedup for either. If decode, encode or queue I/O dominates per-job time, a faster resize step moves the needle less. Measure before relying on it to clear the backlog. See Migration Plan step 5.

### Breaking Changes That Affect This Project

No breaking changes affect this project's usage.

The only call site, in `src/thumbs.js`, is:

```js
grain.open(inputPath).resize(320, 320, { fit: "cover" }).toFile(outputPath, { quality: 82 })
```

None of `open(path)`, `resize(w, h, { fit })` or `toFile(path, { quality })` is listed as changed in 5.0.0.

### Breaking Changes That Don't Affect This Project

| Change (5.0.0) | Why it's dismissed |
|---|---|
| `grain.stream()` removed | Not called. The project uses `grain.open(inputPath)` with a file path. |
| `composite(layers)` now requires an array of `{ input, top, left }` | `composite` is not called. |
| Node.js 16 and 18 dropped; Node 20+ required | `engines.node` is already `>=20`. Runtime and CI both use `node:22-slim`. |
| `grain.cache(false)` global switch removed | Not called. No caching configuration anywhere. |

From 4.3.0: HEIC decoding moved into the main package. This is not breaking for this project. The manifest lists only `pixelgrain`, with no separate HEIC add-on to remove, and the notes say 4.2 already bundled HEIC on Linux, which is what Docker and CI run.

One thing to check: if any developer runs tests outside Docker on macOS or Windows, HEIC support there under 4.2 may have depended on the optional add-on. Under 5.0 it should simply work. This is a possible improvement, not a risk.

### Transitive Effects
- **Runtime:** none. Node 22 satisfies the new Node 20+ floor, and `engines` already declares `>=20`.
- **Peer dependencies and conflicts:** none listed in the release notes. Only one dependency is in the manifest.
- **Version resolution:** `^4.2.0` may already resolve to 4.3.x in the lockfile, depending on when it was last regenerated. That is unverified. Either way, the manifest must change to `^5.0.0`, because the caret range will never pick up 5.0.0.
- **Native or SIMD binaries:** the new SIMD path targets x86-64 and arm64. Confirm the production host architecture is one of these, or the speedup won't apply.

### Execution Evidence

Nothing was run in this session. There was no repository, shell, registry or web access. Every row below is a recommended check, not a result.

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `npm ls pixelgrain` (resolved version actually installed today) | — | — | Unverified — recommended pre-merge check |
| `npm install pixelgrain@^5.0.0` | — | — | Unverified — recommended pre-merge check |
| `npm audit` (after bump; record the advisory-DB state the tool reports) | — | — | Unverified — recommended pre-merge check |
| `npm test` (JPEG/PNG/HEIC dimension and perceptual-hash comparison) | — | — | Unverified — recommended pre-merge check |
| Benchmark of `makeThumb` on a representative mix of production formats, 4.x vs 5.0 | — | — | Unverified — recommended pre-merge check |
| Rollback rehearsal plus verification step (see below) | — | — | Unverified — recommended pre-merge check |
| Search for any other `pixelgrain` usage, e.g. `grep -rn "pixelgrain\|grain\." src test scripts` | — | — | Unverified — the request states `src/thumbs.js` holds all call sites. Re-confirm before merging. |

When these are run, capture the verdict-bearing gates (audit, install, test) to `docs/reviews/{branch}/evidence/{n}-{cmd-slug}.txt`, with cwd, commit SHA, lockfile hash, exit code and timestamp.

### Risk Factors
- **Output drift.** The vendor claims the SIMD path is pixel-identical for `cover`, which is the fit used here. Treat that as a claim to verify, not a fact. The existing test checks dimensions and a perceptual hash against checked-in thumbnails for all three formats, so it should catch visible output changes in CI.
- **Encoder output not covered by the claim.** The pixel-identical claim covers `resize()`. The notes say nothing about the JPEG encoder at `quality: 82`. The perceptual-hash test would catch visible changes. Byte-level changes (file size) would not fail it, so compare output file sizes in the benchmark.
- **Performance gain smaller than hoped.** Covered under Motivation (HEIC mix, non-resize costs). This is the main way the upgrade could disappoint, though it wouldn't break anything.
- **Detectability:** high for correctness, since tests run in the same image as production. Low for performance, since nothing in the test suite measures throughput. Hence the explicit benchmark step.
- **Security reviewer:** not required by policy. The upgrade isn't CVE-driven and isn't crypto or auth. However, pixelgrain parses untrusted uploaded images, and the decoder internals changed (SIMD path, HEIC packaging in 4.3). A quick security-reviewer pass on the diff and an `npm audit` are cheap and reasonable.

### Rollback Plan (precondition — complete before starting Migration Plan)

**Exact rollback commands** (this assumes npm with `package-lock.json`; adjust if the project uses a different lockfile):
```
git checkout <pre-upgrade-commit> -- package.json package-lock.json
npm ci
# No data or config changes are involved: the upgrade touches no code, and
# thumbnails already written stay valid.
docker build -t thumbnailer:rollback-check .
```

**Verification step** (run after rollback; it must pass to confirm the rollback worked):
`npm ls pixelgrain` must report a 4.x version, and `npm test` must pass. The test exercises the project's only use of pixelgrain on JPEG, PNG and HEIC, and would fail if the lockfile left a mismatched build behind. Run both inside the `node:22-slim` image to match CI and production.

**Rehearsal status:** [ ] Not rehearsed. Rehearse on a scratch branch, e.g. `scratch/pixelgrain-5-rollback`: apply the upgrade, run the rollback commands, then run the verification step. Record "Rehearsed on {YYYY-MM-DD} on branch `{name}`; verification step passed", along with the captured verification output or its evidence-file path.

### Migration Plan
1. Record the baseline. Run `npm ls pixelgrain` to confirm the currently resolved 4.x version. Run the benchmark (step 5) against 4.x and save the numbers.
2. Complete and rehearse the Rollback Plan above.
3. Set `"pixelgrain": "^5.0.0"` in `package.json` and run `npm install` to regenerate the lockfile. No source changes are needed in `src/thumbs.js`.
4. Run `npm test` in the `node:22-slim` image. All three fixtures (JPEG, PNG, HEIC) must match dimensions and perceptual hash. Check for any deprecation warnings in the output.
5. Benchmark `makeThumb` against 4.x on the same host. Use a sample of real evening-peak inputs in their actual format mix, not just JPEG. Record per-job latency, throughput and output file sizes. Confirm the production host is x86-64 or arm64.
6. Run `npm audit` and record the advisory-DB state. Optionally do a security-reviewer pass on the diff (see Risk Factors).
7. Merge if tests pass and the benchmark shows a meaningful gain. After deploy, watch queue depth during the next evening peak. If the gain is marginal, the upgrade is still low-cost to keep, but look elsewhere for the backlog fix (worker concurrency, decode/encode cost, HEIC share).

### If Not Upgrading
Staying on 4.x costs nothing in correctness or security, based on the information given (audit unverified). But it forgoes a cheap, low-risk throughput gain for the format types it covers. If the benchmark in step 5 shows that resize isn't the bottleneck, deferring is reasonable. In that case, the queue problem needs a different fix regardless of the pixelgrain version.
