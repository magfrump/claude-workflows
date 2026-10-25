# Interview profile

A slim Claude Code setup for a **25-minute research coding pairing session**
(Python with `datasets` / `torch` / `transformers`, on your own machine,
screen-shared), as opposed to this repo's default harness, which is built for
long unattended runs.

| | Default harness (`~/.claude`) | Interview profile (`~/.claude-interview`) |
|---|---|---|
| Instructions | 36 KB: decision tree, /away mode, questions.md, commit cadence | ~120 lines: brief plan → run → report; time and research discipline; library pitfalls |
| Hooks / plugins | 6 hooks, 4 plugins | none |
| Subagents, docs, commits | routine | only if asked |
| Permissions | allowlist + guards | `auto` mode, Python/pip/uv/nvidia-smi pre-allowed |
| Output for later | `docs/working/` | append-only `RESULTS.md` run log + `ANSWERS.md` cheat sheet for the discussion |

Your normal `~/.claude` is never written, and it isn't read as config. But
Claude Code also loads the `CLAUDE.md` of every directory above the one you
launch from, whatever `CLAUDE_CONFIG_DIR` says. `~` sits above `~/interview`,
so without a guard the full `~/.claude/CLAUDE.md` loads into every `cci`
session (practice run 2 found this in every session so far). The profile's
`settings.json` excludes it with `claudeMdExcludes`, and `preflight.sh` fails
on any ancestor `CLAUDE.md` the exclusion doesn't cover. Switching is just
which command you launch: `claude` (normal) or `cci` (interview).

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
- [ ] Split the shared terminal (tmux) and run
      `tail -F logs/*.log RESULTS.md` in the second pane, so background jobs
      and agent work are visible. Briefs and reports from any subagents land
      in `briefs/` and `reports/`.
- [ ] When the timer ends, `ANSWERS.md` is your outline for the discussion,
      backed by the `R` entries in `RESULTS.md`.

## Files

- `CLAUDE.md`: the session instructions
- `settings.json`: model, effort, permissions
- Both are copied into the profile, so re-run `install.sh` after editing either. Copies rather than symlinks, so a branch switch in this checkout can't change the profile. `cci` warns when the installed `CLAUDE.md` differs from the repo copy. A reinstall overwrites runtime changes to `settings.json` (it prints the diff and keeps a `.bak`), so put any value you want to keep in the repo's `settings.json`.
- `requirements.txt`: the interviewers' file, verbatim
- `requirements-extras.txt`: `accelerate` (needed by `Trainer`), `scikit-learn`, `matplotlib`, `tqdm`; skip with `--no-extras`
- `install.sh`, `preflight.sh`, `warm-cache.py`: setup, go/no-go, cache warming
- `practice-task.md`: rehearsal tasks

Locations can be overridden with `CCI_CONFIG_DIR`, `CCI_VENV`, `CCI_BIN`.
