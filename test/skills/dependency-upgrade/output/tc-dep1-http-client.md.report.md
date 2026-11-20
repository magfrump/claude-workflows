## Dependency Upgrade Evaluation: quillfetch 3.4.2 → 4.1.0

### Summary
**Recommendation:** Defer
**Breaking change impact:** Mechanical
**Estimated effort:** hours
**Risk:** Medium
**Audit state:** Unverified

Do not merge the Renovate PR as written. It changes only the version range. Under 4.0.0, the existing `timeout` values are read as seconds. That turns a 5-second inventory timeout into about 83 minutes and a 30-second payments timeout into about 8.3 hours. No test or error would catch this. The fix itself is small, but nothing in 4.x is needed today. Defer, and close or hold the PR until the conditions under "If Not Upgrading" apply. If the team upgrades anyway, follow the Migration Plan below rather than merging the PR as-is.

### Motivation
This is a routine Renovate bump to the latest release. Nothing is broken, and no security advisory, CVE or end-of-life notice was mentioned. Release notes 4.0.1 and 4.1.0 add `client.stream()`, function-valued `retry.backoff` and a TypeScript fix for `mockTransport()`. The project uses none of these. The only motivation is staying current, which alone does not justify a major-version bump that changes behaviour.

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| 4.0.0: `timeout` is now in **seconds**, not milliseconds; fractional values allowed | `src/clients/inventory.js` (`timeout: 5000`), `src/clients/payments.js` (`timeout: 30000`) | Change to `timeout: 5` and `timeout: 30`. This must ship in the **same commit** as the version bump. Without it, the timeouts stay "valid" numbers but become 1000× longer. A hung inventory or payments upstream would then hold requests (and with `retry: { limit: 2 }` on payments, up to three attempts) for hours instead of failing fast. |

Why this is the critical item:
- **It is silent.** The release notes do not say values are validated or capped, so 5000 is presumably accepted as 5000 seconds. There is no type error, no exception and no deprecation warning. Check whether 4.x warns on large values before relying on that.
- **The tests won't catch it.** `test/clients/inventory.test.js` checks request bodies through `mockTransport()`, and nothing tests a slow upstream. The suite would pass either way.
- **It only shows up in production, during an upstream incident.** It turns a degraded dependency into connection or worker exhaustion in `orderdesk-api`.

### Breaking Changes That Don't Affect This Project
- **Removed `client.fetchRaw()`** (deprecated in 3.5.0): not used. The call sites only use `createClient`, `.post()` and `res.json()`.
- **`hooks.beforeError` now receives `{ error, request }`**: not used. Neither client configures `hooks`.

Non-breaking changes checked:
- 3.5.0: `mockTransport()` now records request headers. This adds data and should not break body assertions. It might affect exact-equality assertions on the recorded request object, if the test uses any.
- 4.0.1: TypeScript declaration fix for `mockTransport()`. The project is JavaScript, so this has no effect.
- 4.1.0: `client.stream()` and function-valued `retry.backoff` are additive.

### Transitive Effects
- **Automatic HTTP/2 (4.0.0):** a behavioural change outside the API surface. When `INVENTORY_URL` or `PAYMENTS_URL` servers (or proxies or load balancers in front of them) advertise HTTP/2, the client switches to it without being asked. Possible effects:
  - different connection reuse and multiplexing
  - different behaviour through proxies
  - different timeout and retry interaction on shared connections
  - header normalisation: `x-service` is already lowercase, so this is likely fine

  Verify against staging, especially payments.
- **Runtime requirements:** the release notes list no Node.js minimum change. `engines: node >=20` stays as it is.
- **Peer dependencies and conflicts:** none listed. The lockfile resolution has not been checked (no access).
- The new range `^4.1.0` will accept future 4.x minors automatically, as `^3.4.2` did for 3.x.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `npm audit` (on current lockfile) | — | — | Unverified — recommended pre-merge check |
| `npm install` / `npm ci` with `quillfetch@^4.1.0` | — | — | Unverified — recommended pre-merge check |
| `npm test` on upgraded branch | — | — | Unverified — recommended pre-merge check |
| `grep -rn "quillfetch\|fetchRaw\|beforeError\|timeout" src test` | — | — | Unverified — recommended pre-merge check |

No command was run in this session because there was no shell, repository or web access. The usage analysis relies entirely on the request's statement that the two files shown are "all of the call sites". The grep above would confirm that, including any `timeout` values passed per request rather than per client.

### Risk Factors
- **Timeout unit change (High if missed, Low once fixed):** described above. This is the main reason the PR cannot merge as-is.
- **HTTP/2 auto-negotiation (Medium):** changes behaviour without any code change. It affects the payments path, where the cost of a bad interaction is highest.
- **Detectability is poor:** no slow-upstream test exists, and `mockTransport()` probably bypasses real transport. That means neither the timeout nor the HTTP/2 change is covered by the suite. Problems would appear only under upstream latency or with specific server configurations.
- **Payments retry semantics:** `retry: { limit: 2 }` on a `capture` POST is unchanged by this upgrade. Combined with a timeout that is too long, though, a retried capture could land long after the caller has given up. That is another reason the timeout fix is non-negotiable.

### Rollback Plan (precondition — complete before starting Migration Plan)

**Exact rollback commands:**
```
git checkout main -- package.json package-lock.json src/clients/inventory.js src/clients/payments.js
npm ci
```
(Adjust `main` to the base branch. List any test files changed during the migration as well.)

**Verification step** (run after rollback; must pass to confirm rollback worked):
`npm ls quillfetch` must report `3.4.2`, followed by `npm test -- test/clients`. If you add a timeout test (Migration Plan step 4), it must pass against 3.x with the original millisecond values. That proves the rollback restored both the package and the matching config units.

**Rehearsal status:** [ ] Rehearsed on {YYYY-MM-DD} on branch `{scratch-branch-name}`; verification step passed — evidence: {evidence-file path or verbatim verification output}. *Not rehearsed; this could not be done here.*

### Migration Plan
When the upgrade is taken up:
1. Complete and rehearse the Rollback Plan on a scratch branch.
2. Update `package.json` to `"quillfetch": "^4.1.0"` and run `npm install` so the lockfile updates.
3. In the same commit, change `timeout: 5000` → `timeout: 5` in `src/clients/inventory.js` and `timeout: 30000` → `timeout: 30` in `src/clients/payments.js`. Add a comment noting the unit is seconds.
4. Add a slow-upstream test that asserts the inventory client fails in about 5 seconds, not much longer. Use a local delayed server, or `mockTransport()` if it supports delays (check this). This closes the gap that would have let the unit change through.
5. Run `npm test` and capture the output as evidence.
6. Run both clients against staging inventory and payments. Confirm which protocol is negotiated (HTTP/1.1 or HTTP/2), check that timeouts and retries behave as expected, and watch for proxy errors.
7. Re-run `npm audit` at merge time and record the timestamp and advisory DB state.

### If Not Upgrading
Staying on 3.4.2 costs nothing today: no known advisory (unverified) and no needed feature. Revisit when:
- a security advisory affects 3.x
- 3.x is announced end-of-life
- the project needs `client.stream()` or function-based `retry.backoff`

Until then, close or hold the Renovate PR, or configure Renovate to stop proposing quillfetch majors. That way the bare bump can't be merged by accident. Updates within 3.x (such as 3.5.0) remain safe to take under the current `^3.4.2` range.
