"""FastAPI routes for account integrations."""

from datetime import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel, HttpUrl

from integrations.auth import Account, current_account
from integrations import store

router = APIRouter(prefix="/v1")


class ApiKeyCreate(BaseModel):
    label: str
    scopes: list[str]


class ApiKey(BaseModel):
    id: str
    label: str
    scopes: list[str]
    created_at: datetime


class SlackChannelCreate(BaseModel):
    channel_name: str
    notify_on: list[str]


class SlackChannel(BaseModel):
    id: str
    channel_name: str
    notify_on: list[str]
    created_at: datetime


@router.post("/api_keys", response_model=ApiKey, status_code=201)
def create_api_key(body: ApiKeyCreate, account: Account = Depends(current_account)):
    return store.api_keys.create(account.id, label=body.label, scopes=body.scopes)


@router.get("/api_keys/{key_id}", response_model=ApiKey)
def get_api_key(key_id: str, account: Account = Depends(current_account)):
    return store.api_keys.get(account.id, key_id)


@router.post("/slack_channels", response_model=SlackChannel, status_code=201)
def create_slack_channel(body: SlackChannelCreate, account: Account = Depends(current_account)):
    return store.slack_channels.create(
        account.id, channel_name=body.channel_name, notify_on=body.notify_on
    )


@router.get("/slack_channels/{channel_id}", response_model=SlackChannel)
def get_slack_channel(channel_id: str, account: Account = Depends(current_account)):
    return store.slack_channels.get(account.id, channel_id)


# BEGIN CHANGE UNDER REVIEW
class WebhookCreate(BaseModel):
    target_url: HttpUrl
    event_types: list[str]


class Webhook(BaseModel):
    id: str
    url: HttpUrl
    events: list[str]
    created_at: datetime


@router.post("/webhooks", response_model=Webhook, status_code=201)
def create_webhook(body: WebhookCreate, account: Account = Depends(current_account)):
    row = store.webhooks.create(account.id, url=str(body.target_url), events=body.event_types)
    return Webhook(id=row.id, url=row.url, events=row.events, created_at=row.created_at)


@router.get("/webhooks/{webhook_id}", response_model=Webhook)
def get_webhook(webhook_id: str, account: Account = Depends(current_account)):
    return store.webhooks.get(account.id, webhook_id)
# END CHANGE UNDER REVIEW
