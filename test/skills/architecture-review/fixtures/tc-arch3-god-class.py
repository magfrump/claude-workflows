# Membership platform — application layer, new module under review.
#
# Architecture: layered.
#   members/domain/          entities and business rules
#   members/application/     use-case services called by the web and worker entry points
#   members/infrastructure/  adapters (database, mail, payments, file storage)
#
# This file is members/application/account_service.py.

import csv
import hashlib
import io
import json
import logging
import os
import secrets
import smtplib
import sqlite3
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage

import stripe
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

log = logging.getLogger(__name__)


class AccountService:
    def __init__(self, db_path: str) -> None:
        self.db = sqlite3.connect(db_path)
        self.smtp_host = os.environ["SMTP_HOST"]
        stripe.api_key = os.environ["STRIPE_KEY"]
        self.flags = json.loads(os.environ.get("FEATURE_FLAGS", "{}"))

    # -- registration and login --------------------------------------------
    def register(self, email: str, password: str) -> int:
        salt = secrets.token_hex(16)
        digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 200_000)
        cur = self.db.execute(
            "INSERT INTO members (email, salt, pw_hash, created_at) VALUES (?, ?, ?, ?)",
            (email, salt, digest.hex(), datetime.now(timezone.utc).isoformat()),
        )
        self.db.commit()
        self.send_welcome_email(email)
        self.audit("register", cur.lastrowid)
        return cur.lastrowid

    def login(self, email: str, password: str) -> str | None:
        row = self.db.execute(
            "SELECT id, salt, pw_hash FROM members WHERE email = ?", (email,)
        ).fetchone()
        if not row:
            return None
        digest = hashlib.pbkdf2_hmac("sha256", password.encode(), row[1].encode(), 200_000)
        if digest.hex() != row[2]:
            return None
        token = secrets.token_urlsafe(32)
        expires = datetime.now(timezone.utc) + timedelta(hours=12)
        self.db.execute(
            "INSERT INTO sessions (token, member_id, expires_at) VALUES (?, ?, ?)",
            (token, row[0], expires.isoformat()),
        )
        self.db.commit()
        return token

    # -- email -------------------------------------------------------------
    def send_welcome_email(self, email: str) -> None:
        msg = EmailMessage()
        msg["To"], msg["From"], msg["Subject"] = email, "hello@example.org", "Welcome!"
        msg.set_content("Thanks for joining.")
        with smtplib.SMTP(self.smtp_host) as s:
            s.send_message(msg)

    def send_renewal_reminders(self) -> int:
        soon = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
        rows = self.db.execute(
            "SELECT email FROM members WHERE renews_at < ?", (soon,)
        ).fetchall()
        with smtplib.SMTP(self.smtp_host) as s:
            for (email,) in rows:
                msg = EmailMessage()
                msg["To"], msg["From"], msg["Subject"] = email, "hello@example.org", "Renewal"
                msg.set_content("Your membership renews next week.")
                s.send_message(msg)
        return len(rows)

    # -- billing -----------------------------------------------------------
    def charge_membership(self, member_id: int, plan: str) -> str:
        price = {"basic": 900, "plus": 1900}[plan]
        if self.flags.get("spring_promo"):
            price = int(price * 0.8)
        customer = self.db.execute(
            "SELECT stripe_customer FROM members WHERE id = ?", (member_id,)
        ).fetchone()[0]
        intent = stripe.PaymentIntent.create(amount=price, currency="usd", customer=customer)
        self.db.execute(
            "UPDATE members SET plan = ?, renews_at = ? WHERE id = ?",
            (plan, (datetime.now(timezone.utc) + timedelta(days=365)).isoformat(), member_id),
        )
        self.db.commit()
        self.audit("charge", member_id)
        return intent.id

    def refund(self, payment_intent_id: str) -> None:
        stripe.Refund.create(payment_intent=payment_intent_id)

    # -- documents and reports ---------------------------------------------
    def render_receipt_pdf(self, member_id: int, amount_cents: int) -> bytes:
        buf = io.BytesIO()
        c = canvas.Canvas(buf, pagesize=A4)
        c.drawString(72, 800, f"Receipt for member {member_id}")
        c.drawString(72, 780, f"Amount: ${amount_cents / 100:.2f}")
        c.save()
        return buf.getvalue()

    def export_members_csv(self) -> str:
        out = io.StringIO()
        writer = csv.writer(out)
        writer.writerow(["id", "email", "plan", "renews_at"])
        writer.writerows(self.db.execute("SELECT id, email, plan, renews_at FROM members"))
        return out.getvalue()

    def monthly_signup_stats(self) -> dict[str, int]:
        rows = self.db.execute(
            "SELECT substr(created_at, 1, 7), count(*) FROM members GROUP BY 1"
        ).fetchall()
        return dict(rows)

    # -- administration ----------------------------------------------------
    def is_enabled(self, flag: str) -> bool:
        return bool(self.flags.get(flag))

    def purge_expired_sessions(self) -> None:
        self.db.execute(
            "DELETE FROM sessions WHERE expires_at < ?",
            (datetime.now(timezone.utc).isoformat(),),
        )
        self.db.commit()

    def audit(self, action: str, member_id: int | None) -> None:
        with open("/var/log/members/audit.log", "a") as f:
            f.write(f"{datetime.now(timezone.utc).isoformat()} {action} {member_id}\n")
        log.info("audit %s %s", action, member_id)
