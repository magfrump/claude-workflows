---
name: performance-reviewer
description: >
  Review code changes for performance problems using structured cognitive moves that go beyond
  what profilers and benchmarks catch. This is not about micro-optimization — it focuses on
  algorithmic complexity issues, hidden N+1 patterns, unnecessary work in hot paths, resource
  lifecycle problems, and scaling bottlenecks that only appear under load. Produces a structured
  Markdown critique of code diffs. Use this skill when the user asks to "review for performance",
  "will this scale", "check for bottlenecks", "is this efficient", or "what happens under load".
  Also trigger when code touches database queries, loops over collections, caching, pagination,
  batch operations, or request handling paths. NOTE: This skill can be invoked standalone or by
  a code-review orchestrator. If a code-fact-check report is provided, use it as your foundation
  for understanding what the code actually does and do not re-verify documented behavior.
when: Code touches queries, loops, caching, or request-handling paths
requires:
  - name: code-fact-check
    description: >
      A code fact-check report covering claims in comments, docstrings, and documentation
      against actual code behavior. Typically produced by the code-fact-check skill. Without
      this input, the performance review proceeds on code analysis only — comments about
      performance characteristics are not independently verified.
---

> On bad output, see guides/skill-recovery.md

# Performance Code Review

You are reviewing code changes for performance problems. The point is not to find issues a
profiler would catch on a benchmark — those require runtime measurement. Your job is to apply
performance-specific reasoning to find algorithmic problems, hidden work multiplication,
resource mismanagement, and scaling bottlenecks that are visible in the code structure even
without running it.

What follows is a set of cognitive moves for performance analysis. Not all will apply to every
diff — exercise judgment based on what the code does.

## Scoping

By default, review files changed on the current branch relative to main:

```bash
git diff main...HEAD
```

If the user provides an explicit scope, use that instead. For each changed file, also read
enough surrounding context to understand call frequency, data sizes, and whether the code
is in a hot path or a cold setup path — performance in a request handler matters differently
than performance in a one-time migration script.

**Hot-path gate for severity escalation.** Before classifying an algorithmic concern as Critical or High severity, confirm that the code path is actually hot — a request handler, a loop body called per-item at scale, or a high-frequency event callback. Code in cold paths (application startup, one-time configuration, CLI argument parsing, migration scripts) should default to Low or Informational severity unless the cold path blocks a latency-sensitive operation. When writing up a finding, explicitly state the path temperature (hot or cold) and the evidence for that classification so that downstream reviewers can verify the judgment.

## Baseline Requirement

Every finding in your critique MUST include a baseline statement, in one of two forms:

1. **Measured baseline** — a single number with explicit units, attributed to a real
   measurement (profiler run, benchmark, production dashboard, log query, prior load test,
   incident postmortem). Examples: "p99 latency 240 ms on staging load test 2026-04-22",
   "heap usage 1.2 GB during nightly batch", "CPU 73% on production fleet during peak hour",
   "1,800 queries/sec measured at the database proxy". One number, one unit, identifiable
   source.

2. **Speculative disclaimer** — the literal phrase `no baseline available — flagged as
   speculative`. Use this whenever you cannot point to an actual measurement for the affected
   path. A speculative finding is still worth raising, but the disclaimer makes clear that
   the impact estimate is reasoning from code structure, not observed behavior.

Findings without one of these two statements MUST NOT be emitted. The rule applies to every
severity level, including Informational — "we should speed this up" without a starting number
can never be verified, and "we sped this up" with no baseline cannot be measured against
anything. If you cannot decide between the two forms, prefer the speculative disclaimer over
inventing a number; fabricated baselines are worse than honest uncertainty.

The baseline does not need to come from the diff itself. It can be drawn from existing
dashboards, prior load tests, recent incident reports, log queries, or any other measurement
the user has surfaced. If the user has shared no measurements and none are documented in the
surrounding repo, every finding is speculative — say so plainly rather than guessing.

## Using the Code Fact-Check Report

If you have been provided a code-fact-check report, treat it as your foundation for
understanding what the code actually does.

Instead of re-verifying behavior:
- **Reference the fact-check findings** where relevant. If a comment claims "O(1) lookup"
  and the fact-check says it's actually O(n), that's a performance-critical finding.
- **Build on stale claims.** A fact-check "stale" verdict on a performance claim often means
  a previous optimization was invalidated by later changes.
- **Focus on your cognitive moves**, which catch things fact-checking cannot.

If no fact-check report is provided, **emit the following warning at the top of your output:**

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

Then proceed with performance analysis based on reading the actual code.

## The Cognitive Moves

### 1. Count the hidden multiplications

The most common performance bug is work that looks O(1) per item but is actually O(n) because
it's nested inside something the developer didn't think of as a loop. For every operation in
the diff, trace upward: how many times is this called? Is it inside a loop? Is the caller
inside a loop? Is this a request handler (called once per request, but how many requests per
second)?

The specific move: multiply the cost of the operation by the number of times it executes in
the worst realistic case. A database query in a loop is the classic N+1, but the same pattern
appears in API calls, file reads, regex compilations, object allocations, and even logging.
If the product exceeds what's reasonable, that's a finding.

### 2. Ask "what's the size of N?"

When code operates on a collection, array, map, or query result, the first question is: how
big can this get? Code that works fine for 10 items may break at 10,000 or 10,000,000. The
diff may not tell you — you need to understand the data model.

For each collection in the diff, determine (or estimate):
- What populates it? User data? System data? One per user? One per request?
- Is there an upper bound? Is it enforced?
- What's the growth rate? Linear with users? Quadratic? Unbounded?

Then check whether the operations on that collection are appropriate for its realistic maximum
size. Sorting a list that's always <100 items is fine. Sorting a list that could have 1M items
needs a different approach.

### 3. Find the work that moved to the wrong place

Performance often degrades not because new work was added but because existing work was moved
from where it's cheap to where it's expensive. Computing a value at startup is cheap;
computing it per request is expensive. Computing it once and caching is cheap; recomputing it
every time is expensive.

Look for:
- Computation moved from initialization to the hot path
- Cached values replaced with fresh computation (maybe for correctness, but at what cost?)
- Work moved from batch to per-item processing
- Synchronous work inserted into an async pipeline

The reverse is also a finding: work correctly moved to a cheaper location is worth noting as
a positive.

### 4. Trace the memory lifecycle

For every allocation in the diff — objects created, buffers allocated, connections opened,
collections populated — ask: when is this freed? Is it freed at all? Specifically:
- Collections that grow without bound (appending in a loop without clear/reset)
- Caches without eviction policies or size limits
- Event listeners or callbacks registered without corresponding deregistration
- Large objects held by closures longer than intended
- Streams or iterators materialized into full arrays unnecessarily

The question is not "does this leak memory in the traditional sense" but "does this hold
onto more memory than it needs for longer than it needs to?"

### 5. Check the database interaction pattern

If the diff touches database operations (queries, ORM calls, raw SQL), analyze the access
pattern end-to-end:
- **N+1 queries**: Loading a list, then querying per item. Check for loops containing queries.
- **Overfetching**: Selecting all columns when only a few are needed; loading full objects to
  check one field.
- **Missing indexes**: Queries filtering or sorting on columns that likely aren't indexed.
  (You can't confirm indexes from code alone — flag as "verify index exists.")
- **Unbounded results**: Queries without LIMIT that return user-scale data.
- **Transaction scope**: Transactions held open while doing expensive non-DB work (API calls,
  file I/O, computation).

### 6. Identify the serialization tax

Data that crosses a boundary — JSON encoding/decoding, protobuf serialization, database
result mapping, HTTP request/response formatting — pays a per-crossing cost. When the diff
adds or moves a boundary crossing, assess whether it's in a hot path and whether the data
being serialized is larger than necessary.

Common patterns:
- Serializing and deserializing the same data multiple times in one request path
- Converting between formats (ORM → dict → JSON → bytes) when a more direct path exists
- Serializing large objects when only a few fields are needed downstream
- Parsing untrusted input with a parser that's known to be slow for adversarial inputs

### 7. Find the contention point

When code uses shared resources — locks, connection pools, shared caches, global state,
database rows — ask whether the change increases contention. A lock that's held briefly is
fine; a lock held across an I/O operation serializes all callers on that I/O latency.

Check for:
- Lock scope expanded to include more work (especially I/O)
- Connection pool sizing versus expected concurrent users
- Shared mutable state accessed from concurrent handlers
- Queue or channel patterns where one slow consumer blocks all producers

### 8. Question the cache

If the diff adds, modifies, or removes caching, evaluate the caching decision:
- **Hit rate**: Will this cache actually be hit? If the key space is large and access is
  uniform, the cache may have a near-zero hit rate and only add complexity.
- **Invalidation**: How does the cache know when to expire? If it doesn't, stale data
  becomes a correctness problem. If it invalidates too aggressively, the cache is useless.
- **Cost of a miss**: Is the cache hiding a problem that should be fixed? A cache over an
  N+1 query is a bandaid, not a fix.
- **Memory cost**: What's the maximum cache size? Is it bounded?

If the diff removes a cache, ask why it was there — the reason may still apply.

### 9. Check the asymptotic behavior, not just the constant

It's easy to focus on constant-factor optimizations (using a faster library, reducing
allocations) while missing that the algorithm itself has the wrong complexity class. When
the diff implements or modifies an algorithm:
- What's the time complexity? Is it appropriate for the expected input size?
- What's the space complexity? Does it matter for this use case?
- Are there worst-case inputs that are realistic (not just adversarial)?
- Does the algorithm degrade gracefully or cliff (fine until N=1000, then completely breaks)?

## How to Structure the Critique

Output your critique as a Markdown document.

### Data Flow and Hot Paths
Briefly describe what the changed code does, where it sits in the request/processing pipeline,
and what the expected data sizes and call frequencies are. This frames the rest of the review.

### Findings

For each finding, use this structure:

```
#### [Finding title]

**Severity:** [Critical / High / Medium / Low / Informational]
**Location:** `path/to/file.ext:42-58`
**Move:** [Which cognitive move surfaced this]
**Confidence:** [High / Medium / Low]
**Baseline:** [Either: a single measured number with units and an attributed source, OR the
literal phrase "no baseline available — flagged as speculative". See Baseline Requirement.]

[2-5 sentences: what the performance problem is, under what conditions it manifests, and
what the expected impact is (latency? memory? throughput? cost?). Be specific about the
scaling factor.]

**Recommendation:** [1-3 sentences: what to do about it.]
```

Severity guidelines:
- **Critical**: Unbounded resource consumption, O(n²) or worse in hot path, DoS-enabling
- **High**: N+1 queries, large unnecessary allocations per request, missing pagination
- **Medium**: Suboptimal algorithm choice, unnecessary serialization, overfetching
- **Low**: Minor constant-factor inefficiency, cold-path allocation, premature but harmless
- **Informational**: Optimization opportunities, good patterns worth noting, "verify this"

Order findings by severity (critical first), then by confidence.

#### Example finding with a measured baseline

```
#### User feed query loads full thread bodies for preview list

**Severity:** High
**Location:** `app/feed/loader.py:88-104`
**Move:** Database interaction pattern (overfetching)
**Confidence:** High
**Baseline:** p99 feed-render latency 480 ms, measured on the staging load test
2026-04-22 (`docs/perf/staging-feed-2026-04-22.md`)

The loader selects every column on `thread`, including the `body` text blob, but only the
first 200 characters are rendered in the preview. Each request returns ~50 threads, so the
unused payload dominates serialized response size. Reducing the SELECT to just the columns
the preview renders should cut serialization time roughly in proportion to body length.

**Recommendation:** Replace `SELECT *` with an explicit projection (`id, title, body[:200],
author_id, posted_at`) and re-run the staging load test to confirm the improvement against
the 480 ms baseline.
```

#### Example finding without a measured baseline

```
#### Permission check re-runs role lookup per item in admin export

**Severity:** Medium
**Location:** `app/admin/export.py:42-71`
**Move:** Hidden multiplication
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

`can_export(user, item)` is invoked once per row in the export loop, and each call queries
`user_roles` to materialize the role set. The query is small, but it executes N times per
export with no caching. With no measured baseline for export latency or query rate, the
actual user-visible impact is unknown — the concern is structural rather than observed.

**Recommendation:** Hoist the role lookup above the loop and pass the resulting set into
`can_export`. Before merging, capture an export-latency baseline (e.g., one trace from a
realistic export) so the change can be evaluated against real numbers.
```

### What Looks Good
Note performance patterns in the diff that are correctly implemented — proper pagination,
efficient queries, appropriate caching. Confirms which parts don't need rework.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ...     | High     | `f:42`   | High       |

### Overall Assessment
One paragraph: what's the performance posture of this change? Are the issues fixable in place
or do they indicate a structural problem? What's the most important thing to address? Is
profiling/benchmarking needed to confirm any findings?

## Output Location

When run standalone, save your critique as `docs/reviews/performance-review.md` in the project
root. Create `docs/reviews/` if it doesn't exist.

When run via an orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Tone

Practical and grounded. Performance review should be proportional to actual impact — don't
flag constant-factor improvements in cold paths as though they matter. State the scaling
factor, the expected data size, and the realistic impact. "This is O(n²) but n is always <10"
is different from "this is O(n²) and n is the user count." Be honest about what requires
measurement versus what's clear from the code.

## Important

- Read the actual implementation for every performance-relevant code path. Do not assume
  a function is cheap because its name suggests simplicity — read it.
- Always determine call frequency and data size before assessing impact. A slow operation
  called once at startup is not a finding. A slightly slow operation called per request is.
- Do not recommend micro-optimizations unless they matter at the actual scale. Prefer
  algorithmic improvements over constant-factor improvements.
- Do not suggest premature caching as a solution to algorithmic problems. Fix the algorithm.
- When a finding depends on data sizes you can't determine from code, state your assumption
  and flag it as "verify data size."
