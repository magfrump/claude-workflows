# Task Decomposition Worked Examples

Two scenarios grounding the task-decomposition workflow from `workflows/task-decomposition.md`. Reference these when deciding whether to decompose, writing sub-agent briefings, or identifying shared dependencies.

## (a) Decomposable: Migrating Three Services to a New Auth API

**Task:** "Migrate auth, billing, and notifications from the v1 identity API to v2. v2 uses JWT instead of opaque tokens, changes the user-lookup endpoint, and adds required `org_id` scoping."

### Step 1 — Identify independent sub-investigations

The three services (auth, billing, notifications) each consume the identity API differently, but they all depend on the same shared concept: how v2's JWT/org-scoping model works. Decomposition:

- **Shared dependency**: v2 API contract — JWT structure, `org_id` scoping rules, new user-lookup endpoint shape. Must be researched first so sub-agents share a common understanding.
- **Independent area A**: Auth service — how it validates tokens today, where v1 endpoints are called, what auth middleware needs to change.
- **Independent area B**: Billing service — how it resolves user identity for invoice records, what fields it reads from the v1 response.
- **Independent area C**: Notifications service — how it looks up user contact info, whether it caches identity responses.

Each area can be researched without understanding the others. The shared dependency (v2 contract) must come first.

### Step 2 — Research the shared dependency

The main agent reads the v2 API docs and the existing v1 client wrapper (`src/lib/identity-client.ts`). It produces a research doc section covering:
- JWT claims structure (`sub`, `org_id`, `roles[]`)
- The new `/v2/users/{id}` response shape vs. the old `/v1/users/{id}`
- Breaking changes: `org_id` is now required on all lookup calls; tokens are validated locally instead of via introspection endpoint

This research is included in every sub-agent briefing so they don't re-investigate it.

### Step 3 — Dispatch sub-agents with focused briefings

**Sub-agent A (auth service):**
> "We're migrating from identity API v1 to v2. v2 uses JWTs (claims: sub, org_id, roles[]) validated locally instead of opaque tokens validated via introspection. Examine `src/auth/middleware.ts` and `src/auth/token-validator.ts`. Answer: (1) Where does token introspection happen today? (2) What fields from the introspection response are used downstream? (3) Are there tests covering auth failure cases? Report in under 300 words."

**Sub-agent B (billing service):**
> "We're migrating from identity API v1 to v2. The user-lookup endpoint changes from `/v1/users/{id}` to `/v2/users/{id}` and now requires `org_id` as a query parameter. Examine `src/billing/invoice-service.ts` and `src/billing/user-resolver.ts`. Answer: (1) Which v1 user-lookup fields does billing actually use? (2) Where does it get the user ID from? (3) Does it have access to `org_id` in its current call chain? Report in under 200 words."

**Sub-agent C (notifications service):**
> "We're migrating from identity API v1 to v2. Same endpoint change as billing (see above). Examine `src/notifications/` directory. Answer: (1) How does it resolve user contact info (email, phone)? (2) Does it cache identity responses? If so, what's the TTL and invalidation strategy? (3) Does it batch user lookups or call per-notification? Report in under 200 words."

**What makes these briefings work:**
- Each states the goal and the relevant v2 context (the sub-agent has zero prior knowledge)
- Each points to specific files, not "look around the service"
- Each asks numbered questions with testable answers, not open-ended "how does this work?"
- Each caps output length to prevent walls of text the main agent has to re-read

### Step 4 — Synthesize into unified research doc

Sub-agents return their findings. The main agent writes `docs/working/research-identity-v2-migration.md` in RPI format:

- **Scope**: Migrate three services from identity API v1 to v2
- **What exists**: Auth uses introspection (can switch to local JWT validation), billing reads `email` and `plan_tier` from user-lookup (both fields exist in v2), notifications caches user contact info for 5 minutes (cache key needs `org_id` added)
- **Invariants**: All three services must continue working during rollout — need a feature flag or v1/v2 dual-path
- **Gotchas**: Notifications cache doesn't include `org_id` in its key — could serve cross-org stale data after migration. Billing has no access to `org_id` in its current call chain — needs to be threaded through from the auth context.

### Step 5 — Plan and implement sequentially

From here, normal RPI: write a plan addressing all three services as a coherent sequence (shared client wrapper first, then auth, then billing, then notifications), implement, test.

**Why decomposition helped:** Three sub-agents researched three services in parallel. Without decomposition, the main agent would have read through all three sequentially, filling its context with details about the first service before getting to the third. The parallel research took one round instead of three, and each sub-agent's focused briefing produced concise, targeted findings.

---

## (b) Counter-Example: Tightly Coupled Refactor That Shouldn't Be Decomposed

**Task:** "Refactor the `Order` model to split `status` (a string enum covering payment, fulfillment, and shipping states) into three separate status fields: `paymentStatus`, `fulfillmentStatus`, and `shippingStatus`."

### Why it looks decomposable

The task touches three subsystems (payment, fulfillment, shipping). You might think:
- **Area A**: Payment-related code that reads/writes `order.status`
- **Area B**: Fulfillment-related code that reads/writes `order.status`
- **Area C**: Shipping-related code that reads/writes `order.status`

### Why decomposition hurts here

**The subsystems are not independent.** Every read/write of `order.status` must be classified as belonging to payment, fulfillment, or shipping — and that classification is the hard part. Consider:

- `order.status === 'PAID_AWAITING_FULFILLMENT'` — is this a payment status or a fulfillment status? It's a transition between both. A sub-agent looking at payment code and a sub-agent looking at fulfillment code would both claim it, or neither would, and the main agent would spend more time resolving the contradiction than it saved.
- The database migration must change all three fields atomically. You can't migrate payment statuses independently of fulfillment statuses because the old `status` column encodes combinations of both.
- State machine transitions like `SHIPPED → DELIVERED` and `PAID → REFUNDED` interact: a refund after shipping requires coordinating `paymentStatus` and `shippingStatus` in the same transaction.

**The coordination overhead exceeds the research savings.** Each sub-agent would need to understand the full state machine to correctly classify "its" statuses. That means each briefing would need to include the same full context, and the synthesis step would be dominated by resolving conflicting classifications.

### What to do instead

Use normal RPI. Research the full `Order` state machine in one pass: enumerate every status value, map each to its new field, identify transition points that span multiple fields. The shared understanding is the task — it can't be partitioned.

**Litmus test:** If every sub-agent would need the same context to do its job, decomposition adds overhead without enabling parallelism. Decompose when sub-tasks have genuinely independent research scopes. Don't decompose when the shared dependency *is* the task.
