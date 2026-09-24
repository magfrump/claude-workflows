We need to pick how Larkspur Orders runs background jobs (sending order confirmation emails, generating invoices, syncing stock counts to the warehouse system). The options on the table are:

- a Postgres-backed queue in our existing orders database, using `SELECT ... FOR UPDATE SKIP LOCKED`
- Redis with a Sidekiq-style worker library
- Amazon SQS with a Lambda consumer
- keep the current approach: a cron job every five minutes that scans for unsent work

Context we're sure of:

- We run on a single managed Postgres 16 instance and three app servers. We have no Redis and no AWS account; the company's hosting contract covers only what we already run, and procurement for a new vendor takes about two quarters.
- Operations is one person, part-time.
- A job must be enqueued in the same transaction as the order row it belongs to: last year the cron approach sent confirmation emails for orders whose transaction later rolled back, and we refunded 212 customers by hand.
- Peak volume is about 40 jobs a minute. The cron's five-minute delay is the main customer complaint.

Which approach should we use?
