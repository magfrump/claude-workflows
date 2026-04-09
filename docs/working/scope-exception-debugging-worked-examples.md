## Scope Exception: guides/README.md

The file scope constraint for this task listed only `guides/debugging-examples.md`, `CLAUDE.md`, and `docs/working/summary-debugging-worked-examples.md`.

However, `guides/README.md` must also be updated because the `guide-index-sync.bats` test requires every `.md` file in `guides/` to be listed in `guides/README.md`. The prior round 9 attempt failed BATS tests for exactly this reason.

Change: Added a one-line entry for `debugging-examples.md` to `guides/README.md`.
