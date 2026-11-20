# Notifications service — new feature package, concatenated into one file for review.
#
# Architecture: ports and adapters.
#   notify/domain/          entities and business rules
#   notify/application/     use cases and the ports they depend on
#   notify/infrastructure/  adapters for external systems
#   notify/main.py          composition root
#
# Each "# ---- file: <path> ----" marker starts a separate module.


# ---- file: notify/domain/reminder.py ----
from dataclasses import dataclass
from datetime import datetime, timedelta


@dataclass(frozen=True)
class Reminder:
    id: int
    recipient: str
    subject: str
    due_at: datetime  # timezone-aware, UTC

    def __post_init__(self) -> None:
        if self.due_at.utcoffset() != timedelta(0):
            raise ValueError("due_at must be a timezone-aware UTC datetime")

    def is_due(self, now: datetime, lead: timedelta) -> bool:
        return now >= self.due_at - lead


# ---- file: notify/application/ports.py ----
from datetime import datetime
from typing import Iterable, Protocol

from notify.domain.reminder import Reminder


class ReminderStore(Protocol):
    """Reminders not yet sent. Delivery is at-least-once: a crash between
    Sender.send and mark_sent sends that reminder again on the next run."""

    def pending(self, before: datetime) -> Iterable[Reminder]: ...

    def mark_sent(self, reminder_id: int) -> None: ...


class Sender(Protocol):
    def send(self, recipient: str, subject: str, body: str) -> None: ...


class Clock(Protocol):
    def now(self) -> datetime:
        """The current time, timezone-aware, in UTC."""
        ...


# ---- file: notify/application/send_due_reminders.py ----
from datetime import timedelta

from notify.application.ports import Clock, ReminderStore, Sender


class SendDueReminders:
    def __init__(self, store: ReminderStore, sender: Sender, clock: Clock,
                 lead: timedelta = timedelta(hours=1)) -> None:
        self._store = store
        self._sender = sender
        self._clock = clock
        self._lead = lead

    def __call__(self) -> int:
        now = self._clock.now()
        sent = 0
        for reminder in self._store.pending(before=now + self._lead):
            if reminder.is_due(now, self._lead):
                self._sender.send(reminder.recipient, reminder.subject,
                                  f"Reminder: {reminder.subject} at {reminder.due_at:%H:%M} UTC")
                self._store.mark_sent(reminder.id)
                sent += 1
        return sent


# ---- file: notify/infrastructure/smtp_sender.py ----
import smtplib
from email.message import EmailMessage


class SmtpSender:
    def __init__(self, host: str, from_addr: str) -> None:
        self._host = host
        self._from = from_addr

    def send(self, recipient: str, subject: str, body: str) -> None:
        msg = EmailMessage()
        msg["To"], msg["From"], msg["Subject"] = recipient, self._from, subject
        msg.set_content(body)
        with smtplib.SMTP(self._host) as smtp:
            smtp.send_message(msg)


# ---- file: notify/infrastructure/sql_reminders.py ----
import sqlite3
from datetime import datetime, timezone
from typing import Iterator

from notify.domain.reminder import Reminder


class SqlReminderStore:
    """due_at is stored as UTC ISO-8601 text with a +00:00 offset, so text
    order is time order."""

    def __init__(self, conn: sqlite3.Connection) -> None:
        self._conn = conn

    def pending(self, before: datetime) -> Iterator[Reminder]:
        rows = self._conn.execute(
            "SELECT id, recipient, subject, due_at FROM reminders WHERE sent = 0 AND due_at < ?",
            (before.astimezone(timezone.utc).isoformat(),),
        ).fetchall()
        for reminder_id, recipient, subject, due_at in rows:
            yield Reminder(reminder_id, recipient, subject, datetime.fromisoformat(due_at))

    def mark_sent(self, reminder_id: int) -> None:
        with self._conn:
            self._conn.execute("UPDATE reminders SET sent = 1 WHERE id = ?", (reminder_id,))


# ---- file: notify/infrastructure/system_clock.py ----
from datetime import datetime, timezone


class SystemClock:
    def now(self) -> datetime:
        return datetime.now(timezone.utc)


# ---- file: notify/main.py ----
import os
import sqlite3

from notify.application.send_due_reminders import SendDueReminders
from notify.infrastructure.smtp_sender import SmtpSender
from notify.infrastructure.sql_reminders import SqlReminderStore
from notify.infrastructure.system_clock import SystemClock


def build() -> SendDueReminders:
    conn = sqlite3.connect(os.environ["NOTIFY_DB"])
    return SendDueReminders(
        store=SqlReminderStore(conn),
        sender=SmtpSender(os.environ["SMTP_HOST"], "reminders@example.org"),
        clock=SystemClock(),
    )


if __name__ == "__main__":
    print(build()())
