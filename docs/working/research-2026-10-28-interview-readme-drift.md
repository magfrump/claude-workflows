# Research: interview profile README drift

Date: 2026-10-28 · Brief: `docs/working/briefs/2026-10-28-interview-readme-drift.md`
Base commit: 4b04a1eb · Workflow: research-plan-implement (no approval gate), then
pr-prep's review-fix loop. Docs-only change: no script in `profiles/interview/` changes.

## Scope

Every claim in `profiles/interview/README.md` checked against `settings.json`,
`install.sh`, `preflight.sh` (and, for the code-fact-check pass, the other files the
README describes). Line numbers are at 4b04a1eb.

## Claims the brief names (all three confirmed as drift)

| # | README claim (line) | What the code does | Checked against |
|---|---|---|---|
| C1 | `settings.json`: "model, effort, permissions" (68 in Files list, 67 before) | Also sets `theme` and `tui`, and the `claudeMdExcludes` list. Values: `model` `opus[1m]`, `effortLevel` `medium`, `theme` `dark`, `tui` `fullscreen`; excludes `/home/*/CLAUDE.md`, `/home/*/CLAUDE.local.md`, `/home/*/.claude/CLAUDE.md`, `/home/*/.claude/rules/**`; `permissions.defaultMode` `auto`, an allow list, and denies for `rm -rf`, `git push`, `git reset --hard` | `settings.json:2-5` (runtime values), `:6-11` (excludes), `:13` (mode), `:14-36` (allow), `:37-41` (deny) |
| C2 | "`cci` warns when the installed `CLAUDE.md` differs from the repo copy" (68) | The launcher that `install.sh` writes prints a WARNING plus review/install commands, then asks `cci: launch anyway? [y/N]` and exits 1 unless the answer is `y`/`Y`. It runs only when the repo copy exists, and compares `CLAUDE.md` only, not `settings.json`. The check is inline in the generated `~/.local/bin/cci` script (a heredoc in `install.sh`), not a named function | `install.sh:85-102` (heredoc), `:93` (compare), `:97-99` (prompt and exit) |
| C3 | "`preflight.sh` fails on any ancestor `CLAUDE.md` the exclusion doesn't cover" (21-22) | Walks the ancestors of `$HOME/interview` up to `/`, looking at `CLAUDE.md`, `CLAUDE.local.md` and `.claude/CLAUDE.md` in each. A file in `$HOME` itself passes when the installed `settings.json` merely contains the text `"claudeMdExcludes"` and `$HOME` is under `/home/`; the patterns themselves are never compared. A file above `$HOME` fails. `.claude/rules/**` is never looked at | `preflight.sh:122-123` (key-presence test), `:127` (the three file names), `:129-133` (pass/fail rule), `:124-137` (walk) |

Note on C2 and the brief's "naming the script and function": there is no function. The
check lives in the launcher body that `install.sh` generates; the README names the script
(`install.sh`) and the generated file (`cci`) instead.

## Code-fact-check of the rest of the README

| Line | Claim | Verdict | Evidence |
|---|---|---|---|
| 10 | Default instructions 36 KB | holds | `global-instructions/CLAUDE.md` is 36657 bytes |
| 10 | Interview instructions ~120 lines | holds | `profiles/interview/CLAUDE.md` is 123 lines |
| 11 | Default harness: 6 hooks | **stale** | `hooks/wiring.json` wires 9 hook scripts (auto-approve-allowed-commands, batch-feedback-routing-reminder, claude-config-audit, dd-routing-reminder, guard-trusted-writes, live-verify-gate, log-usage, log-usage-post, web-taint-mark). Fixed to name the file rather than a count that drifts |
| 11 | 4 plugins | holds | `global-instructions/CLAUDE.md` "Plugin-shipped skills" lists four |
| 11 | Interview profile: no hooks/plugins | holds | `settings.json` has no `hooks`/`enabledPlugins`; `install.sh:19` |
| 13 | `auto` mode, Python/pip/uv/nvidia-smi pre-allowed | holds but incomplete | `settings.json:13-41` also allows read-only shell and git commands and `huggingface-cli`, and denies three commands; table cell widened |
| 14 | `RESULTS.md` / `ANSWERS.md` | holds | `CLAUDE.md:63`, `:81` |
| 16 | `~/.claude` never written | holds (scripts) | `install.sh` writes only `CONFIG_DIR`, `VENV`, `BIN` (`:27-29`, `:50-63`, `:84-103`) |
| 32 | install makes profile + `~/interview-env` + `~/.local/bin/cci` | holds | `install.sh:27-29`, `:50`, `:67-81`, `:84-104` |
| 33 | `--warm`: checks, then caches models and runs a GPU step | holds | `preflight.sh:21`, `:145-148`; `warm-cache.py` |
| 37 | distilbert, gpt2, IMDB, WikiText-2; one training step | holds (one step per model) | `warm-cache.py:24-28`, `:45-67`. "one training step" is one per model (two total); reworded |
| 40 | profile has its own credentials | holds | `preflight.sh:139-143` checks `$CONFIG_DIR/.credentials.json` |
| 51 | preflight must print `READY` | holds | `preflight.sh:151` |
| 58-60 | `logs/*.log`, `briefs/`, `reports/` | holds | `CLAUDE.md:28`, `:31`, `:47` |
| 68 | copied, not symlinked; reinstall prints diff, keeps `.bak` | holds | `install.sh:51-63`; the `.bak` and diff happen only when the installed file differed, and apply to `CLAUDE.md` too |
| 70 | extras list, `--no-extras` | holds | `requirements-extras.txt:9-12`, `install.sh:35` |
| 74 | `CCI_CONFIG_DIR`, `CCI_VENV`, `CCI_BIN` | holds | `install.sh:27-29`; `preflight.sh:14-15` reads the first two |

Not checkable from code and left as written: the 3 GB download size, `/fast`, Claude Code
loading ancestor `CLAUDE.md` files whatever `CLAUDE_CONFIG_DIR` says, and the practice
run 2 history.

## Design choice

Seeded with docs/constraints.md (S3 one source of truth, S4, S8 small units) and the
brief's out-of-scope list (no script, settings or test change).

| Option | What | Hard constraints | Ranking |
|---|---|---|---|
| A. Inline corrections | Fix each claim where it sits; describe settings values in the Files list and the guard's real check in the intro paragraph | pass | Smallest diff; the reader meets each fact where they meet it today |
| B. New "What the guard checks" section | Move the exclude/preflight story into its own section | pass | Larger diff, and splits the intro's ancestor-CLAUDE.md warning from its caveat |
| C. Paste `settings.json` verbatim | Code block of the file | pass | Restates a second copy that drifts (S3); the criterion asks for a description |
| D. Point at the file, no values | "see `settings.json`" | pass | Fails acceptance criterion 1 |

Path A dominates: it meets every criterion with the smallest change. The exclude list is
described by pattern (four `/home/*/` entries) rather than pasted, and the hook count is
replaced by a pointer to `hooks/wiring.json` so the table stops drifting.

## Plan

1. Edit `profiles/interview/README.md`: intro paragraph (C3), Files list (C1, C2),
   table hooks and permissions cells, the warm step wording.
2. Review-fix loop: an independent code-fact-check pass over the edited README against
   the profile's files; fix any finding, docs only.
3. Final change: brief Status open to done, then the `handoff: ready` marker.

## Review log

(filled in after the review pass)
