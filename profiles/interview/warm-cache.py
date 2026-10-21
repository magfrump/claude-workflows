"""warm-cache.py — fill the Hugging Face cache and exercise the GPU training path.

The interview task is unknown, so this can't download *the* model. It does
three useful things anyway:
  1. proves Hub downloads work from this machine (auth, proxy, disk);
  2. caches small models and datasets that research-coding tasks commonly use,
     so if one comes up the first run starts instantly;
  3. runs one real forward/backward/optimizer step on CUDA, so CUDA init,
     kernel loading and any driver problems surface now, not on the call.

Run with the interview venv: ~/interview-env/bin/python warm-cache.py
"""

import time

import torch
from datasets import load_dataset
from transformers import (
    AutoModelForCausalLM,
    AutoModelForSequenceClassification,
    AutoTokenizer,
)

MODELS = {
    "distilbert-base-uncased": AutoModelForSequenceClassification,
    "gpt2": AutoModelForCausalLM,
}
DATASETS = [("stanfordnlp/imdb", None), ("Salesforce/wikitext", "wikitext-2-raw-v1")]


def timed(label, fn):
    t = time.time()
    out = fn()
    print(f"  {label}: {time.time() - t:.1f}s")
    return out


def main():
    assert torch.cuda.is_available(), "CUDA not available to torch"
    device = torch.device("cuda")

    for name, path_config in DATASETS:
        timed(f"dataset {name}", lambda: load_dataset(name, path_config))

    for name, cls in MODELS.items():
        tok = timed(f"tokenizer {name}", lambda: AutoTokenizer.from_pretrained(name))
        model = timed(f"model {name}", lambda: cls.from_pretrained(name)).to(device)
        if tok.pad_token is None:
            tok.pad_token = tok.eos_token

        # One real training step, so the whole path (autograd, optimizer, CUDA
        # kernels) is exercised, not just a forward pass.
        batch = tok(["a warm-up sentence"] * 8, return_tensors="pt", padding=True).to(device)
        if cls is AutoModelForCausalLM:
            labels = batch["input_ids"]
        else:
            labels = torch.zeros(8, dtype=torch.long, device=device)
        opt = torch.optim.AdamW(model.parameters(), lr=1e-5)

        def step():
            loss = model(**batch, labels=labels).loss
            loss.backward()
            opt.step()
            torch.cuda.synchronize()
            return loss.item()

        loss = timed(f"train step {name}", step)
        print(f"    loss={loss:.3f}")
        del model, opt
        torch.cuda.empty_cache()

    print("warm-cache: OK")


if __name__ == "__main__":
    main()
