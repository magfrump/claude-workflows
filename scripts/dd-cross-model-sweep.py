#!/usr/bin/env python3
"""One-shot divergent-design sweep: same prompt to N OpenRouter models, save raw markdown.

This is a post-hoc reconstruction of the runner that produced
runs/dd-cross-model-2026-07-30/ (the original lived in job tmp; behavioral
equivalence to the *.meta.json outputs is verified, identity is not). No spend
guard: archival one-shot, max_tokens 48000 x 3 models. (The fourth arm,
local Fable, ran as a Claude Code subagent given the same prompt file — no script).
Committed per tech-debt finding C20 of the 2026-07-30 review: the sweep README's
results table was hand-transcribed from the *.meta.json files this script writes,
and hand transcription is where both of that README's data errors came from. Future
sweeps: generate the table from the meta.json files instead.

Usage:
  export OPENROUTER_API_KEY=sk-or-...
  scripts/dd-cross-model-sweep.py <prompt-file> <out-dir>

Distinct from scripts/cross-model-review.py (the code-review sweep harness with
replicates/Jaccard analysis): this one sends a single free-form prompt once per
model and saves raw markdown + usage metadata, nothing more.
"""
import json, os, sys, time, urllib.request

API = "https://openrouter.ai/api/v1/chat/completions"
KEY = os.environ.get("OPENROUTER_API_KEY") or sys.exit("OPENROUTER_API_KEY not set")
if len(sys.argv) < 3:
    sys.exit("usage: dd-cross-model-sweep.py <prompt-file> <out-dir>")
PROMPT_PATH = sys.argv[1]
OUT_DIR = sys.argv[2]
MODELS = ["moonshotai/kimi-k3", "openai/gpt-5.6-sol", "google/gemini-3.1-pro-preview"]

prompt = open(PROMPT_PATH).read()
os.makedirs(OUT_DIR, exist_ok=True)

def call(model):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        # kimi-k3 spends budget inside the reasoning trace and returns content:null
        # if max_tokens is too low (see scripts/cross-model-review.py) — be generous.
        "max_tokens": 48000,
    }
    req = urllib.request.Request(API, data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json",
                 "X-Title": "dd-cross-model sweep"})
    with urllib.request.urlopen(req, timeout=1800) as r:
        return json.load(r)

for model in MODELS:
    slug = model.replace("/", "_")
    ok = False
    for attempt in (1, 2):
        try:
            t0 = time.time()
            resp = call(model)
            msg = resp["choices"][0]["message"]
            content = msg.get("content")
            finish = resp["choices"][0].get("finish_reason")
            usage = resp.get("usage", {})
            if not content:
                print(f"{model} attempt {attempt}: EMPTY content (finish={finish}, usage={usage})", flush=True)
                continue
            with open(f"{OUT_DIR}/{slug}.md", "w") as f:
                f.write(content)
            meta = {"model": model, "finish_reason": finish, "usage": usage,
                    "latency_s": round(time.time() - t0, 1), "attempt": attempt}
            with open(f"{OUT_DIR}/{slug}.meta.json", "w") as f:
                json.dump(meta, f, indent=2)
            print(f"{model}: OK {len(content)} chars, {meta['latency_s']}s, usage={usage}", flush=True)
            ok = True
            break
        except Exception as e:
            print(f"{model} attempt {attempt}: ERROR {type(e).__name__}: {e}", flush=True)
            time.sleep(5)
    if not ok:
        print(f"{model}: FAILED after 2 attempts", flush=True)
