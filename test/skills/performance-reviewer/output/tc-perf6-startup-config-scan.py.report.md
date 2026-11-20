> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

# Performance Review: subject.py

**Scope:** `subject.py` (the whole file, as you asked)
**Date:** 2026-11-19

## Data Flow and Hot Paths

`load_plugins()` reads `plugins.json` from the module's directory, parses it, and runs three checks before returning the plugins sorted by `priority`, highest first:

1. **Pairwise loop (lines 13–22):** no two plugins share a name, and no two plugins share a `provides` entry.
2. **Dependency loop (lines 24–27):** every `requires` entry is provided by some plugin.
3. **Sort (line 29):** order by `priority`.

**Path temperature: cold.** The module docstring says this runs "when the worker process starts". Nothing else in the repository calls `load_plugins`; the only caller is the `__main__` CLI block (lines 32–34). So it runs at startup and doesn't block requests.

**Data size: unknown.** `plugins.json` isn't in the repository, so I can't tell how many plugins (N) there are or how long their `provides`/`requires` lists are. Plugin manifests usually hold tens of entries, maybe low hundreds. I assume that below. **Verify data size.**

**Measurements:** none are available. You didn't share any, and the repository documents none, so every finding below is speculative.

## Findings

#### 1. Pairwise uniqueness check is O(N²) and rebuilds two sets for every pair

**Severity:** Low
**Location:** `subject.py:13-22`
**Move:** Check the asymptotic behavior / Count the hidden multiplications
**Classification:** Macro (quadratic algorithm) / Cold path (worker startup, per the module docstring)
**Confidence:** High (complexity) / Low (whether it matters)
**Baseline:** no baseline available — flagged as speculative

The nested loop compares each plugin with every later one, which is N(N−1)/2 comparisons. For each pair, line 17 builds two new sets. That costs O(P) per pair (P = `provides` length), so the check is O(N²·P) overall. When a clash is found, line 18 builds the same two sets again. That only happens once, just before exiting, so it doesn't matter. Each `plugins[i + 1:]` also copies the remaining list, which adds another O(N²) of allocations.

At realistic manifest sizes (N < 100) this takes well under a millisecond and isn't worth fixing for speed alone. It would only matter in two cases:

- The manifest grows to thousands of entries. At N = 5,000 that is about 12.5M pairs and 25M set constructions, which would add seconds to each worker start.
- Workers restart often, for example a pre-fork server with `max_requests` recycling or serverless cold starts. Then the startup cost is paid on every restart, not once per deploy.

Under the hot-path gate, neither case is established here.

**Recommendation:** If the manifest might grow, replace the pairwise loop with one pass that builds a `name → plugin` dict and a `capability → provider name` dict, exiting on the first collision. That is O(total provides), and it produces the index Finding 2 needs. Otherwise leave it as is.

#### 2. Dependency check scans every plugin for each `requires` entry

**Severity:** Low
**Location:** `subject.py:24-27`
**Move:** Count the hidden multiplications
**Classification:** Macro (linear scan nested in a loop) / Cold path (worker startup)
**Confidence:** High (complexity) / Low (whether it matters)
**Baseline:** no baseline available — flagged as speculative

For each of the R `requires` entries across all plugins, `any(dep in p["provides"] for p in plugins)` loops over plugins. Each `in` test checks membership in a JSON list, which is a linear scan. In the worst case, a dependency with no provider, the cost is O(R·N·P). With small manifests this is negligible. It grows in the same quadratic way as Finding 1 if N grows.

**Recommendation:** Check each `dep` against the `capability → provider` dict from Finding 1, or against one set of all provided capabilities built once. That makes each check O(1) and the whole loop O(R).

## Endorsements

- The manifest is read and JSON-parsed once per `load_plugins()` call, and the dependency loop and sort reuse that parsed list. [read: subject.py:10-29]
- Claim: `load_plugins()` runs once per worker process, not per request or per job. The docstring says so, but no production caller in the repository confirms it. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Pairwise uniqueness check is O(N²) and rebuilds two sets for every pair | Low | `subject.py:13-22` | High (complexity) / Low (impact) |
| 2 | Dependency check scans every plugin for each `requires` entry | Low | `subject.py:24-27` | High (complexity) / Low (impact) |

## Overall Assessment

This file doesn't need performance work if two things hold:

- **Small manifest.** The plugin count stays in the tens to low hundreds. I couldn't check this because `plugins.json` isn't in the repository.
- **Startup only.** The function really runs once per worker start, as the docstring claims.

Both checks have quadratic structure, but on a cold path with a small N that costs well under a millisecond.

If you do touch this code, the fix is small and local. Build a `name` dict and a `capability → provider` dict in one pass, and use them for both the uniqueness check and the dependency check. That makes validation linear in total manifest size and removes the repeated set building.

The thing to confirm is call frequency, not speed. If `load_plugins()` ever moves onto a per-request or per-job path, or if workers recycle often under load, both findings rise to Medium or High under the calibration matrix. In that case, cache the validated result once per process rather than making the validation itself faster. No profiling is needed unless one of those conditions turns out to be true.
