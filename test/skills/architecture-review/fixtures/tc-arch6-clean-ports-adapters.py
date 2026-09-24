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
    recipient: str
    subject: str
    due_at: datetime

    def is_due(self, now: datetime, lead: timedelta) -> bool:
        return now >= self.due_at - lead


# ---- file: notify/application/ports.py ----
from datetime import datetime
from typing import Iterable, Protocol

from notify.domain.reminder import Reminder


class ReminderSource(Protocol):
    def pending(self, before: datetime) -> Iterable[Reminder]: ...


class Sender(Protocol):
    def send(self, recipient: str, subject: str, body: str) -> None: ...


class Clock(Protocol):
    def now(self) -> datetime: ...


# ---- file: notify/application/send_due_reminders.py ----
from datetime import timedelta

from notify.application.ports import Clock, ReminderSource, Sender


class SendDueReminders:
    def __init__(self, source: ReminderSource, sender: Sender, clock: Clock,
                 lead: timedelta = timedelta(hours=1)) -> None:
        self._source = source
        self._sender = sender
        self._clock = clock
        self._lead = lead

    def __call__(self) -> int:
        now = self._clock.now()
        sent = 0
        for reminder in self._source.pending(before=now + self._lead):
            if reminder.is_due(now, self._lead):
                self._sender.send(reminder.recipient, reminder.subject,
                                  f"Reminder: {reminder.subject} at {reminder.due_at:%H:%M}")
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
from datetime import datetime
from typing import Iterator

from notify.domain.reminder import Reminder


class SqlReminderSource:
    def __init__(self, conn: sqlite3.Connection) -> None:
        self._conn = conn

    def pending(self, before: datetime) -> Iterator[Reminder]:
        rows = self._conn.execute(
            "SELECT recipient, subject, due_at FROM reminders WHERE sent = 0 AND due_at < ?",
            (before.isoformat(),),
        )
        for recipient, subject, due_at in rows:
            yield Reminder(recipient, subject, datetime.fromisoformat(due_at))


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
from notify.infrastructure.sql_reminders import SqlReminderSource
from notify.infrastructure.system_clock import SystemClock


def build() -> SendDueReminders:
    conn = sqlite3.connect(os.environ["NOTIFY_DB"])
    return SendDueReminders(
        source=SqlReminderSource(conn),
        sender=SmtpSender(os.environ["SMTP_HOST"], "reminders@example.org"),
        clock=SystemClock(),
    )


if __name__ == "__main__":
    print(build()())
