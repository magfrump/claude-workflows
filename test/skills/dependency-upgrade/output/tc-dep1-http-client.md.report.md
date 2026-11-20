## Dependency Upgrade Evaluation: quillfetch 3.4.2 → 4.1.0

### Summary
**Recommendation:** Defer. **Do not merge the Renovate PR as-is.** If the team does want 4.x, merge only together with the timeout fixes in the Migration Plan.
**Breaking change impact:** Mechanical. There are two one-line edits, but the failure is silent, so the edits are mandatory.
**Estimated effort:** Hours. The code change takes minutes. Most of the time goes into adding a slow-upstream test and checking HTTP/2 behavior against the inventory and payments upstreams.
**Risk:** High if merged as-is. Low to Medium with the migration applied.
**Audit state:** Unverified. No audit was run because no shell or registry access was available. Run `npm audit` before merge.

### Motivation
Renovate opened this PR to keep the dependency current. Nothing is broken, and the release notes contain no security fix. The project uses none of the new 4.x features (`client.stream()`, function-valued `retry.backoff`). Being on the latest version is not enough reason to take a major bump, and this bump has a dangerous default-path change.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| `timeout` is now in **seconds**, not milliseconds (4.0.0) | `src/clients/inventory.js`: `timeout: 5000`. After the bump this means 5000 s, about 83 minutes. | Change to `timeout: 5` |
| Same | `src/clients/payments.js`: `timeout: 30000`. After the bump this means 30000 s, about 8.3 hours. With `retry: { limit: 2 }`, a hung capture could block for roughly a day. | Change to `timeout: 30` |

**Why this matters:** Renovate's diff touches only `package.json`. Merging it effectively removes both timeouts. Nothing throws, no type error appears (these are `.js` files), and the existing tests won't notice. `inventory.test.js` uses `mockTransport()` and checks request bodies, and per the request no test exercises a slow upstream. The failure would appear in production as request handlers hanging and sockets or workers piling up whenever inventory or payments slows down. That is when timeouts matter most.

### Breaking Changes That Don't Affect This Project
- **`client.fetchRaw()` removed (4.0.0; deprecated in 3.5.0).** Not used. Both call sites use `.post()` and `.json()`.
- **`hooks.beforeError` now receives `{ error, request }` (4.0.0).** Not used. Neither client configures `hooks`.
- **`mockTransport()` TypeScript declaration fix (4.0.1).** Irrelevant, because the project is plain JS.
- **`retry.maxDelay` is in seconds.** Unchanged in 4.0, and the project doesn't set it.

### Transitive Effects
- **Runtime:** The release notes state no Node minimum change. `engines.node >=20` is presumably fine, but this can't be confirmed without the package's own `engines` field.
- **Peer dependencies:** None are mentioned in the release notes. This is Unverified, because the lockfile and the package metadata were not available.
- **3.5.0 is in the range.** `^3.4.2` may already resolve to 3.5.x in the lockfile, but no lockfile was provided. 3.5.0's only behavior change, `mockTransport()` recording headers, is additive.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `npm audit` (on PR branch) | — | — | Unverified. Recommended pre-merge check. |
| `npm ci` (on PR branch) | — | — | Unverified. Recommended pre-merge check. |
| `npm test` (on PR branch, after timeout fix) | — | — | Unverified. Recommended pre-merge check. |
| `grep -rn "quillfetch\|timeout:\|fetchRaw\|beforeError" src test` | — | — | Unverified. The call-site list above comes from the request, not from a search. Run this to confirm there are no other usages. |

No commands were run. The environment had no repository, shell, or network access.

### Risk Factors
- **Silent timeout inflation.** This is the critical risk, described above. Detectability with the current tests is none.
- **Automatic HTTP/2 (4.0.0).** This changes behavior even with no code edits. Connection reuse and multiplexing, header casing (lowercase in h2), and interactions with proxies, load balancers, or service meshes in front of `INVENTORY_URL` and `PAYMENTS_URL` can all differ. Verify against staging upstreams. Problems may show up only under load or through specific proxies.
- **Retries on a payment-capture POST.** This is pre-existing and not caused by the upgrade. `retry: { limit: 2 }` on `POST /intents/:id/capture` risks duplicate capture attempts unless the payments service is idempotent on intent ID or quillfetch skips retrying non-idempotent methods by default. The upgrade makes this worse if the timeout fix is missed, because each attempt could wait hours. Worth confirming separately.
- **Security review.** Not required under the skill's triggers: there is no CVE and no crypto/auth package. Payments is a sensitive path, though, so a quick look at the migrated `payments.js` diff is reasonable.

### Rollback Plan (precondition: complete before starting Migration Plan)

**Exact rollback commands** (assumes npm and `package-lock.json`, since no lockfile was provided; adjust for yarn or pnpm):
```
git checkout main -- package.json package-lock.json src/clients/inventory.js src/clients/payments.js
npm ci
```
No data or config changes are involved.

**Verification step** (run after rollback; it must pass to confirm the rollback worked):
`npm ls quillfetch` must report `3.x`, **and** `npm test -- test/clients` must pass. That includes the new slow-upstream timeout test from step 2 below. The timeout test is what makes the check meaningful: on a half-reverted tree (4.x library with `timeout: 5000`, or 3.x with `timeout: 5`), it fails or trips immediately.

**Rehearsal status:** [ ] Not rehearsed. This environment cannot execute commands. Rehearse on a scratch branch (e.g. `scratch/quillfetch-4-rollback`) and attach the verification output before starting the migration.

### Migration Plan
Do this only if the team decides to take 4.x. Otherwise, close or ignore the Renovate PR and see "If Not Upgrading".
1. On 3.x first, add a slow-upstream test for each client. It should assert that a request to a delayed endpoint rejects with a timeout error within the expected bound. Use `mockTransport()` if it supports delayed responses, or a local `http.createServer` that never responds. Confirm it passes on 3.4.2. This closes the detection gap and gives the rollback rehearsal its verification step.
2. Rehearse the rollback per the plan above.
3. On the Renovate branch, change `src/clients/inventory.js` to `timeout: 5` and `src/clients/payments.js` to `timeout: 30`. Commit these **in the same PR** as the version bump, so the version and the units can never diverge.
4. Run `grep -rn "timeout" src` to catch any other quillfetch timeouts, such as per-request overrides.
5. Run `npm ci && npm test`. The timeout tests from step 1 must pass unchanged.
6. Deploy to staging and exercise `reserve()` and `capture()` against real upstreams. Check that HTTP/2 negotiation works through the proxy or mesh, and watch error rates and latency.
7. Run `npm audit` at merge time. Re-run it if more than 24 hours have passed or the lockfile changed.

### If Not Upgrading
3.4.2 works and has no reported advisory in the provided notes. Revisit when:
- a security advisory affects 3.x,
- 3.x reaches end-of-life or stops receiving fixes,
- the project needs `client.stream()` (e.g. large or chunked inventory exports) or HTTP/2, or
- another dependency requires quillfetch 4.

Regardless of the decision, consider adding the slow-upstream timeout tests from step 1 now. They are cheap, they protect the current code, and they make any future quillfetch bump safe to evaluate. Also configure Renovate so major quillfetch bumps are not automerged.
