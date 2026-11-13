# Research: four small record fixes in one review unit

- **Goal**: Land the four small record fixes of brief `docs/working/briefs/2026-11-13-small-records-review.md` (D12 after the light pass, the `Harness feedback` warning, decision 018's moved cite, a failure pattern for `exec "$@"` under a bash `sh`) as one review unit.
- **Problem framing**: Four records drifted from what was built or found (a plan decision, an instruction-file pair, a line cite, the failure library), and one health-check warning prints every run because of the second. Considered and discarded: "the health check's divergence warning is too noisy and should be loosened", rejected because the warning was right: the section was genuinely absent, and the check's exemption list is the designed place to record intended divergence, not a loosening.
- **Project state**: docs-only review unit on `docs/small-records-review` · standalone · not blocked (cite: docs/working/briefs/2026-11-13-small-records-review.md)
- **Task status**: complete (implemented, reviewed)

## What exists

1. **D12.** `docs/working/plan-build-loop-handoff.md` D12 said "Each iteration is one full cycle", and its summary table row said "a full cycle every iteration for now" [observed]. The owner replaced that answer with Q-270 [2] (2026-11-11; the owner's answers file of that date is untracked, so the Q-270 archive entry is the tracked source), built by `docs/working/briefs/closed/2026-11-11-light-pass.md`, merged a77bbc97, approved in Q-279 [1] [observed: `docs/working/questions-archive.md`, `git log -1 a77bbc97`]. The rule's text is step 0.5 of `skills/dev-cycle/SKILL.md`: light only when `--main-log` shows only `chore` lines and the newest record is dated today and holds a full block; it skips steps 2, 3, 4 and 4b [observed]. The decision log's rows end at 88 [observed]; row shape is `| N | date | **decision** | rationale | source |`, and amendments to the plan are written into it as an indented "**Amended DATE (...)**" bullet (D8, D11) [observed].
2. **The warning.** `scripts/health-check.sh` gate 13, `check_md_semantic_divergence`, warns "H2 sections in global-instructions/CLAUDE.md not in AGENTS.md/GEMINI.md" for any H2 not in `expected_claude_only` [observed]. `## Harness feedback` (global-instructions/CLAUDE.md:169) was the one such H2. README's "Cursor, Copilot, Cline, and other AGENTS.md-compatible tools" symlinks `AGENTS.md`, `guides/` and the rest into each project [observed: README.md:75-96], so AGENTS.md readers work in other projects, which is exactly where `docs/harness-feedback.md` lives (`guides/harness-feedback.md`; `guides/cross-project-setup.md`:36). They have `guides/harness-feedback.md` through the symlink; they may not have `~/.claude/scripts/harness-feedback.py`, which the install puts in `~/.claude` [inferred].
3. **Decision 018's cite.** Two places in `docs/decisions/018-argv-exec-over-shell-string-interpolation.md` cited `scripts/confine-tests.sh:220` (Concretely item 2, and References) [observed]. The pattern now sits under the comment "# Decision 018's reference pattern" (line 274, body at 285-290) [observed]. `docs/roadmap.md`:168 cites the old line too, but the roadmap is the cycle's.
4. **The failure pattern.** `docs/failure-patterns.md` has no `exec` / option-injection entry [observed: grep below]; last entry FP-180. The fix is bd657ce8 ("run a command named "-something" on the unshare path"), inside merge b0ebed19, which runs the body under `"$BASH"` with `exec -- "$@"`. Finding 2 of `docs/reviews/security-review-final-2026-11-10-confine-tests-bats.md` records the reproduction; re-run here: `bash -c 'exec "$@"' sh -a x echo hi` prints `hi`, rc 0 [observed].

## Invariants

- `test/agents-gemini-sync.bats`: AGENTS.md and GEMINI.md bodies identical after line 3, and no `@` imports [observed]. The new section has no `@` token.
- Gate 13's AGENTS/GEMINI section-structure equality [observed: health-check.sh:1035].
- The failure library's schema: one line, `- **FP-NNN** DATE symptom: cause: fix: ref:`, single-token fields, reused categories [observed]. The gate's `fp_nums` reads `- **FP-NNN**` [observed: scripts/build-loop.sh:1395].
- The log's row numbers are sequential [observed].

## Prior art

- AGENTS.md already carries tool-neutral copies of global sections (Context Packing, Shared Thoughts) and drops Claude-Code-only ones (Tool Preferences is exempted in the check with a reason: "the AGENTS.md/GEMINI.md tools do not run under" the sandbox) [observed]. That is the pattern item 2 follows.

## Gotchas

- Failure-pattern grep: no matches found
  (`rg -n -i 'exec|dash|option|sh-is-bash|argv' docs/failure-patterns.md` returned only FP-080, a heredoc delimiter entry unrelated to exec; read as no match for this area.)
- The schema has one `ref:`. The brief asks to cite both the merge and the review, so the ref is one token joining them with `+`: `ref:b0ebed19+docs/reviews/security-review-final-2026-11-10-confine-tests-bats.md(finding-2)`.
- Category choice: `cause:environment-divergence` (the body assumed `sh` behaves one way; which shell `sh` is varies by host) and `fix:align-config` (starter-set "sync configuration across environments": the fix pins one interpreter, `$BASH`, on every host). No backfilled fix shape fits better; no new category coined.
- Bash writes naming CLAUDE.md beside `install.sh` trip a PreToolUse guard; read separately.
- `scripts/confine-tests.sh --probe` exits 3 here.

## Design choices

**Item 2, the warning (divergent design, three viable options).** Seeded with `docs/constraints.md` and the brief's criterion ("they need it if they work in projects that keep `docs/harness-feedback.md`").

| Option | What it means | Constraints |
|---|---|---|
| A. Copy the section verbatim to both files | Same text as the global instructions | Points at `~/.claude/scripts/...` that an AGENTS.md user may lack (S11 portability, S5 real use) |
| B. A tool-neutral copy in both files | Same rule; grammar pointer to `guides/harness-feedback.md` (symlinked into projects); the checker run from `~/.claude/scripts/` or the clone's `scripts/` (the clone fallback added in review, item 6) | S5: feedback from real use outside this repo is the section's whole value. S11: plain text. S3: restates a rule as AGENTS.md already does for every shared section; the grammar keeps one source. S2: AGENTS.md is not loaded here (the root CLAUDE.md is), 4 lines elsewhere |
| C. Exempt `Harness feedback` in `expected_claude_only` | Warning stops; AGENTS.md agents never file feedback | Fails the brief's own criterion: those agents do work in such projects (README:75-96). Loses S5 signal |

No hard constraint prunes any. B dominates: it meets the brief's criterion, which C fails, and avoids A's dangling path. **Path A: B.**

Other choices (one line each):
- D12: add an "Amended" bullet in the plan's own style and correct the two sentences that said every iteration is full (the D12 paragraph and the summary-table row); F53's row ("revisit later (D12)") points at D12 and stays.
- 018: cite the comment by its opening text, so it cannot drift again (the brief's second option); both cites changed.
- The check in item 2 is documented only in `scripts/health-check.sh`'s own comments; with option B no comment changes.

## Verification

- `scripts/confine-tests.sh --probe`: exit 3, first line "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the tests run through `scripts/health-check.sh` (which runs the bats suite) and `scripts/hermeticity-lint --root .`.
- `bats test/agents-gemini-sync.bats`: 4 of 4 ok.
- Health check's gate 13 before: not re-run on the base; the warning's text is reconstructed from the check's code (`warn "H2 sections in $GLOBAL_MD not in $sibling: ..."`, health-check.sh:1079) and the roadmap item that reports it every run. After (full `scripts/health-check.sh` on this branch, exit 0, "All checks passed."):

      ── MD file semantic divergence ──
        global-instructions/CLAUDE.md: 333 lines, 9 H2 + 16 H3 sections, 26 skill ref(s)
        AGENTS.md: 81 lines, 6 H2 + 0 H3 sections, 26 skill ref(s)
        GEMINI.md: 81 lines, 6 H2 + 0 H3 sections, 26 skill ref(s)
        ✓ AGENTS.md and GEMINI.md have identical section structure
        ✓ No semantic divergence detected across MD files

  The run's other warnings (unrun report-dependent suites, skills lacking fixtures, stale spikes, thoughts and personas) predate this branch and are outside it.
- `scripts/hermeticity-lint --root .`: exit 0, 145 test files, no unstubbed network spawns.

## Review

One fact-check-style reviewer (code-review's fact-check pass; the diff is docs only, so the security, performance and API critics have no surface) found no Must Fix. Addressed: (1) row 89 now names row 72's D12 clause, which still states the old answer; (2) the after-run above replaces a pointer to a commit that did not exist; (3) row 89 no longer cites the untracked answers file; (4) plan D12's blocked-thread bullet says "an iteration", not "a full cycle"; (6) the AGENTS.md section names the clone's `scripts/harness-feedback.py` and its `init`; (7) the task status. Kept: (5) FP-181's `+`-joined ref, a single grep-able token that cites both sources the brief names; no precedent, disclosed here and in the commit body. A second pass re-checked the fixes and found no Must Fix or Must Address; two of its three Considers were applied (the option-B row above, and naming `docs/harness-feedback.md` in the section), the third (this line's timing) is resolved by this sentence.

Failure-pattern skip: this branch has no fix(...) commits; FP-181 is added as the brief's item 4, not for a fix here.

## Files read

Last verified: 2026-11-13
docs/working/briefs/2026-11-13-small-records-review.md
docs/working/plan-build-loop-handoff.md
docs/decisions/log.md
docs/working/questions-archive.md
skills/dev-cycle/SKILL.md
docs/roadmap.md
scripts/health-check.sh
test/agents-gemini-sync.bats
AGENTS.md
GEMINI.md
global-instructions/CLAUDE.md
README.md
guides/harness-feedback.md
guides/cross-project-setup.md
docs/decisions/018-argv-exec-over-shell-string-interpolation.md
scripts/confine-tests.sh
docs/failure-patterns.md
docs/reviews/security-review-final-2026-11-10-confine-tests-bats.md
scripts/build-loop.sh
