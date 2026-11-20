# API Consistency Review: `subject.py` (refund endpoint)

> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

**Scope:** `subject.py`. The diff is lines 57–68 (`BEGIN`/`END CHANGE UNDER REVIEW`). The rest of the file is the baseline.
**Date:** 2026-11-19
**Note:** `subject.py` is the only file in the repository. `billing.models` (`Invoice.refund`, `Refund.to_dict`) and `billing.auth` aren't available, so anything about refund model behavior is inferred from the call site only.

---

## Baseline Conventions

These come from the four existing handlers (`get_subscription`, `cancel_subscription`, `get_invoice`, `create_payment_method`):

- **Routing:** everything lives under the `/v1` blueprint prefix. Collections are plural snake_case nouns (`/subscriptions`, `/invoices`, `/payment_methods`). State-changing actions are `POST /<collection>/<id>/<verb>` (`/subscriptions/<sub_id>/cancel`).
- **Handler names:** `verb_noun` in snake_case (`get_invoice`, `cancel_subscription`, `create_payment_method`).
- **Path params:** `<noun>_id` (`invoice_id`, `sub_id`).
- **Tenancy/auth:** every lookup is scoped through `Model.find(current_account().id, id)`.
- **Error envelope:** every error goes through `error_response()` (lines 11–15), which produces `{"error": {"code": <snake_case code>, "message": <str>, "details"?: {...}}}`.
- **Error codes and statuses:**
  - Not found → **404** with code `<resource>_not_found` (`subscription_not_found`, `invoice_not_found`).
  - Request in the wrong state (conflict) → **409** with code `<resource>_<state_problem>` (`subscription_already_canceled`).
  - Bad input → **422** with code `validation_failed` and a structured `details` object (`{"missing": [...]}`).
- **Success bodies:** the bare resource dict (`x.to_dict()`), with no `success` flag. **201** on create, **200** otherwise.
- **Input parsing:** `request.get_json(silent=True) or {}`, then explicit validation before the model is touched.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `POST /invoices/<invoice_id>/refund` | route | `POST /subscriptions/<sub_id>/cancel`, `GET /invoices/<invoice_id>` | `subject.py:26`, `subject.py:37` | Consistent: plural collection + id + action verb |
| `refund_invoice` | function | `cancel_subscription`, `get_invoice`, `create_payment_method` | `subject.py:27,38,46` | Consistent: `verb_noun` |
| `invoice_id` | path param | `invoice_id` (`get_invoice`), `sub_id` | `subject.py:37` | Consistent: same name as the sibling invoice route |
| `amount` | request body field | `type`, `token` (the only other body fields; no monetary fields exist) | `subject.py:48` | New category: units, type and "absent" semantics are being set here (see Finding 5) |
| `success` | error response field | `error` (top-level envelope key) | `subject.py:12` | Inconsistent: no existing response has a `success` flag |
| `error_message` | error response field | `error.message`, `error.code`, `error.details` | `subject.py:12-14` | Inconsistent: existing message lives at `error.message` |
| *(no error code emitted)* for not found | error code | `invoice_not_found`, `subscription_not_found` | `subject.py:22,30,41` | Inconsistent: should reuse the existing code `invoice_not_found` |
| *(no error code emitted)* for invoice not paid | error code | `subscription_already_canceled` | `subject.py:32` | Inconsistent: the existing pattern is `<resource>_<state_problem>`, e.g. `invoice_not_refundable` |

---

## Findings

#### 1. Error responses skip `error_response()` and use a different envelope

**Severity:** Inconsistent
**Location:** `subject.py:62`, `subject.py:64`
**Move:** #4 Error consistency (and #2/#7 for the field names)
**Confidence:** High

Precedent: `{"error": {"code", "message"}}` built by `error_response()` used in `subject.py:11-15,22,30,32,41,50-52`

Every existing handler returns errors as `{"error": {"code": ..., "message": ...}}` through the shared `error_response()` helper. The refund handler builds its own errors by hand as `{"success": false, "error_message": "..."}`. A client that reads `body["error"]["code"]` will get a `KeyError` or `undefined` from this one endpoint, so consumers would need special-case parsing for refunds. Because the helper is bypassed, the envelope can also drift further later.

**Recommendation:** Replace both `jsonify(...)` error returns with `error_response(...)` calls. Drop the `success` and `error_message` keys.

#### 2. Not-found error doesn't reuse the existing `invoice_not_found` code

**Severity:** Inconsistent
**Location:** `subject.py:61-62`
**Move:** #4 Error consistency
**Confidence:** High

Precedent: `invoice_not_found` / `"No invoice with that id"` used in `subject.py:41`

The same condition (calling `Invoice.find` for the current account and getting `None`) already has a canonical error: `404 invoice_not_found` from `GET /invoices/<invoice_id>`. The new endpoint returns 404 with no machine-readable code and a different message (`"Invoice not found"`). Clients that branch on `invoice_not_found` won't recognize this endpoint's error.

**Recommendation:** `return error_response(404, "invoice_not_found", "No invoice with that id")`.

#### 3. Invoice in the wrong state returns 400 with no code; the existing pattern is 409 with a coded error

**Severity:** Inconsistent
**Location:** `subject.py:63-64`
**Move:** #4 Error consistency
**Confidence:** High

Precedent: `409 subscription_already_canceled` for an action rejected because of resource state, used in `subject.py:31-32`

Rejecting a refund because the invoice isn't `paid` is the same kind of error as rejecting a cancel because the subscription is already `canceled`. The codebase answers that with **409** and a `<resource>_<state_problem>` code. The new handler uses **400**, which no other handler in the file returns, and gives no code. Clients can't tell "invoice is in the wrong state" apart from other 400s, and the meaning of 4xx statuses becomes inconsistent across the API.

**Recommendation:** `return error_response(409, "invoice_not_refundable", "Only paid invoices can be refunded")`. Name the code after the domain; `invoice_not_paid` would also fit the pattern.

#### 4. `amount` isn't validated; the existing pattern is 422 `validation_failed`

**Severity:** Inconsistent
**Location:** `subject.py:65-66`
**Move:** #4 Error consistency / #8 Nullability
**Confidence:** Medium (depends on `Invoice.refund`, which isn't visible)

`create_payment_method` checks its body before calling the model and returns `422 validation_failed` with structured `details`. The refund handler passes `payload.get("amount")` straight to `invoice.refund()`. A string, a negative number, zero, or an amount above the invoice total will either raise inside the model (an unstructured 500) or be handled in some way the API contract never states. Either way, the error doesn't match the `validation_failed` shape clients already handle.

**Recommendation:** Validate `amount` in the handler: type, > 0, and ≤ the refundable balance. On failure, return `error_response(422, "validation_failed", ..., {"invalid": ["amount"]})` or a similar `details` shape that sits alongside the existing `{"missing": [...]}`.

#### 5. `amount` field: units and the meaning of "omitted" aren't specified

**Severity:** Informational (downgraded from Minor because there's no precedent)
**Location:** `subject.py:66`
**Move:** #2 Naming / #8 Nullability
**Confidence:** Medium

No existing precedent in `subject.py` (all request body fields and `to_dict()` call sites; the repository contains no other source files).

This is the API's first monetary input, so it sets the convention. Nothing in the handler says whether `amount` is in minor units (cents, as an integer) or a decimal, or what currency applies. When `amount` is omitted, `None` is passed through, which presumably means a full refund, but that isn't documented. Later money fields (credits, adjustments, partial payments) will copy whatever is chosen here.

**Recommendation:** Decide deliberately, ideally integer minor units matching however `Invoice.to_dict()` represents totals. Document "omitted = full refundable balance" in a docstring or the API docs.

#### 6. Retrying the refund could double-refund

**Severity:** Minor
**Location:** `subject.py:58-67`
**Move:** #9 Idempotency and safety
**Confidence:** Medium (depends on whether `Invoice.refund` changes `status` away from `paid`)

The only guard is `invoice.status != "paid"`. If a partial refund leaves the invoice `paid`, a client retrying after a timeout will issue a second refund. `cancel_subscription` is effectively retry-safe, because a second call gets 409 `subscription_already_canceled` instead of a second side effect. For money movement, the risk of a duplicate is higher. The codebase has no idempotency-key mechanism yet (none found in `subject.py`).

**Recommendation:** At minimum, reject refunds that would exceed the refundable balance (409 with a coded error). Consider accepting an `Idempotency-Key` header. Since this would be the first such mechanism, name and document it deliberately so other write endpoints can adopt it.

#### 7. Action endpoint returns the child resource, not the parent

**Severity:** Informational
**Location:** `subject.py:67`
**Move:** #7 Asymmetry
**Confidence:** Medium

The one existing action endpoint, `POST /subscriptions/<id>/cancel`, returns the updated parent resource with 200. `POST /invoices/<id>/refund` returns a new Refund object with 201. That's defensible, since a refund is a new resource and 201 matches `create_payment_method`. But it creates a new sub-pattern ("actions that create a child return the child"), and there's no `GET` route to read a refund back. Consumers who want the invoice's updated status need a second call to `GET /invoices/<id>`.

**Recommendation:** Keep 201 + refund body if that's the intent, but record it as the convention. Consider adding a read path for refunds, e.g. `GET /invoices/<invoice_id>/refunds` or `GET /refunds/<refund_id>`, so create and read are symmetric.

---

## What Looks Good

- **Route shape** `POST /invoices/<invoice_id>/refund` matches the existing action route `/subscriptions/<sub_id>/cancel`.
- **Handler name** `refund_invoice` follows the `verb_noun` convention.
- **Path param** `invoice_id` is identical to the one in the sibling `GET /invoices/<invoice_id>`.
- **Tenancy scoping** uses `Invoice.find(current_account().id, invoice_id)`, matching every other handler, so there's no cross-account access issue.
- **Body parsing** uses `request.get_json(silent=True) or {}`, the same idiom as `create_payment_method`.
- **Versioning:** this is a new endpoint under `/v1` and nothing existing was changed, so it's backward-compatible and needs no version bump.
- **201 on creation** matches `create_payment_method`.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Error responses skip `error_response()`; `success` / `error_message` envelope | Inconsistent | `subject.py:62,64` | High |
| 2 | Not-found doesn't reuse the `invoice_not_found` code | Inconsistent | `subject.py:61-62` | High |
| 3 | Wrong-state error is 400 with no code; precedent is 409 + coded error | Inconsistent | `subject.py:63-64` | High |
| 4 | `amount` not validated; precedent is 422 `validation_failed` | Inconsistent | `subject.py:65-66` | Medium |
| 5 | `amount` units and meaning when omitted are unspecified (first money field) | Informational | `subject.py:66` | Medium |
| 6 | Retries can double-refund; no duplicate protection | Minor | `subject.py:58-67` | Medium |
| 7 | Action returns the child resource; no read path for refunds | Informational | `subject.py:67` | Medium |

---

## Overall Assessment

The endpoint's outward shape (route, handler name, path param, tenancy scoping, versioning) fits the codebase well. The problems are all in error handling. The handler ignores the shared `error_response()` helper and invents its own `{"success", "error_message"}` envelope. It drops the machine-readable codes every other endpoint provides, uses 400 where the codebase uses 409 for state conflicts, and skips the 422 `validation_failed` input check. For consumers, this is the only endpoint where `body.error.code` doesn't exist, which will break any shared error-handling code in clients or SDKs. All of it is fixable in place by routing the three error paths through `error_response()` with the codes suggested above. The idempotency and `amount`-units points matter more than usual because this is money movement, and because this endpoint will set the convention for future financial inputs.

I printed the report here and didn't save it to `docs/reviews/`.
