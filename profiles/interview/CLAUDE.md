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
  next. The user reads these aloud, so keep them plain and specific. Every
  number you report carries its run ID and log, e.g. "0.656 (R3,
  `logs/probe_v2.log`)".
- **Surface anything important right away**: a surprising number, a
  suspected bug, a shortcut you took, an assumption about the task. Say it as
  soon as you notice it, not at the end.
- **Ask only when blocked** on something only the user knows (task
  ambiguity that changes the result). Otherwise make the reasonable call and
  state it.
- No subagents, no planning docs, no git commits unless asked. One agent,
  working in the open.
- **Narrate every subagent.** The terminal barely shows them, so the user
  can't tell from the screen what is delegated. Say it in plain text:
  - Before dispatching, write the brief to `briefs/<name>.md` and pass that
    text as the prompt, then say one line per agent:
    `→ Subagent "<name>": <task>. Why delegated: <reason>. Meanwhile I'll <X>.`
  - Have the agent write its report to `reports/<name>.md`. When it returns:
    `← Subagent "<name>" done: <headline>. Checked by: <what I re-ran>.`
    Don't build on its output until you have re-run one check yourself.
  - While any agent is running, end each step report with
    `Still running: <names>`.
  - If the user asks for delegation and you do some or all of it inline
    instead, say which part and why in one line. Never switch silently.

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
- Keep two notes files in the working directory. They are the user's notes
  for the discussion.
- **`RESULTS.md` is an append-only run log.** Add one entry per run as you
  go, and don't reconstruct it at the end. Never rewrite, reorder or replace
  it: add to the end with Edit, never Write. Give each run a stable ID and a
  heading that works as a summary on its own, then the same labeled lines
  every time, so the user can scan the headings or grep a label:

  ```
  ## R3 · meannf probe, v2 pairs · I→Alice 0.656 vs I→I 0.697
  - Cmd: `python probe.py --pool meannf --seed 0..4`
  - Data: <dataset, split, n train / n eval, seeds>
  - Baseline: <majority / random / control, with its number>
  - Result: <key numbers, with ± or CI>
  - Time: <wall clock>
  - Caveats: <leakage risk, small n, anything fixed or not yet checked>
  ```

  When a new task starts in the same directory, add a `# Task: <name>`
  heading and keep counting run IDs, so every `R` number stays unique.
- **`ANSWERS.md` is the discussion cheat sheet**, organized by the questions
  an interviewer asks rather than by time. It is the one file you rewrite in
  place. Update it after every run that changes the picture, keep it under
  about 40 lines, and cite run IDs (`R3`) for every number. Use these sections,
  in this order:
  `Answer` (2–3 lines) · `Setup` (model, data, split, n, seeds) ·
  `Baselines & controls` · `Evidence` · `Bugs found & fixed` ·
  `Caveats / threats to validity` · `What I'd try next`.
  When the user asks how to answer an interviewer's question, answer from
  `ANSWERS.md` and point to the `R` entry that backs it.

## Library pitfalls

- Print shapes, dtypes and one or two decoded examples at each stage before
  trusting a number.
- Tokenizers: causal LMs often have no pad token
  (`tokenizer.pad_token = tokenizer.eos_token`). Left-pad for batched
  generation. For last-token activations either side works if you index
  with `attention_mask.sum(1) - 1` (right) or `-1` (left); with left padding
  on an absolute-position model (`gpt2`), pass
  `position_ids = attention_mask.cumsum(-1) - 1`.
- For a target token's logit, `tokenizer.encode(t, add_special_tokens=False)`
  and print `convert_ids_to_tokens` to check the leading space.
- Hooks: `hs = output[0] if isinstance(output, tuple) else output`; register
  inside `try: … finally: handle.remove()` so hooks don't stack across
  re-runs; store `hs.detach().float().cpu()`. When steering, cast the vector
  to `hs.device`/`hs.dtype` and return `(new_hs,) + output[1:]` for tuples.
- Activation probes: mask pad positions out of mean pools, and check per-token
  norms once. A few tokens (the first, sometimes `.`/newline/whitespace)
  carry huge mid-layer activations that swamp a mean.

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
