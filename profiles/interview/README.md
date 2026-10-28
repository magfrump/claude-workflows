# Interview profile

A slim Claude Code setup for a **25-minute research coding pairing session**
(Python with `datasets` / `torch` / `transformers`, on your own machine,
screen-shared), as opposed to this repo's default harness, which is built for
long unattended runs.

| | Default harness (`~/.claude`) | Interview profile (`~/.claude-interview`) |
|---|---|---|
| Instructions | 36 KB: decision tree, /away mode, questions.md, commit cadence | ~120 lines: brief plan → run → report; time and research discipline; library pitfalls |
| Hooks / plugins | the hooks in `hooks/wiring.json`, 4 plugins | none |
| Subagents, docs, commits | routine | only if asked |
| Permissions | allowlist + guards | `auto` mode; Python, pip, uv, nvidia-smi, `huggingface-cli`, read-only shell tools plus `mkdir`/`tee`, and `git status`/`diff`/`log` pre-allowed; commands starting `rm -rf`, `git push`, `git reset --hard` denied |
| Output for later | `docs/working/` | append-only `RESULTS.md` run log + `ANSWERS.md` cheat sheet for the discussion |

Your normal `~/.claude` is never written, and it isn't read as config. But
Claude Code also loads the `CLAUDE.md` of every directory above the one you
launch from, whatever `CLAUDE_CONFIG_DIR` says. `~` sits above `~/interview`,
so without a guard the full `~/.claude/CLAUDE.md` loads into every `cci`
session (practice run 2 found this in every session so far). The profile's
`settings.json` excludes it with `claudeMdExcludes`, which lists four
`/home/*/` patterns: `CLAUDE.md`, `CLAUDE.local.md`, `.claude/CLAUDE.md` and
`.claude/rules/**`.

`preflight.sh` checks this only roughly. It walks the directories above
`~/interview` and looks for `CLAUDE.md`, `CLAUDE.local.md` and
`.claude/CLAUDE.md` in each. It never checks `~/interview` itself or any
other launch directory, so a `CLAUDE.md` left in `~/interview`, above a cloned
repo, goes unchecked. It fails on any file it finds above `~`. One found in
`~` itself passes, and is reported as excluded, as long as the string
`claudeMdExcludes` appears in the installed `settings.json` and `$HOME`
starts with `/home/`. It doesn't compare the file against the patterns (the
list could even be empty), and it never looks at `.claude/rules/**`. To see
what actually loads, run the `cci -p` command it prints when no ancestor file
fails.

Switching is just which command you launch: `claude` (normal) or `cci`
(interview).

## Setup (host WSL shell, not the container)

The cc-isolated container has no internet access, so run all of this from
your normal WSL terminal:

```bash
cd <this repo>                                 # the host path that is mounted as /workspace
bash profiles/interview/install.sh             # profile + ~/interview-env venv + ~/.local/bin/cci
bash profiles/interview/preflight.sh --warm    # checks, then caches models and runs a GPU step
```

The first install downloads about 3 GB (CUDA torch). `--warm` downloads
`distilbert`, `gpt2`, IMDB and WikiText-2, then runs one training step per
model on the GPU.

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
- `settings.json`: runtime values (`model` `opus[1m]`, `effortLevel` `medium`, `theme` `dark`, `tui` `fullscreen`), the `claudeMdExcludes` list described above, and permissions (`auto` mode, an allow list and three denies)
- Both are copied into the profile, so re-run `install.sh` after editing either. Copies rather than symlinks, so a branch switch in this checkout can't change the profile. The `cci` launcher that `install.sh` generates stops when the installed `CLAUDE.md` differs from the repo copy: it prints a warning with `diff` and `cp` commands, then asks `launch anyway? [y/N]` and exits unless you answer `y`. An empty or missing answer counts as no, so a `cci` run with nothing on stdin exits too. It skips the check if the repo copy is missing, for example after switching to a branch without it, and it doesn't compare `settings.json`. A reinstall overwrites a changed installed file, including runtime changes to `settings.json` (it prints the diff and keeps the previous version as `.bak`, overwritten on each reinstall), so put any value you want to keep in the repo's `settings.json`.
- `requirements.txt`: the interviewers' file, verbatim
- `requirements-extras.txt`: `accelerate` (needed by `Trainer`), `scikit-learn`, `matplotlib`, `tqdm`; skip with `--no-extras`
- `install.sh`, `preflight.sh`, `warm-cache.py`: setup, go/no-go, cache warming
- `practice-task.md`: rehearsal tasks

Locations can be overridden with `CCI_CONFIG_DIR`, `CCI_VENV`, `CCI_BIN`.
