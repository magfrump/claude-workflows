"""HTTP handlers for the billing service."""

from flask import Blueprint, jsonify, request

from billing.auth import current_account
from billing.models import Invoice, PaymentMethod, Subscription

bp = Blueprint("billing", __name__, url_prefix="/v1")


def error_response(status, code, message, details=None):
    body = {"error": {"code": code, "message": message}}
    if details:
        body["error"]["details"] = details
    return jsonify(body), status


@bp.get("/subscriptions/<sub_id>")
def get_subscription(sub_id):
    sub = Subscription.find(current_account().id, sub_id)
    if sub is None:
        return error_response(404, "subscription_not_found", "No subscription with that id")
    return jsonify(sub.to_dict())


@bp.post("/subscriptions/<sub_id>/cancel")
def cancel_subscription(sub_id):
    sub = Subscription.find(current_account().id, sub_id)
    if sub is None:
        return error_response(404, "subscription_not_found", "No subscription with that id")
    if sub.status == "canceled":
        return error_response(409, "subscription_already_canceled", "Subscription is already canceled")
    sub.cancel()
    return jsonify(sub.to_dict())


@bp.get("/invoices/<invoice_id>")
def get_invoice(invoice_id):
    invoice = Invoice.find(current_account().id, invoice_id)
    if invoice is None:
        return error_response(404, "invoice_not_found", "No invoice with that id")
    return jsonify(invoice.to_dict())


@bp.post("/payment_methods")
def create_payment_method():
    payload = request.get_json(silent=True) or {}
    missing = [f for f in ("type", "token") if f not in payload]
    if missing:
        return error_response(
            422, "validation_failed", "Missing required fields", {"missing": missing}
        )
    pm = PaymentMethod.create(current_account().id, payload["type"], payload["token"])
    return jsonify(pm.to_dict()), 201


# BEGIN CHANGE UNDER REVIEW
@bp.post("/invoices/<invoice_id>/refund")
def refund_invoice(invoice_id):
    invoice = Invoice.find(current_account().id, invoice_id)
    if invoice is None:
        return jsonify({"success": False, "error_message": "Invoice not found"}), 404
    if invoice.status != "paid":
        return jsonify({"success": False, "error_message": "Only paid invoices can be refunded"}), 400
    payload = request.get_json(silent=True) or {}
    refund = invoice.refund(amount=payload.get("amount"))
    return jsonify(refund.to_dict()), 201
# END CHANGE UNDER REVIEW
