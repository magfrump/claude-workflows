"""Live `openai`-package shim backed by any OpenAI-compatible endpoint, stdlib-only.

The sandbox can reach openrouter.ai but not pypi, so the real `openai` package
can't be installed; the benchmark steps only use
AsyncOpenAI(api_key, base_url).chat.completions.create(...) -> choices[0].message.content,
which this implements with urllib. Blocking HTTP runs in asyncio.to_thread so
the pipeline's asyncio.gather batching still gets real concurrency.

Usage (from runs/review-arms/crb/offline-work):
  export PYTHONPATH=../shims-live:../shims:/workspace/external/code-review-benchmark/offline
  (shims-live first so this beats the dry-run stub; tqdm still comes from ../shims)
"""

import asyncio
import json
import urllib.error
import urllib.request


class _Message:
    def __init__(self, content: str):
        self.content = content


class _Choice:
    def __init__(self, content: str):
        self.message = _Message(content)


class _Response:
    def __init__(self, content: str):
        self.choices = [_Choice(content)]


class _Completions:
    def __init__(self, api_key: str, base_url: str):
        self._api_key = api_key
        self._base_url = (base_url or "https://api.openai.com/v1").rstrip("/")

    def _post(self, payload: dict) -> str:
        req = urllib.request.Request(
            f"{self._base_url}/chat/completions",
            data=json.dumps(payload).encode(),
            headers={
                "Authorization": f"Bearer {self._api_key}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                data = json.load(resp)
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")[:500]
            raise RuntimeError(f"HTTP {e.code} from {self._base_url}: {body}") from e
        if "choices" not in data:
            raise RuntimeError(f"no choices in response: {json.dumps(data)[:500]}")
        return data["choices"][0]["message"]["content"] or ""

    async def create(self, model=None, messages=None, **kwargs):
        payload = {"model": model, "messages": messages}
        for k in ("temperature", "max_tokens", "response_format"):
            if k in kwargs:
                payload[k] = kwargs[k]
        content = await asyncio.to_thread(self._post, payload)
        return _Response(content)


class _Chat:
    def __init__(self, api_key: str, base_url: str):
        self.completions = _Completions(api_key, base_url)


class AsyncOpenAI:
    def __init__(self, api_key=None, base_url=None, **kwargs):
        self.chat = _Chat(api_key, base_url)


class OpenAI(AsyncOpenAI):
    pass
