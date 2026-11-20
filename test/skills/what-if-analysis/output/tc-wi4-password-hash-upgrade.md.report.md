# What-If Analysis: bcrypt → Argon2id upgrade-on-login for `accounts-api`

**Proposal:** Design doc "Upgrade stored password hashes from bcrypt to Argon2id" (Quillmark `accounts-api`)
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository was available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. All findings are tagged `[NOVEL]`.

---

## Assumptions Examined

**A1. Rollback is "instant and complete," and the previous release is a safe fallback.**
- **Source:** Explicit, "Rollback and rollback" section.
- **If wrong:** Redesign of the rollout.
- **Analysis:** Each upgrade overwrites the only copy of the bcrypt hash. The previous release "predates this work entirely," so it cannot verify `$argon2id$` hashes. Redeploying it locks out every upgraded account. The flag only stops *new* upgrades. It reverses nothing.
- **Tag:** `[NOVEL]`

**A2. "No data migration is involved at any stage."**
- **Source:** Explicit, same section.
- **If wrong:** Redesign.
- **Analysis:** Upgrade-on-login *is* a data migration. It runs one row at a time, it is destructive, and it cannot be reversed in place. Calling it "no migration" is what lets the doc treat rollback as trivial.
- **Tag:** `[NOVEL]`

**A3. An upgrade login costs about 90 ms of CPU, a 20 ms increase.**
- **Source:** Explicit, "Capacity."
- **If wrong:** Redesign of the rollout pacing and capacity plan.
- **Analysis:** An upgrading login does a bcrypt verify (70 ms) and then an Argon2id hash (90 ms), so about 160 ms. Adding a verify-after-write check (recommended below) makes it about 250 ms. The 20 ms figure only holds once an account is already upgraded.
- **Tag:** `[NOVEL]`

**A4. CPU is the only resource that matters.**
- **Source:** Implicit.
- **If wrong:** Redesign.
- **Analysis:** Argon2id at m=64 MiB allocates 64 MiB per in-flight hash. Bcrypt uses about 4 KiB. Memory headroom, container memory limits, and allocator behaviour under concurrency are not discussed.
- **Tag:** `[NOVEL]`

**A5. Every stored hash is either `$2b$` or `$argon2id$`.**
- **Source:** Implicit, step 2.
- **If wrong:** Tweak or redesign.
- **Analysis:** Libraries from 2017 often emitted `$2a$` (older node-bcrypt, many Java libraries) or `$2y$` (PHP). Accounts created before 2017 might carry an even older format. The doc does not define an else branch. This dispatch logic is not behind the flag, so it takes effect the moment the code deploys.
- **Tag:** `[NOVEL]`

**A6. Login is the only code path that writes `password_hash`.**
- **Source:** Implicit.
- **If wrong:** Redesign.
- **Analysis:** Registration, password change, password reset, and admin reset all write the column. The doc does not say whether they write bcrypt or Argon2id. If the reset path still writes bcrypt, the month-12 forced reset regenerates bcrypt hashes.
- **Tag:** `[NOVEL]`

**A7. Mobile and web are the only consumers of password hashes.**
- **Source:** Explicit, "Other consumers."
- **If wrong:** Tweak or redesign, depending on what turns up.
- **Analysis:** The list covers clients only. It omits other readers of the column itself: re-auth endpoints, other services or jobs with database access, triggers, CDC pipelines, and session fingerprints. See Coupling Analysis.
- **Tag:** `[NOVEL]`

**A8. Upgrading the hashes of active users meaningfully reduces exposure to a database leak.**
- **Source:** Implicit, from the motivation.
- **If wrong:** Redesign of the strategy.
- **Analysis:** The threat is offline cracking of a leaked database. Dormant accounts, which are likely the majority of 4.2M, stay on bcrypt for 12 months. Backups keep bcrypt hashes for every account until retention expires.
- **Tag:** `[NOVEL]`

**A9. "Login failure rate" will reveal a broken upgrade.**
- **Source:** Explicit, rollback triggers.
- **If wrong:** Tweak.
- **Analysis:** A bad Argon2id write succeeds silently. The user is already logged in. It only fails on that user's *next* login, which may be days later, and at 1% it is buried in the aggregate failure rate.
- **Tag:** `[NOVEL]`

---

## Consequence Chains

**Outcome 1: active accounts migrate to Argon2id.**
```
→ First-order: Active accounts' bcrypt hashes are overwritten with Argon2id
  → Second-order: Code versions without Argon2id verify can no longer serve those users
    → Third-order: The "redeploy previous release" rollback becomes a mass lockout,
      growing every day the flag is on. Up to ~60% of MAU by day 30.
    → Third-order: Any stale instance (DR region, canary pool, a straggler during a
      rolling deploy, a forgotten cron host, staging restored from prod) rejects
      upgraded users intermittently. This looks like flaky auth, not a clear outage.
  → Second-order: If the hash change is treated as a "password change" event
    (DB trigger, CDC consumer, or session-validity fingerprint derived from the hash)
    → Third-order: Upgraded users get logged out on all other devices, or receive
      "your password was changed" emails. Expect a support spike, phishing-style
      confusion, and possibly a security team investigating a "mass password change."
```

**Outcome 2: Argon2id adds about 20 ms per login.**
```
→ First-order: Per-login CPU rises (the doc's figure, true only at steady state)
  → Second-order: During migration, upgrading logins cost ~160 ms (bcrypt + Argon2id).
    The share of upgrading logins peaks right after each ramp step, especially 10% → 100%.
    → Third-order: At 45 logins/s/host, all upgrading, CPU demand is ~7.2 core-s/s
      vs ~3.15 today (+4 cores). Whether that fits "55% peak" depends on core count,
      which the doc does not state. On an 8-vCPU host it is ~105%.
    → Third-order: Near saturation, queueing makes p95 grow non-linearly. The
      "<40 ms p95 increase" criterion is likely missed in week 4 even if mean CPU fits.
  → Second-order: Each in-flight Argon2id holds 64 MiB
    → Third-order: A burst (credential stuffing, a mass session expiry, the 12-month
      forced-reset wave) at 200 concurrent hashes needs ~12.8 GiB per host. That
      means container OOM kills, which turn a slowdown into a login outage.
```

**Outcome 3: dormant accounts are forced to reset at month 12.**
```
→ First-order: Remaining bcrypt accounts must reset their password
  → Second-order: Reset emails go to addresses that may now be abandoned or re-registered
    → Third-order: Account takeover via expired email domains on long-dormant accounts
  → Second-order: If "force reset" sets a flag but leaves the bcrypt hash in place
    → Third-order: The bcrypt hashes stay crackable in the DB. The security goal is
      not met for exactly the population with the oldest, most-reused passwords.
  → Second-order: If the reset path writes bcrypt (A6), reset accounts land back on
    bcrypt and the "still on bcrypt" metric never reaches zero.
```

---

## Coupling Analysis

| Coupling | Visible / Invisible | Risk |
|---|---|---|
| Deployed code version ↔ hash format in DB. Every running instance must understand every format present. | **Invisible** (temporal) | High. This is what breaks rollback (A1) and any mixed-version fleet. |
| Hash dispatch logic ↔ actual prefix distribution (`$2a$`, `$2y$`, legacy) | **Invisible** (data convention) | Medium-high. Can lock users out at deploy time, before the flag is touched. |
| Other `password_hash` writers (register, change, reset, admin tools) | Visible in code, unmentioned in doc | High for forced-reset correctness. |
| Re-auth / "confirm your password" endpoints (change email, delete account, payment) that may carry their own bcrypt-only verify | **Invisible** (behavioural) | Medium. Upgraded users fail step-up auth. |
| DB triggers / CDC / audit jobs keyed on `password_hash` updates | **Invisible** | Medium. Spurious "password changed" notifications or session revocation. |
| Session validity tied to a hash fingerprint (Django-style session auth hash, or a token salt) | **Invisible** | Medium. Silent logout of all other devices on upgrade. |
| Concurrent password change ↔ upgrade write. Upgrade writes unconditionally. | **Invisible** (temporal race) | Low probability, high severity. Login B verifies the old bcrypt, password change A commits, then B overwrites with Argon2id of the *old* password. The change is silently reverted, which is worst for a user changing their password after a compromise. |
| Bcrypt 72-byte truncation / any pre-hash or pepper scheme | **Invisible** (library behaviour) | Low. After upgrade, only the exact full password works. Users whose devices differ past byte 72 get locked out. If a pepper or SHA pre-hash exists, the upgrade must reproduce it. |
| Timing behaviour for nonexistent users (dummy bcrypt hash) vs Argon2id-upgraded users | **Invisible** | Low. The 70 ms vs 90 ms difference gives a username-enumeration and "is this account active" timing oracle. |
| Backups and DB snapshots | Visible, unmentioned | Medium. Bcrypt hashes for all 4.2M accounts survive for the full retention period regardless of upgrade progress. |
| Argon2 native library ↔ build images, host architectures, container memory limits | Visible in build config | Low-medium. A new native dependency and a new memory profile. |

---

## Confidence Inversions

**"Rollback is instant and complete."**
*Scenario:* Week 2, 10%. A CPU regression appears and the team redeploys the previous release, as the doc instructs. Every account upgraded in weeks 1–2, likely tens of thousands, now fails login with a "wrong password" error. Support sees a wave of lockouts, users reset their passwords, and the incident is larger than the regression it was meant to fix. The only clean recovery is to roll forward. Under this design the "safe" lever is the most dangerous action available.

**"No schema change… every code path that reads a hash keeps working."**
*Scenario:* The reasoning is backwards. Keeping one column means every reader *receives* Argon2id strings. Only readers updated to parse them keep working. A forgotten re-auth endpoint or internal tool keeps calling bcrypt `compare`, gets `false`, and users are told their password is wrong when changing their email address.

**"Fits within current headroom."**
*Scenario:* The calculation uses the steady-state cost (90 ms), not the migration-period cost (160 ms), and ignores memory. On the week-4 flip to 100%, a Monday-morning peak combined with a routine credential-stuffing run pushes hosts into CPU saturation and memory pressure. p95 rises by hundreds of milliseconds, retries amplify the load, and the team turns the flag off. That helps CPU, but the "fix" then gets misdiagnosed as "rollback worked," which reinforces the false belief in A1.

**"Staff are unaffected because they use SSO."**
*Scenario:* Mostly sound. However, break-glass, service, or legacy staff accounts with a local password are often exactly the ones that predate 2017 and carry an odd hash prefix. This is worth a single query to confirm.

---

## Adversarial Scenarios

**1. Credential stuffing during the migration window (likely; Quillmark-sized services see this routinely).**
Failed logins against upgraded accounts now cost 90 ms of CPU and 64 MiB of memory each. Without a concurrency limiter on Argon2id, an attacker can drive memory exhaustion at far lower request rates than a bcrypt-only system tolerated. *Realistic worst case:* login hosts are OOM-killed in rotation and logins are degraded for the duration of the attack. This is not caught by the doc's success criteria, which only measure p95 under normal traffic.

**2. A latent write-path bug (maybe 10–20% likely for a first implementation).**
Examples include a wrong encoding, a parameter string mismatch between the write and verify libraries, a collation or charset issue in the column, or a pepper omitted on the new path. Each upgrade then destroys a working credential, and the failure only appears at the user's next login. *Realistic worst case:* a week at 1% produces several thousand broken accounts before anyone notices, because the aggregate failure rate barely moves. Recovery is forced resets for exactly the users the team cannot easily identify, unless the upgrade was logged.

**3. Mixed-version fleet or regional lag (likely in any rolling or multi-region deploy).**
The flag is enabled while one region or canary pool is still on the old release, or a DR failover lands on an older image. *Realistic worst case:* intermittent lockouts that depend on which host serves the request. These are very hard to diagnose because the same user succeeds on retry.

---

## Reversibility Map

| Timepoint | What reversal requires | Difficulty |
|---|---|---|
| **New code deployed, flag off** | Redeploy the old release. Safe *only if* no Argon2id hashes exist anywhere, including from registration or reset paths if those changed. | Easy. ⚠️ Except for the A5 risk: odd prefixes may already be failing. |
| **Day 1, flag at 1%** — 🔴 **CLIFF EDGE** | The first upgrade write makes the old release permanently unsafe. Flag off stops growth. Full reversal means forcing resets for every upgraded account. | Already hard. The doc implies this is the easiest point. |
| **1 week** | Same as day 1, at a larger scale: roughly 1% of logins' accounts. | Hard. Requires forced resets for thousands of accounts. |
| **1 month (100%)** | ~60% of MAU upgraded. Reverting the code is not viable. Only forward fixes. | Effectively irreversible. |
| **6 months** | The Argon2 library, dual verify paths, and the memory profile are now permanent infrastructure. | Irreversible. Only further forward migrations are possible. |

The cliff sits at the very first write, not at a late stage. Any genuine rollback window has to be bought deliberately, for example by retaining the old hash for a bounded period (see Recommendations).

---

## Cost of Success

*World after full success:* Active users are on Argon2id, login is about 20 ms slower, and a year from now dormant accounts are forced through a reset.

What's worse than today:
- **Complexity:** Two verification algorithms coexist for at least 12 months, and longer if reset or registration paths lag behind. Hash format becomes a variable that every auth bug investigation must account for.
- **Maintenance / operational:** A per-request 64 MiB allocation is now a permanent capacity and DoS concern. Login capacity planning becomes memory-bound, not just CPU-bound. Every future traffic spike or attack is more expensive to absorb.
- **Optionality:** The dispatch keys on *prefix*, not *parameters*. When the guild revises its guidance again (they did between 2017 and now), there is no mechanism to re-hash Argon2id hashes with outdated parameters. The next upgrade needs another design doc. A `needs_rehash(params)` check costs almost nothing now.
- **Opportunity:** An alternative closes the dormant-account gap on day 1: wrap existing hashes offline, as `Argon2id(bcrypt_hash)`, then unwrap on login. The upgrade-on-login-only approach rules this out unless chosen now. Success as defined leaves the largest exposure (dormant accounts plus backups) in place for a year.
- **User trust:** Users with dormant accounts get a forced-reset email out of the blue at month 12, a pattern that phishing campaigns imitate.

---

## Findings Summary

1. `[REVERSIBILITY CLIFF]` `[NOVEL]` Redeploying the previous release locks out all upgraded accounts. The cliff is at the first write, so "instant and complete" rollback is false.
2. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Upgrade-on-login is a destructive, row-by-row data migration. The bcrypt value is unrecoverable once overwritten.
3. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Capacity math omits the double-hash cost of upgrading logins (~160 ms) and assumes a core count it never states. Week-4 p95 likely exceeds the 40 ms criterion.
4. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` 64 MiB per hash makes memory a new bottleneck and a DoS amplification vector. There is no concurrency limiter.
5. `[HIDDEN COUPLING]` `[NOVEL]` Prefix dispatch assumes only `$2b$`, while `$2a$`/`$2y$`/legacy hashes may exist. This dispatch is unflagged.
6. `[HIDDEN COUPLING]` `[NOVEL]` Other writers (register, change, reset, admin) are unspecified. A bcrypt-writing reset path undermines the month-12 cleanup.
7. `[HIDDEN COUPLING]` `[NOVEL]` Other readers (re-auth endpoints, internal tools, triggers, CDC, session fingerprints) are not inventoried.
8. `[HIDDEN COUPLING]` `[NOVEL]` An unconditional upgrade write can race with a password change and revert it.
9. `[SECOND-ORDER EFFECT]` `[NOVEL]` Write-path bugs are silent until the next login. Aggregate failure rate is too blunt a rollback signal.
10. `[SECOND-ORDER EFFECT]` `[NOVEL]` Dormant accounts and backups keep bcrypt exposure for 12+ months. A forced reset that doesn't null the hash leaves it crackable.
11. `[SECOND-ORDER EFFECT]` `[NOVEL]` Forced resets to stale emails create account-takeover risk and resemble phishing.
12. `[HIDDEN COUPLING]` `[NOVEL]` Timing difference between the dummy-hash path and Argon2id leaks account existence and activity. Low severity.
13. `[HIDDEN COUPLING]` `[NOVEL]` Bcrypt 72-byte truncation or any pre-hash/pepper must be handled consistently. Low severity.
14. `[SUCCESS COST]` `[NOVEL]` There is no parameter-based rehash, so future guidance changes require another migration design.
15. `[SUCCESS COST]` `[NOVEL]` A permanent dual-algorithm path and memory-bound login capacity.

---

## Recommendations

**Must address before proceeding**

1. **Rewrite the rollback plan (findings 1, 2).**
   - Split into two releases. First ship an Argon2id-capable *verify* path and let it bake everywhere: all regions, DR, canaries, and any service that verifies passwords. Only then enable writes.
   - Once the first write happens, mark pre-Argon2 releases as non-deployable in the deploy tooling.
   - If a real rollback window is wanted, keep the old bcrypt hash in a side column (or an audit table) for a fixed 2–4 weeks, then delete it. Accept that this briefly retains the weak hash.
   - Remove the "instant and complete" language.

2. **Make the write safe (findings 8, 9).**
   - Verify the submitted password against the freshly computed Argon2id hash before writing it.
   - Write with compare-and-swap: `UPDATE … SET password_hash = :new WHERE id = :id AND password_hash = :old_bcrypt`.
   - Log each upgrade (account id, timestamp) so damage can be scoped if a bug is found.

3. **Redo capacity with real numbers (findings 3, 4).**
   - Model upgrade logins at 160–250 ms and state core counts.
   - Load-test memory at burst concurrency.
   - Add a bounded semaphore for Argon2id hashing so excess requests queue or fail fast instead of causing OOM.
   - Add intermediate ramp steps (for example 10% → 25% → 50% → 100%) so the share of upgrading logins never spikes at once.

4. **Audit the data and the code paths (findings 5, 6, 7).**
   - Run `SELECT LEFT(password_hash, 4), COUNT(*) … GROUP BY 1` before shipping, and define behaviour for every prefix found.
   - Inventory every reader and writer of `password_hash`: grep across all services, triggers, CDC consumers, and session code.
   - Make register, change, and reset write Argon2id before or alongside the flag.

**Worth mitigating**

- **Metrics (finding 9):** Segment login failures by stored hash type and by "upgraded in the last N days." That segment is the real canary.
- **Dormant accounts (finding 10):** Consider wrapping all bcrypt hashes offline as `Argon2id(bcrypt)` so dormant accounts are protected immediately.
  - Otherwise, the month-12 forced reset must replace the hash with an unusable value, not just set a flag.
  - Track backup retention as the true end date of the exposure.
- **Parameter rehash (finding 14):** Base the rehash decision on parameters (`needs_rehash`), not prefix, so future guidance changes are a config bump.
- **Forced-reset hygiene (finding 11):** Send reset emails only to verified, recently deliverable addresses, and coordinate the messaging with support.

**Acknowledged risks**

- **Timing oracle (finding 12):** Low impact. Fix cheaply by making the dummy hash Argon2id once rollout completes.
- **72-byte truncation (finding 13):** It affects very few users and they can reset. Confirm there is no pepper or pre-hash; if there is, it becomes a must-address item.
- **Temporary dual-algorithm complexity (finding 15):** This is the inherent price of upgrade-on-login. It is acceptable if a removal date is committed to.
