# Interview profile

A slim Claude Code setup for a **25-minute research coding pairing session**
(Python with `datasets` / `torch` / `transformers`, on your own machine,
screen-shared), as opposed to this repo's default harness, which is built for
long unattended runs.

| | Default harness (`~/.claude`) | Interview profile (`~/.claude-interview`) |
|---|---|---|
| Instructions | 36 KB: decision tree, /away mode, questions.md, commit cadence | ~70 lines: brief plan → run → report; time and research discipline |
| Hooks / plugins | 6 hooks, 4 plugins | none |
| Subagents, docs, commits | routine | only if asked |
| Permissions | allowlist + guards | `acceptEdits`, Python/pip/uv/nvidia-smi pre-allowed |
| Output for later | `docs/working/` | a running `RESULTS.md` for the discussion |

Your normal `~/.claude` is never touched. Switching is just which command you
launch: `claude` (normal) or `cci` (interview).

## Setup (host WSL shell, not the container)

The cc-isolated container has no internet access, so run all of this from
your normal WSL terminal:

```bash
cd <this repo>                                 # the host path that is mounted as /workspace
bash profiles/interview/install.sh             # profile + ~/interview-env venv + ~/.local/bin/cci
bash profiles/interview/preflight.sh --warm    # checks, then caches models and runs a GPU step
```

The first install downloads about 3 GB (CUDA torch). `--warm` downloads
`distilbert`, `gpt2`, IMDB and WikiText-2, then runs one training step on the
GPU.

Then log in once (the profile has its own credentials) and do a practice run:

```bash
mkdir -p ~/interview-practice/run1 && cd ~/interview-practice/run1
cci          # then /login inside Claude Code
```

See [practice-task.md](practice-task.md) for timed practice tasks and a debrief checklist.

## Day of

- [ ] ~1 hour before: `bash profiles/interview/preflight.sh`. It must print `READY`.
- [ ] `mkdir -p ~/interview && cd ~/interview && cci`, and confirm you're logged in.
- [ ] Optional: `/fast` for faster output on the same model.
- [ ] Increase your terminal font size for the screen share. Share the terminal
      window (or the whole screen) where the work happens, so it's credited.
- [ ] If they give you a repo, clone it into `~/interview` and launch `cci` from inside it.
- [ ] When the timer ends, `RESULTS.md` is your outline for the discussion.

## Files

- `CLAUDE.md`: the session instructions (symlinked into the profile, so edits apply immediately)
- `settings.json`: model, effort, permissions (copied; re-run `install.sh` after editing)
- `requirements.txt`: the interviewers' file, verbatim
- `requirements-extras.txt`: `accelerate` (needed by `Trainer`), `scikit-learn`, `matplotlib`, `tqdm`; skip with `--no-extras`
- `install.sh`, `preflight.sh`, `warm-cache.py`: setup, go/no-go, cache warming
- `practice-task.md`: rehearsal tasks

Locations can be overridden with `CCI_CONFIG_DIR`, `CCI_VENV`, `CCI_BIN`.
