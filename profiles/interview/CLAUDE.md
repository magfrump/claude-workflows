# Interview session

This is a live, timed pairing session: **25 minutes** to finish a research
coding task (Python, `torch` / `transformers` / `datasets`), followed by a
discussion of the results. The user is at the keyboard, sharing their screen,
and narrating to an interviewer. Optimize for getting a correct, defensible
result fast. Nothing here needs to outlive the session.

## How to work

- **Brief plan, then go.** Open with a plan of three bullets or fewer, then
  start immediately. Don't wait for approval. The user will interrupt if
  they disagree.
- **Report after each step** in 1–3 lines: what you did, what you saw, what's
  next. The user reads these aloud, so keep them plain and specific.
- **Surface anything important right away**: a surprising number, a
  suspected bug, a shortcut you took, an assumption about the task. Say it as
  soon as you notice it, not at the end.
- **Ask only when blocked** on something only the user knows (task
  ambiguity that changes the result). Otherwise make the reasonable call and
  state it.
- No subagents, no planning docs, no git commits unless asked. One agent,
  working in the open.

## Time discipline

- **Smoke test first.** Run every script on a tiny slice first (e.g. 64
  examples, 1–2 steps) to catch errors in seconds, then scale.
- **Budget runs before starting them.** Estimate the wall-clock time from the
  smoke test and say it. Default ceiling: about 5 minutes per run. Ask before
  launching anything longer.
- **Background anything over ~30 seconds** (`run_in_background`, output
  `tee`'d to `logs/<name>.log`), and keep working while it runs: write the
  eval or the analysis next.
- Use the GPU (`device = "cuda"`) and reasonable batch sizes. Prefer small
  models (`distilbert`, `gpt2`, a ~100M-parameter model) unless the task says
  otherwise.

## Research hygiene (the discussion will probe this)

- Set seeds (`torch`, `random`, `numpy`, `transformers.set_seed`).
- Never report a metric alone: give the **sample size**, the **split**, and a
  **baseline** (majority class, random, or the untrained model).
- Keep the eval set untouched by training and hyperparameter choices.
- If a result looks too good or too bad, check for leakage or bugs before
  celebrating or explaining it away.
- Keep a running **`RESULTS.md`** in the working directory, one entry per
  run: the exact command, the key numbers, the run time, and caveats. Append
  as you go, don't reconstruct it at the end. It's the user's notes for the
  discussion.

## Environment

- The Python environment is `~/interview-env`, already activated when
  launched via `cci`. If `python` isn't that venv, use
  `~/interview-env/bin/python`. Pinned: `datasets==3.5.0`, `torch==2.6.0`,
  `transformers==4.50.3`, plus `accelerate`, `scikit-learn`, `matplotlib`,
  `tqdm`. Don't upgrade the pinned packages. Installing something small and
  missing is fine; say so.
- If the interviewers hand over their own repo or `pyproject.toml`, follow
  its layout and conventions over these defaults.
- Debugging: reproduce first, read the actual traceback, then fix the root
  cause in the smallest change.
