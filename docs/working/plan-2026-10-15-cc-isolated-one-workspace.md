# Plan: cc-isolated takes one workspace (roadmap Next 3)

**Task status:** in review (iteration 2) · **Branch:** `fix/cc-isolated-one-workspace` (from `merge/ready-2026-10-15`, 5e6e9266) · **Last verified:** 2026-10-15

Deferred items from the rebuild-hint fix (`docs/reviews/code-review-rubric-2026-10-15-fix-rebuild-hint-recreate.md` A7; override-log rows 2026-10-15): (a) a second positional workspace is a usage error; (b) install.sh's "Next steps" lines lose their trailing `# …` notes, and its `--probe-only` row stops saying "rebuilds".

## Pre-mortem (enforcement file: `cc-isolated.sh` and `install.sh` match the gate's `enforcement` regex)

Assume this shipped and a user still launched the wrong workspace, or a legitimate command broke. The stories, as bypass families, each marked:

| # | Family | How it fails | Status |
|---|---|---|---|
| F1 | Second positional before `--` | `cc-isolated ~/a  # note` passes `#`, `note`; the old parser kept the last one | **Covered**: exit 2 at the second positional, naming both values |
| F2 | Positionals after `--` | The old `--) shift; break` dropped everything after it, so `cc-isolated -- ~/a` silently opened `$PWD` | **Covered**: mirror cc-push's rule (at most one word after `--`, and only if none came before) |
| F3 | A note whose words are flags | `cc-isolated  # --bless` sets `ws=#`, then `--bless` runs a re-bless nobody reviewed; the second-positional rule never fires because no second positional follows | **Covered**: a positional starting with `#` before `--` is itself a usage error, raised at the first note word, before any later flag is parsed. A real directory named `#x` is still reachable as `./#x` or `-- '#x'` |
| F4 | A note with shell syntax (`;`, `|`, `&&`, `$( )`) | The shell acts on it before cc-isolated runs | **Not coverable in the launcher.** Mitigated by printing no notes on copyable lines (install.sh here; cc-isolated's and init-firewall.sh's own lines in 47da5a4b) |
| F5 | A note word consumed as a flag value (`--profile # x`) | `--profile '#'` | **Was uncovered (review iteration 1, A1)**: `--profile` took its next word unchecked, so `--profile '#' --bless` ran a bless and `--profile '#' x` opened x (`register_project`'s check only runs under `--register`). **Now covered**: a `--profile` value starting with `#` or `-` is a usage error |
| F6 | A legitimate form passing two positionals | Breaks a documented command | **Covered by audit**: every caller passes at most one (below) |
| F7 | The usage error lands after a side effect | e.g. after the host-tool refusal or the devcontainer check | **Covered**: the parse loop runs before both; usage errors answer first (decision log row 71) |

`/pre-mortem` skill: this table is the bypass-family pass (RPI's enforcement-file rule); not escalated further (one function, ~20 lines). `/architecture-review`: not triggered (one module, no structural change).

## Argument grammar audit

- Modes: launch (no flag), `--probe-only`, `--register` (+ `--profile V`) take a workspace; `--bless`, `--list` ignore one; `--help` exits first. There is no `--clean` mode in cc-isolated.sh. `--` is accepted but undocumented and unused.
- Callers that pass positionals: install.sh "Next steps" (one `<repo>` per line), `rebuild_hint` (`--probe-only WS && cc-isolated WS`, one each), the unregistered NOTE (`--register 'WS' --profile P`), init-firewall.sh's hint, the guides (`cc-isolated-usage.md`, `devcontainer-setup.md`, one each), `test/cc-isolated-functions.bats` (one each), `hooks/live-verify-gate.sh` messages (one). None passes two.

## Steps

1. `main()`: on a positional, refuse `#…` (F3), refuse a second (F1); after `--`, at most one word and only if none came before (F2). Message via `printf %q` (values are untrusted text echoed to a terminal), then the usage, exit 2, like the other usage errors.
2. install.sh "Next steps": notes onto their own lines, `--probe-only` row says "recreates the container".
3. `--help` header and `guides/cc-isolated-usage.md`: one workspace; a pasted note is now a usage error.
4. bats: each mode taking a workspace × second positional → 2; `--` forms; `#` word; install.sh lines carry no `#`. Each fails on 5e6e9266.
