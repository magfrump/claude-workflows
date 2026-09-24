# Design doc: Upgrade stored password hashes from bcrypt to Argon2id

**Service:** `accounts-api`, Quillmark · **Reviewers:** Security guild, Identity team

## Motivation

Our password hashes use bcrypt at cost 10, chosen in 2017. The security guild's
current guidance is Argon2id with 64 MiB memory, 3 iterations and parallelism 1.
Bcrypt at cost 10 now falls short of that guidance against GPU cracking for a
database of our size (4.2 million accounts).

## Approach: upgrade on login

We cannot re-hash passwords we do not have, so we upgrade each account the next
time its owner logs in successfully:

1. The user submits a password.
2. `accounts-api` loads the stored hash. If it starts with `$2b$` (bcrypt), it
   verifies with bcrypt; if it starts with `$argon2id$`, it verifies with
   Argon2id.
3. If verification succeeds, the flag `hash_upgrade_enabled` is on, and the
   stored hash is bcrypt, the service computes an Argon2id hash of the submitted
   password and writes it to the `password_hash` column in place of the bcrypt
   value.

Accounts that never log in keep their bcrypt hash. After 12 months we will
force a password reset for any account still on bcrypt.

## Schema

No schema change. `password_hash` is `VARCHAR(255)`, which fits both formats.
We keep one column so that every code path that reads a hash keeps working.

## Rollout and rollback

The upgrade-on-login write sits behind the `hash_upgrade_enabled` flag.

- Week 1: 1% of logins.
- Week 2: 10%.
- Week 4: 100%.

**Rollback is instant and complete.** If we see elevated login failures, CPU
pressure from Argon2id, or any other problem, we turn `hash_upgrade_enabled`
off. That stops all further upgrades immediately, and if needed we can then
redeploy the previous `accounts-api` release, which predates this work
entirely. No data migration is involved at any stage, so there is nothing to
roll back in the database.

## Capacity

Argon2id at these parameters takes about 90 ms of CPU per verification on our
login hosts, against about 70 ms for bcrypt cost 10. At our peak of 45 logins
per second per host this is a 20 ms increase per login and fits within current
headroom (hosts peak at 55% CPU today).

## Other consumers of password hashes

- The mobile app and the web app never see hashes; both call `accounts-api`.
- Staff accounts authenticate through SSO and have no `password_hash` value, so
  they are unaffected.

## Success criteria

- 60% of monthly active accounts on Argon2id within 30 days of reaching 100%.
- No increase in the login failure rate.
- p95 login latency increase under 40 ms.
