"""Offline shim for the `openai` package — deterministic dry-run LLM.

Lets the Code Review Bench offline pipeline (steps 2 / 2.5 / 3) run end to end
with no network and no installed dependencies, so the data-format plumbing can
be validated before spending money on a real judge model. Responses:

  - extract prompt  -> one issue per comment block (first line of each block)
  - dedup prompt    -> all singletons (no duplicates claimed)
  - judge prompt    -> match iff golden and candidate share >= 4 distinct
                       words of length >= 6 (crude, deterministic; NOT a
                       substitute for a real judge)
"""

import json
import re


class _Message:
    def __init__(self, content: str):
        self.content = content


class _Choice:
    def __init__(self, content: str):
        self.message = _Message(content)


class _Response:
    def __init__(self, content: str):
        self.choices = [_Choice(content)]


def _extract_between(text: str, start: str, end: str) -> str:
    i = text.find(start)
    if i == -1:
        return ""
    j = text.find(end, i + len(start))
    return text[i + len(start):j] if j != -1 else text[i + len(start):]


def _answer(prompt: str) -> str:
    if '{{"issues"' in prompt or '"issues":' in prompt and "extract" in prompt.lower():
        body = _extract_between(prompt, "Code Review Comment:\n", "\nInstructions:")
        issues = []
        for block in body.split("\n\n---\n\n"):
            first = next((ln.strip().strip("*").strip() for ln in block.splitlines() if ln.strip()), None)
            if first:
                issues.append(first[:200])
        return json.dumps({"issues": issues})

    if '"groups"' in prompt:
        block = _extract_between(prompt, "Candidates:\n", "\nReturn ONLY")
        n = len(re.findall(r"(?m)^\d+\.", block))
        return json.dumps({"groups": [[i] for i in range(n)]})

    if '"match"' in prompt:
        golden = _extract_between(prompt, "Golden Comment (the issue we're looking for):\n",
                                  "\nCandidate Issue")
        cand = _extract_between(prompt, "Candidate Issue (from the tool's review):\n",
                                "\nInstructions:")
        words = lambda s: {w for w in re.findall(r"[a-zA-Z_]{6,}", s.lower())}  # noqa: E731
        shared = words(golden) & words(cand)
        match = len(shared) >= 4
        return json.dumps({
            "reasoning": f"stub word-overlap heuristic; shared={sorted(shared)[:6]}",
            "match": match,
            "confidence": 0.5,
        })

    return json.dumps({"error": "stub: unrecognized prompt"})


class _Completions:
    async def create(self, model=None, messages=None, **kwargs):
        prompt = messages[-1]["content"] if messages else ""
        return _Response(_answer(prompt))


class _Chat:
    def __init__(self):
        self.completions = _Completions()


class AsyncOpenAI:
    def __init__(self, api_key=None, base_url=None, **kwargs):
        self.chat = _Chat()


class OpenAI(AsyncOpenAI):
    pass
