> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# API Consistency Review: `subject.py` webhook routes

**Scope:** `subject.py`, the block between `BEGIN CHANGE UNDER REVIEW` and `END CHANGE UNDER REVIEW` (lines 60–82). Lines 1–59 are the baseline.
**Date:** 2026-11-19

---

## Baseline Conventions

These come from the existing API-key and Slack-channel resources (`subject.py:14-57`):

- **Router and versioning:** every route is under `APIRouter(prefix="/v1")`.
- **Route paths:** plural snake_case collection nouns (`/api_keys`, `/slack_channels`). A single item is `/<collection>/{<noun>_id}` (`{key_id}`, `{channel_id}`).
- **Handler names:** `create_<resource>` for POST and `get_<resource>` for GET by ID, in snake_case and singular.
- **Model names:** `<Resource>Create` is the request body and a bare `<Resource>` is the response (`ApiKeyCreate`/`ApiKey`, `SlackChannelCreate`/`SlackChannel`). There are no `DTO`/`Request`/`Response` suffixes.
- **Field names:** snake_case. **Every field you can write in the create model appears under the same name in the read model** (`label`/`scopes` → `label`/`scopes`; `channel_name`/`notify_on` → `channel_name`/`notify_on`). The read model adds only server-generated fields: `id: str` and `created_at: datetime`.
- **Event subscription field:** the one existing "which events trigger this" field is `notify_on: list[str]` (`subject.py:28,34`).
- **Status codes:** POST returns `201` with the created resource. GET returns the default `200`.
- **Auth:** every handler takes `account: Account = Depends(current_account)` and scopes store calls by `account.id`.
- **Idempotency:** no idempotency key on any create endpoint.
- **Lists and pagination:** there are no list endpoints, so no pagination convention exists.
- **Errors:** no explicit error handling in the routes. Not-found and validation behaviour is left to the store layer and FastAPI defaults.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `POST /webhooks` | route | `POST /api_keys`, `POST /slack_channels` | `subject.py:38,48` | Consistent: plural collection noun under `/v1` |
| `GET /webhooks/{webhook_id}` | route | `GET /api_keys/{key_id}`, `GET /slack_channels/{channel_id}` | `subject.py:43,55` | Consistent: `{<noun>_id}` path parameter |
| `create_webhook` | function | `create_api_key`, `create_slack_channel` | `subject.py:39,49` | Consistent |
| `get_webhook` | function | `get_api_key`, `get_slack_channel` | `subject.py:44,56` | Consistent |
| `WebhookCreate` | type | `ApiKeyCreate`, `SlackChannelCreate` | `subject.py:14,26` | Consistent: `<Resource>Create` |
| `Webhook` | type | `ApiKey`, `SlackChannel` | `subject.py:19,31` | Consistent: bare noun |
| `Webhook.id` | field | `ApiKey.id`, `SlackChannel.id` | `subject.py:20,32` | Consistent |
| `Webhook.created_at` | field | `ApiKey.created_at`, `SlackChannel.created_at` | `subject.py:23,35` | Consistent |
| `WebhookCreate.target_url` | field | `Webhook.url` (its own read counterpart); no other URL fields | `subject.py:62,68`; create/read symmetry in `subject.py:14-35` | **Inconsistent:** request and response use different names for the same value |
| `Webhook.url` | field | `WebhookCreate.target_url`; no other URL fields | `subject.py:62,68` | **Inconsistent:** see above |
| `WebhookCreate.event_types` | field | `Webhook.events`, `SlackChannelCreate.notify_on` | `subject.py:28,63,69` | **Inconsistent:** differs from its own read field and from the sibling's event-subscription field |
| `Webhook.events` | field | `WebhookCreate.event_types`, `SlackChannel.notify_on` | `subject.py:34,63,69` | **Inconsistent:** see above |

---

## Findings

#### 1. Webhook request and response use different names for the URL field (`target_url` in, `url` out)

**Severity:** Inconsistent
**Location:** `subject.py:62`, `subject.py:68`, `subject.py:75-76`
**Move:** #7 Asymmetry (naming-shaped), #2 Naming
**Confidence:** High

Precedent: create model and read model use identical names for every writable field, in `subject.py:14-35` (`ApiKeyCreate.label`/`ApiKey.label`, `SlackChannelCreate.channel_name`/`SlackChannel.channel_name`)

Every existing resource lets a consumer send a body to `POST` and get back a resource whose writable fields have the same names. Clients rely on that to round-trip objects, for example to build a form from the read model or diff what they sent against what they got back. `WebhookCreate` takes `target_url`, but `Webhook` returns `url`, so a client that posts `{"target_url": ...}` gets back `{"url": ...}`. The handler also renames the field internally (`url=str(body.target_url)`), which shows the store and response already treat `url` as the name. This is the only resource where the same value has two names. When a future `PATCH /webhooks/{webhook_id}` is added, it will have to pick one, and either choice breaks symmetry with one of the existing models.

**Recommendation:** Use one name in both models. The response and store already use `url`, so renaming `WebhookCreate.target_url` to `url` is the smallest change. This hasn't shipped yet, so fixing it now costs nothing. Once clients depend on it, it becomes a breaking change.

---

#### 2. Webhook event subscription field has different names in request and response (`event_types` in, `events` out)

**Severity:** Inconsistent
**Location:** `subject.py:63`, `subject.py:69`, `subject.py:75-76`
**Move:** #7 Asymmetry (naming-shaped), #2 Naming
**Confidence:** High

Precedent: create model and read model use identical names for every writable field, in `subject.py:14-35` (`SlackChannelCreate.notify_on`/`SlackChannel.notify_on`, `ApiKeyCreate.scopes`/`ApiKey.scopes`)

This is the same create/read mismatch as Finding 1, on a second field: consumers send `event_types` and read back `events`. Two renamed fields out of two writable fields means none of the webhook payload round-trips. A consumer can't reuse a `Webhook` response as a `WebhookCreate` body, and generated SDK types will show two unrelated-looking fields.

**Recommendation:** Pick one name and use it in both models (and see Finding 3 on which name to pick).

---

#### 3. Webhook event subscription field doesn't follow the existing `notify_on` name

**Severity:** Minor
**Location:** `subject.py:63`, `subject.py:69`
**Move:** #2 Naming
**Confidence:** Medium

Precedent: `notify_on: list[str]` as the "events that trigger this integration" field, in `subject.py:28,34` (`SlackChannelCreate`, `SlackChannel`)

Both Slack channels and webhooks are account integrations (the module docstring says "routes for account integrations") that fire on a set of event names given as `list[str]`. The existing integration calls this `notify_on`. The new one calls it `event_types` or `events`. A consumer setting up both integrations has to learn two names for the same idea, and shared client code (such as a "choose which events trigger this integration" component) can't treat them the same way. I rated this Medium confidence because there is only one precedent. The two resources may also take different event vocabularies, which would weaken the case for a shared name.

**Recommendation:** If webhooks and Slack channels subscribe to the same event names, call the field `notify_on` to match. If you deliberately want a different name (say, `events` reads better for webhooks), make that a conscious decision and plan to align Slack channels later rather than keeping two names for good.

---

#### 4. Webhook URL may come back normalized, not as sent

**Severity:** Informational
**Location:** `subject.py:62`, `subject.py:68`, `subject.py:75`
**Move:** #8 Nullability / contract, #7 Asymmetry
**Confidence:** Low

`target_url` is validated as `HttpUrl`, then stored as `str(body.target_url)` and returned as `HttpUrl`. Depending on the Pydantic version, `HttpUrl` normalizes input; Pydantic v2, for example, adds a trailing `/` to a bare host. So a client may send `https://example.com` and get back `https://example.com/`. No existing field uses `HttpUrl`, so there is no baseline here. I'm flagging it because clients that check "what I sent equals what I stored" will see a spurious mismatch.

**Recommendation:** Document that the URL is returned in normalized form, or store and return the raw string if exact round-tripping matters.

---

#### 5. `create_webhook` builds its response by hand; sibling handlers return the store result

**Severity:** Informational
**Location:** `subject.py:75-76` vs `subject.py:40`, `subject.py:50-52`, `subject.py:81`
**Move:** #1 Baseline, #7 Asymmetry
**Confidence:** Medium

Every other handler, including the new `get_webhook`, returns the store object directly and lets `response_model` serialize it. `create_webhook` alone builds a `Webhook(...)` field by field. The wire output is the same today. The risk is drift between the two webhook endpoints: if a field is added to `Webhook` and the store, `get_webhook` will return it automatically but `create_webhook` won't until someone updates the hand-written constructor. That is exactly the create/read asymmetry consumers notice.

**Recommendation:** Return `store.webhooks.create(...)` directly, as the sibling handlers do. If the hand mapping was a workaround for the renamed fields, fixing Findings 1–2 removes the need for it.

---

## What Looks Good

- **Routes:** `/webhooks` and `/webhooks/{webhook_id}` match the plural-collection, `{<noun>_id}` pattern and sit under the `/v1` prefix.
- **Names:** `create_webhook`, `get_webhook`, `WebhookCreate` and `Webhook` follow the existing verb and model-naming conventions.
- **Server-generated fields:** `id: str` and `created_at: datetime` match both sibling read models exactly in name and type.
- **Status codes:** `POST` returns `201` with `response_model=Webhook`, the same as the other creates.
- **Auth:** both handlers use `Depends(current_account)` and scope store calls by `account.id`.
- **Versioning:** this adds endpoints and changes no existing ones, so it is backward-compatible and needs no version bump. No existing consumer is affected.
- **Idempotency:** non-idempotent `POST` creates with no idempotency key, the same as the existing creates. That's consistent, though no resource here has retry-safe creates.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | URL field is `target_url` in the request but `url` in the response | Inconsistent | `subject.py:62,68` | High |
| 2 | Events field is `event_types` in the request but `events` in the response | Inconsistent | `subject.py:63,69` | High |
| 3 | Event subscription field doesn't follow the existing `notify_on` name | Minor | `subject.py:63,69` | Medium |
| 4 | `HttpUrl` normalization may change the URL between request and response | Informational | `subject.py:62,68,75` | Low |
| 5 | `create_webhook` builds its response by hand, unlike sibling handlers | Informational | `subject.py:75-76` | Medium |

---

## Overall Assessment

The resource's structure follows the established conventions: routes, handler names, model names, server-generated fields, status codes, auth and versioning all match. The problem is in the payload fields. The new resource is the only one whose create and read models use different names for the same data, and it is mismatched on both writable fields (`target_url`/`url`, `event_types`/`events`). It also doesn't reuse the existing integration's `notify_on` name. None of this breaks existing consumers, because these are new endpoints. But it is a contract that becomes a breaking change to fix once clients adopt it. All of it can be fixed in place before merge by renaming the request fields to match the response (and ideally `notify_on`), then dropping the hand-built response in `create_webhook`.
