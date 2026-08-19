"""Shared identity constants for the CRB direction-1 arm.

Deliberately tiny. The 2026-08-18 review's tech-debt triage argued against
building a shared `crb_*` module for this arm — arms in this repo are single-use
as code, so a refactor's risk lands inside the sweep window while its benefit
lands in a maintenance phase that history says will not occur. That reasoning
holds for the arm's *logic* and is why no such module exists.

It does not hold for these four values. They are not a refactor: they are the
identity of the work dir the injector writes and the leaderboard reads, and a
review-fix pass hand-copied them into a second file, where they are held in
agreement by a comment. `sanitize_model` in particular must keep matching the
vendored `sanitize_model_name` on both sides or stage 4 reads a directory stage 3
never wrote — and that failure surfaces as "no evaluations, run step 3 first",
which misdiagnoses the cause.

So: one definition, imported by both. No behaviour lives here.
"""

from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
BENCH = WORKSPACE / "external/code-review-benchmark/offline"
BENCH_DATA = BENCH / "results/benchmark_data.json"
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"

DEFAULT_OUT = WORKSPACE / "runs/review-arms/crb/offline-work-50"
DEFAULT_JUDGE = "claude-opus-4-5-20251101"
DEFAULT_TOOL = "mfc-pipeline-e8"


def sanitize_model(model: str) -> str:
    """Model id -> results-directory name.

    Must stay byte-compatible with the vendored benchmark's own
    `sanitize_model_name`: the benchmark names the directory it writes, and we
    have to predict that name to seed it and to read it back.
    """
    return model.strip().replace("/", "_")
