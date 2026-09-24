# Checkout service — payment port, use case, and adapter, concatenated into one
# file for review.
#
# Architecture: ports and adapters.
#   checkout/application/     use cases and the ports they depend on
#   checkout/infrastructure/  adapters for external providers
#
# Each "# ---- file: <path> ----" marker starts a separate module.


# ---- file: checkout/application/ports.py ----
from abc import ABC, abstractmethod

import stripe


class PaymentGateway(ABC):
    @abstractmethod
    def charge(
        self, amount_cents: int, currency: str, payment_method: str
    ) -> stripe.PaymentIntent: ...

    @abstractmethod
    def refund(self, intent: stripe.PaymentIntent) -> stripe.Refund: ...


# ---- file: checkout/application/place_order.py ----
from dataclasses import dataclass

import stripe

from checkout.application.ports import PaymentGateway


@dataclass
class CheckoutResult:
    ok: bool
    payment_ref: str | None = None
    decline_reason: str | None = None
    needs_review: bool = False


class PlaceOrder:
    def __init__(self, payments: PaymentGateway) -> None:
        self._payments = payments

    def __call__(self, amount_cents: int, payment_method: str) -> CheckoutResult:
        try:
            intent = self._payments.charge(amount_cents, "usd", payment_method)
        except stripe.error.CardError as e:
            return CheckoutResult(ok=False, decline_reason=e.user_message)

        if intent.status == "requires_action":
            return CheckoutResult(ok=False, decline_reason="authentication_required")

        charge = intent.latest_charge
        risky = charge.outcome.risk_level == "elevated"
        return CheckoutResult(ok=True, payment_ref=intent.id, needs_review=risky)


# ---- file: checkout/infrastructure/stripe_gateway.py ----
import stripe

from checkout.application.ports import PaymentGateway


class StripeGateway(PaymentGateway):
    def __init__(self, api_key: str) -> None:
        self._client = stripe.StripeClient(api_key)

    def charge(
        self, amount_cents: int, currency: str, payment_method: str
    ) -> stripe.PaymentIntent:
        return self._client.payment_intents.create(
            params={
                "amount": amount_cents,
                "currency": currency,
                "payment_method": payment_method,
                "confirm": True,
                "expand": ["latest_charge"],
            }
        )

    def refund(self, intent: stripe.PaymentIntent) -> stripe.Refund:
        return self._client.refunds.create(params={"payment_intent": intent.id})
