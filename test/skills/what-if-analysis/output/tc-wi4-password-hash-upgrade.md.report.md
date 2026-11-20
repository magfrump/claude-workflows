# What-If Analysis: bcrypt → Argon2id upgrade-on-login for `accounts-api`

**Proposal:** Design doc "Upgrade stored password hashes from bcrypt to Argon2id" (Quillmark `accounts-api`), supplied inline
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output — this skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository was available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. Everything below is tagged `[NOVEL]` because there is no baseline to compare against.

---

## Assumptions Examined

- **Assumption:** Redeploying the previous `accounts-api` release is a safe rollback.
  - **Source:** explicit ("Rollout and rollback": "we can then redeploy the previous `accounts-api` release, which predates this work entirely")
  - **If wrong:** redesign. The previous release only knows bcrypt. Every account already rewritten to `$argon2id$` fails verification under it. The rollback plan has to be rebuilt around a dual-verifier release that becomes the permanent floor.
  - **Tag:** `[NOVEL]`

- **Assumption:** "No data migration is involved at any stage, so there is nothing to roll back in the database."
  - **Source:** explicit ("Rollout and rollback")
  - **If wrong:** redesign. Upgrade-on-login is a data migration, done one row at a time. Each upgrade overwrites the bcrypt value in place and does not keep the old one. That overwrite is the irreversible part.
  - **Tag:** `[NOVEL]`

- **Assumption:** Every stored bcrypt hash starts with `$2b$`.
  - **Source:** explicit (Approach step 2), with an implicit claim that nothing else exists
  - **If wrong:** tweak, but a high-severity one. Hashes from 2017-era libraries are often `$2a$` or `$2y$`. Imported or acquired accounts may use other formats. NULLs exist for staff. If the new dispatch only matches `$2b$` and `$argon2id$`, every other row fails login on the day the new release ships, before the flag matters at all.
  - **Tag:** `[NOVEL]`

- **Assumption:** `accounts-api` is the only code that reads or verifies `password_hash`.
  - **Source:** implicit ("Other consumers" lists only the mobile app, the web app and staff SSO; "Schema" says one column keeps "every code path that reads a hash" working)
  - **If wrong:** redesign. Any other reader that calls bcrypt directly will reject upgraded users. Examples: a legacy admin tool, a second service with DB access, a re-auth endpoint in another repo, a basic-auth or API path. Because the column type is unchanged, nothing fails at schema level. It fails at runtime, per user, as an ordinary "wrong password".
  - **Tag:** `[NOVEL]`

- **Assumption:** Writing a new value to `password_hash` has no side effects beyond storing it.
  - **Source:** implicit
  - **If wrong:** redesign. Many systems treat any change to the password hash as a password change. Possible effects: "your password was changed" security emails, invalidation of all other sessions (for example, a session token or session-auth hash derived from the stored hash), a reset of a `password_changed_at` timestamp, fraud or audit signals, and CDC events. Each successful upgrade would fire all of them.
  - **Tag:** `[NOVEL]`

- **Assumption:** The upgrade write cannot conflict with other writes to the same row.
  - **Source:** implicit (step 3 describes an unconditional overwrite)
  - **If wrong:** redesign of the write. If a login with the old password races a password change or reset, the upgrade can overwrite the new password's hash with an Argon2id hash of the old password.
  - **Tag:** `[NOVEL]`

- **Assumption:** Argon2id costs about 20 ms more CPU per login than today.
  - **Source:** explicit ("Capacity")
  - **If wrong:** redesign of capacity and success criteria. The 20 ms figure only holds for an account that is already upgraded. An upgrade login runs a bcrypt verify and then an Argon2id hash, about 160 ms in total. Upgrade logins are the majority for the first weeks at 100%. The doc also never prices memory: 64 MiB per concurrent hash.
  - **Tag:** `[NOVEL]`

- **Assumption:** New passwords (signup, change, reset) are already, or will be, written as Argon2id.
  - **Source:** implicit. The doc only covers the login path.
  - **If wrong:** tweak. If set-password still writes bcrypt, the system keeps creating bcrypt rows. The 12-month forced reset then never finishes, and reset accounts land back on bcrypt.
  - **Tag:** `[NOVEL]`

- **Assumption:** Active users submit their password often enough to be upgraded within 12 months.
  - **Source:** implicit (the forced reset targets accounts "still on bcrypt", read as dormant ones)
  - **If wrong:** tweak. Users on long-lived mobile refresh tokens, "remember me" sessions or social login may never type a password. They are active, yet they get force-reset.
  - **Tag:** `[NOVEL]`

- **Assumption:** Upgrading active accounts meaningfully addresses the threat in the motivation (GPU cracking of a stolen database).
  - **Source:** implicit (motivation versus the success criteria)
  - **If wrong:** redesign of scope. The success metric is 60% of *monthly active* accounts, not of 4.2M. If MAU is a fraction of the total, most hashes stay bcrypt for 12 months. Every existing backup and replica snapshot keeps bcrypt hashes for all 4.2M for as long as backups are retained.
  - **Tag:** `[NOVEL]`

## Consequence Chains

**Outcome 1: active accounts move to Argon2id**

```
→ First-order: upgrade logins rewrite password_hash to $argon2id$
  → Second-order: each rewrite looks like a password change to anything watching the column
    → Third-order: security-notification pipeline emails "your password was changed" to up to millions of users; support volume spikes; phishing-awareness training now teaches users to ignore real alerts
    → Third-order: if session validity is tied to the hash, every upgraded user is logged out on all other devices; logins rise, which triggers more upgrades and more CPU, a self-feeding loop during the 100% ramp
  → Second-order: rows are no longer readable by bcrypt-only code
    → Third-order: any unmapped bcrypt reader starts failing for exactly the users who logged in recently, the most active and most vocal ones, at a growing rate that looks like "users forgetting passwords"
```

**Outcome 2: the rollout ramps with a flag as the safety valve**

```
→ First-order: at 10% (week 2), about 10% of logins take the bcrypt+Argon2id path (~+90 ms CPU)
  → Second-order: p95 latency rises by ~90 ms, breaching the "<40 ms" success criterion by design
    → Third-order: on-call follows the doc ("any other problem") and turns the flag off, then redeploys the previous release "if needed"
      → Third-order: every account upgraded so far gets locked out; login failures spike, and the rollback causes the incident it was meant to end
```

**Outcome 3: dormant accounts are force-reset at 12 months**

```
→ First-order: accounts still on bcrypt get a forced reset
  → Second-order: users with dead email addresses cannot recover; their accounts are effectively lost
  → Second-order: active token-only users are caught by the reset at the same time
    → Third-order: a burst of reset emails and resets in a short window (deliverability and spam-reputation risk, support load)
  → Second-order: if "forced reset" only sets a flag and leaves the bcrypt value in place, the crackable hash stays in the DB and all future backups. The security goal is not met even after year one.
```

## Coupling Analysis

| Coupling | Visibility | Why it matters |
|---|---|---|
| Previous `accounts-api` release ↔ hash format | Invisible (deploy pipeline treats the last release as a safe target) | The rollback floor moves the moment the first Argon2id row exists. Automated rollback tooling, canary auto-revert and autoscaling from a stale image could all put bcrypt-only code back into the fleet. |
| Mixed-version fleet during deploys | Invisible (timing) | During any rolling deploy or partial revert, an upgraded user routed to an old instance fails. The failures look random and are hard to diagnose. |
| Other readers of `password_hash` (other services, scripts, admin tools, ETL, a password-history table) | Visible in principle (DB grants, `import bcrypt` across repos), unmapped in the doc | Single-column reuse hides them. They break silently instead of failing loudly. |
| Change triggers on `password_hash` (notifications, session invalidation, `password_changed_at`, audit/fraud, CDC) | Invisible (behavioral contract: "hash changed ⇒ user changed password") | Turns a background migration into a user-visible event for millions. |
| Password-change and reset flows ↔ upgrade write | Invisible (temporal; nothing orders them) | Lost update: a password change can be reverted to the old password. If the reset was triggered by account compromise, an attacker logging in with the old password at the right moment could undo it. |
| Set-password path ↔ hash algorithm | Visible in code, not in the doc | Decides whether the bcrypt population shrinks or keeps growing. |
| bcrypt's 72-byte truncation (and NUL handling in some libraries) ↔ Argon2id hashing full input | Invisible (library behavior) | bcrypt accepted any input whose first 72 bytes matched. Argon2id stores whatever the user typed at upgrade time. Low severity: it only affects passwords over 72 bytes whose submissions vary past byte 72. |
| Argon2id memory ↔ container or host memory limits and worker pool size | Visible in config | 64 MiB × concurrent hashes. A burst of 50 concurrent verifications needs about 3.2 GiB. If the runtime hashes on a small fixed thread pool, CPU time turns into queueing latency. |
| Hash verification on non-login hosts (re-auth for sensitive actions, password change, account deletion) | Possibly invisible | The capacity analysis covers "login hosts" only. |

## Confidence Inversions

**"Rollback is instant and complete."** This is the most confident claim in the doc and it is false after the first upgraded row. Concrete scenario: in week 1 an Argon2id library bug causes a small rate of verify errors. The team turns the flag off. That stops new upgrades but does nothing for the accounts already upgraded, because the failure is in the verify path and that path stays on. The team then redeploys the previous release, which locks out all upgraded accounts rather than a few. The real rollback options are a fix-forward, a downgrade-on-login release (new code), or forced resets for the affected accounts. None of these are instant.

**"No data migration is involved."** This is a migration with no snapshot of the prior state. Concrete scenario: in month 2 a compliance or FIPS requirement surfaces that the team's Argon2id build cannot meet, or an interop partner needs bcrypt. The original bcrypt values are gone, so getting back requires each user to log in again (with downgrade code) or reset.

**"Fits within current headroom."** Concrete scenario: the ramp hits 100% during the week's peak. Most logins are upgrade logins at about 160 ms CPU each. At 45 logins/s that is about 7.2 cores of hashing per host, against about 3.15 today, so about 4 more cores. On an 8-core host at 55% (about 4.4 cores busy), that is more than 100% demand. On a 16-core host it is about 80%. The doc gives no core count, so headroom is unproven. Steady state after the ramp (+20 ms/login, about +0.9 cores) is fine. The transition is the risk.

**"Staff accounts are unaffected."** This is plausible. It is worth a one-line query to confirm that no staff, service or break-glass account has a non-null `password_hash`.

## Adversarial Scenarios

1. **Mass re-login during the ramp (about 10–20% likely over a 4-week rollout).** Causes include a session-store incident, a forced logout after an unrelated security event, a mobile release that drops refresh tokens, or the hash-change session invalidation described above. Login rate jumps several times above the 45/s peak while most logins are still upgrade logins. Realistic worst case: CPU saturation and memory pressure on login hosts, a login brownout, and an on-call reaching for the redeploy rollback.

2. **Credential stuffing against a growing Argon2id population.** Wrong passwords never trigger upgrades. Each failed attempt on an upgraded account still costs 90 ms CPU and 64 MiB. Without a concurrency cap on hashing, an attacker can drive memory use per host, not only CPU. Realistic worst case: OOM kills on login hosts during an attack that would have been absorbed under bcrypt. Severity is moderate, since rate limiting probably exists, but the memory dimension is new.

3. **The database or a backup leaks during the 12-month window.** This is the threat the doc exists to address. Realistic worst case: the leak includes millions of bcrypt cost-10 hashes (dormant accounts plus all historical backups). The upgrade protected the minority of rows that attackers are least likely to profit from, because active users are also the ones who rotate passwords. If dormant accounts reuse passwords elsewhere, the downstream harm is unchanged.

## Reversibility Map

- **Before the first upgrade write:** fully reversible. Turning the flag off or redeploying the old release is safe.
- **1 week (1% of logins, likely tens of thousands of upgraded accounts):** turning the flag off stops growth. Redeploying the previous release locks out every upgraded account. Returning to a bcrypt-only world needs new downgrade-on-login code or resets for those accounts.
- **1 month (100% for about a week, heading toward 60% of MAU):** same mechanism at much larger scale. A redeploy of the old release would be a mass lockout of the most active users. The dual-verifier release is now the permanent floor.
- **6 months:** same, plus whatever has been built on Argon2id-only assumptions (new services, tooling, parameter changes). Undoing it means a migration in the other direction.

**Cliff edge:** the first Argon2id write, in week 1 at 1%. After it, undoing the change needs new code or user action. After that point the gradient grows in magnitude but does not change in kind. The doc places the cliff nowhere and describes the opposite.

The 12-month forced reset is also one-way: dead-email accounts are lost. The proposal schedules it as its own later step, so it is not tagged as a cliff here. It is still listed as a consequence in Outcome 3 and in Recommendations.

## Cost of Success

Suppose everything works. By month 2, 60%+ of MAU are on Argon2id, latency settled at +20 ms, and no failures occurred. By month 12, dormant accounts are reset. What is worse than today:

- **Complexity:** `accounts-api` carries two verifiers, format dispatch and an upgrade write path for at least 12 months. Realistically it carries them longer, because the reset will not reach every row. Every auth change during that time has to be tested against both formats.
- **Maintenance:** bcrypt remains a security-critical dependency alongside Argon2id. Hashing is now memory-heavy, so login hosts need memory planning and a concurrency limiter that did not matter before.
- **Permanent per-login cost:** about +29% CPU per verification forever, plus 64 MiB per concurrent hash. The cost of absorbing a stuffing attack also rises.
- **Optionality:** the upgrade logic is keyed on the `$2b$` prefix. The next parameter bump (Argon2id m=64 MiB → higher) would need the same machinery rebuilt unless it is generalized now to "rehash if the stored parameters are below the current policy".
- **User cost:** dormant users with dead emails permanently lose their accounts at month 12.
- **Opportunity:** a year of identity-team attention goes into a hash migration rather than, for example, passkeys. Passkeys would remove the stored-hash threat for the users who adopt them.

## Findings Summary

1. `[REVERSIBILITY CLIFF]` The first Argon2id write makes "redeploy the previous release" a lockout event. The doc's "instant and complete" rollback claim is false from week 1. `[NOVEL]`
2. `[UNEXAMINED ASSUMPTION]` "No data migration" is wrong. In-place overwrites without keeping the old value are an irreversible per-row migration. `[NOVEL]`
3. `[HIDDEN COUPLING]` Mixed-version fleets (rolling deploys, auto-revert, stale images) produce intermittent failures for upgraded users. `[NOVEL]`
4. `[HIDDEN COUPLING]` Possible side effects of any `password_hash` change: security emails, session invalidation, `password_changed_at` resets, audit/fraud/CDC events. `[NOVEL]`
5. `[HIDDEN COUPLING]` Lost-update race. An unconditional upgrade write can revert a concurrent password change or compromise-driven reset to the old password. `[NOVEL]`
6. `[UNEXAMINED ASSUMPTION]` `$2b$`-only prefix matching. `$2a$`, `$2y$`, NULL or legacy formats would fail login at deploy, independent of the flag. `[NOVEL]`
7. `[HIDDEN COUPLING]` Unmapped readers of `password_hash` outside `accounts-api` break silently for upgraded users. `[NOVEL]`
8. `[UNEXAMINED ASSUMPTION]` The capacity math covers steady state only. Upgrade logins cost about 160 ms CPU, and the ramp may exceed host CPU. Memory (64 MiB per hash) is unaddressed. `[NOVEL]`
9. `[SECOND-ORDER EFFECT]` The p95 <40 ms success criterion is breached by design at 10% (+~90 ms on upgrade logins). Combined with the rollback instructions, a predictable latency breach leads to a lockout. `[NOVEL]`
10. `[UNEXAMINED ASSUMPTION]` The set-password, signup and reset paths may still write bcrypt, so the bcrypt population would never converge. `[NOVEL]`
11. `[SECOND-ORDER EFFECT]` Active users who never type a password (token, remember-me or social login) get force-reset at month 12. `[NOVEL]`
12. `[UNEXAMINED ASSUMPTION]` The MAU-based metric hides that most of the 4.2M hashes, and all backups, stay bcrypt through year one. The motivating threat is largely unaddressed during that period. `[NOVEL]`
13. `[SECOND-ORDER EFFECT]` If the forced reset does not overwrite or null the bcrypt value, crackable hashes persist indefinitely. `[NOVEL]`
14. `[HIDDEN COUPLING]` bcrypt's 72-byte truncation versus Argon2id's full-input hashing. Low severity. `[NOVEL]`
15. `[SECOND-ORDER EFFECT]` Memory-hard verification raises the per-attempt cost of credential stuffing, and that cost now includes memory as well as CPU. `[NOVEL]`
16. `[SUCCESS COST]` A dual-verifier path that lasts more than 12 months, a permanent +20 ms and memory overhead, a prefix-specific upgrade that will need rebuilding for the next parameter bump, and lost dormant accounts. `[NOVEL]`

## Recommendations

**Must address before proceeding**

- **Rewrite the rollback plan (findings 1–3, 9).** Ship in two phases. Phase 1 releases dual verification with the upgrade write off. Let it bake and declare it the minimum allowed release: pin it in the deploy tooling, rebuild base images, and disable auto-revert below it. Phase 2 turns the write on. State explicitly that turning the flag off is the only rollback, and that the response to Argon2id verify problems is fix-forward or targeted resets. If a way back to bcrypt is needed, build a downgrade-on-login path before phase 2, or keep the bcrypt value in a side column for N weeks.
- **Make the upgrade write conditional (finding 5).** `UPDATE ... SET password_hash = :argon WHERE id = :id AND password_hash = :bcrypt_value_just_verified`. If zero rows are updated, the write was a lost race; do nothing.
- **Inventory the hash formats (finding 6).** Run `SELECT LEFT(password_hash, 4), COUNT(*) ... GROUP BY 1`, including NULLs, before the dual verifier ships. Handle every prefix found, or route unknown prefixes to the current code path, not to "fail".
- **Map every reader and every side effect of `password_hash` (findings 4, 7).** Check DB grants on the column, triggers and CDC subscribers, grep all repos for bcrypt usage, and check how sessions are validated. Exempt upgrade writes from "password changed" handling. One way is a separate `password_changed_at` that the upgrade path does not touch, and session keys that do not derive from the hash.
- **Redo the capacity analysis for the transition (findings 8, 9, 15).** Measure CPU per upgrade login (bcrypt + Argon2id) against real core counts at peak, add a concurrency limiter sized to the memory budget, and load-test a 3–5× login burst. Rewrite the latency criterion with separate targets for upgrade logins and steady-state logins, so the ramp does not trip its own rollback trigger.

**Worth mitigating**

- **Confirm the set-password, signup and reset paths write Argon2id (finding 10).** Watch signal: a daily count of new bcrypt rows should be zero.
- **Close the dormant-account gap (findings 12, 13).** Consider wrapping existing hashes so all 4.2M rows are protected now rather than in 12 months: store `argon2id(bcrypt_hash)` under a distinct prefix and verify it by computing bcrypt, then Argon2id. This is one batch job and costs extra login CPU for wrapped rows. Make the forced reset overwrite the bcrypt value, not just set a flag. Track progress against all 4.2M accounts, not only MAU. Set a backup-retention date after which old bcrypt-bearing backups are destroyed.
- **Before month 12, find active accounts that never submitted a password (finding 11).** Prompt them in-app for re-authentication instead of force-resetting them by email.
- **Generalize the upgrade trigger (finding 16).** Use "rehash if the stored algorithm or parameters are below policy" instead of "if prefix is `$2b$`".

**Acknowledged risks**

- **Permanent +20 ms per login and higher per-host memory.** This is the intended security tradeoff and steady state fits the stated CPU headroom.
- **bcrypt 72-byte truncation (finding 14).** It affects a negligible number of users, and they can recover through a password reset.
- **Running two verifiers for about a year.** This is inherent to any upgrade-on-login scheme. It is acceptable once the dual-verifier release is pinned as the floor.
