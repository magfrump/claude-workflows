from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.auth import current_org
from app.db import get_session

router = APIRouter()


@router.get("/orgs/me/audit-events")
def list_audit_events(
    event_type: str | None = None,
    org=Depends(current_org),
    db: Session = Depends(get_session),
):
    """Audit trail for the org settings page. Every API call, login and
    permission change an org's members make is recorded as an audit event."""
    sql = """
        SELECT id, actor_id, event_type, target, ip_address, created_at
        FROM audit_events
        WHERE org_id = :org_id
    """
    params = {"org_id": org.id}
    if event_type:
        sql += " AND event_type = :event_type"
        params["event_type"] = event_type
    sql += " ORDER BY created_at DESC"

    rows = db.execute(text(sql), params).mappings().all()
    return {
        "org_id": org.id,
        "count": len(rows),
        "events": [dict(r) for r in rows],
    }
