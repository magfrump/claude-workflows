# RPI: Integration-conflict rationale memory log

Status: complete
Relevant paths: workflows/branch-strategy.md, docs/working/integration-conflicts.md

## Research

### Task
The Integration branch refresh procedure (`workflows/branch-strategy.md`, step 4) recovers a prior
conflict resolution with `git show <previous-integration-branch>:<path>`. That returns the **resolved
code** but never the **rationale** — which side was authoritative, what was intentionally dropped, what
made the two sides diverge, when the resolution goes stale. The user wants to use existing integration
branches "for reference on how to resolve merge conflicts" *beyond* the code-only reference the shipped
procedure provides. Persist the *why* into a new `docs/working/integration-conflicts.md`, and wire the
procedure to append a rationale entry on each resolution and grep the log on the next build.

### Prior art in the file
- Step 4 (lines ~220-231): "Resolve conflicts using the prior integration branch as reference *only*"
  — the `git show` reference, plus the "prior resolutions go stale, re-verify each hunk" caution.
- Step 5: first-principles resolutions for PRs absent from the previous integration branch.
- "Why this shape (failure-driven)": three invariants, the second being "prior resolutions are
  reference only."
- `Done when…` checklist + Quick-reference table conventions used throughout.
- The prior RPI doc `rpi-integration-branch-procedure.md` records the section's design intent.

### Invariants to preserve
- `git show <prior-branch>:<path>` stays the code reference; the log is the *complementary* why.
- Re-verify-each-hunk discipline is unchanged — the log is a hint, never a patch to replay.
- Section ordering, `Done when…`, Quick-reference, and `<YYYY-MM-DD>` pass-the-date convention.
- File scope: only `workflows/branch-strategy.md` and `docs/working/*`.

### Key design choice: grep key = file path
The procedure already addresses a prior resolution by `<path>` (`git show …:<path>`). Using the same
`<path>` as the log's grep key means one handle locates both the prior code and the prior rationale.
So each entry keeps `path:` on its own line and the recovery command is
`grep -n -A8 '<path>' docs/working/integration-conflicts.md`.

## Plan
1. Create `docs/working/integration-conflicts.md`: purpose (`git show` = what, log = why), how it's
   used in step 4 (grep-before, append-after), an entry template with a `staleness signal` field
   (ties to the "resolutions go stale" invariant), and an empty Entries section (newest-first).
2. Edit step 4: recover intent from **two** sources (`git show` for code + `grep` the log for why),
   then **append a rationale entry** after each resolution. Inline a compact entry template.
3. Edit step 5: note first-principles resolutions get a log entry too (marked no-prior-reference).
4. "Why this shape": add a fourth invariant — "Rationale outlives code" — and bump "three" → "four".
5. Add a `Done when…` bullet and two Quick-reference rows (grep-to-recover, append-to-record).

## Verification
- Markdown renders; conventions match the rest of the file.
- The grep key (`<path>`) is consistent between the log file and step 4's command.
- The append action and the grep action both appear, traceable to step 4.
- Relative link `../docs/working/integration-conflicts.md` resolves from `workflows/`.
- No file outside scope touched.
