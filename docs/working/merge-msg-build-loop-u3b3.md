Merge branch 'feat/build-loop-u3b3': one git_harden for both scripts, and the D6 snippet that runs the gate only from bytes it has hashed

## What this does

U3b3 of the build-loop handoff (plan step 9's U3b3 bullet and its as-built note; D6):
- **`git_harden`** (`scripts/lib/dev-cycle-read.sh`): build-loop.sh's hardening moves into the lib with its trust model stated once (rows 281, 495). dev-cycle.sh now calls it too, so the digest and its check modes read no user or system git config, no hook, fsmonitor or replace ref, and no transport. HARDEN gains `log.date=default` (row 505: a bogus log.date stopped --check-brief) and `log.showSignature=false` (on main, a planted one made the digest's git log run gpg.program). A second call returns at once.
- **The D6 snippet** (`test/lib/d6-snippet.bash`): the orchestrator's one way to run build-loop.sh or dev-cycle.sh. U4 feeds it byte for byte to `bash -s -- SCRIPT ARG... <<'D6'` (the Bash tool's shell can be zsh). It refuses a replace ref, info/grafts, and a default branch that is not exactly one plain main or master naming a commit. In claude-workflows, a single perl process drives one `git cat-file --batch`, uses an object only once its bytes SHA-1 to its id, and takes every next id from checked bytes: main's first parents to the root, the trees down to `scripts/lib/`, then the four files, written from those bytes into a temp dir and run. Elsewhere it runs the root-owned `/opt/claude-workflows` copy after an ownership walk up to `/`. Any read failure refuses (`refuse d6: WHY`, exit 2); it never falls through to the image copy.

**Workflow provenance:** RPI (plan revision 4, step 9; U3b split before code at d1091eb8) → pr-prep, three iterations (the third the final confirming pass).
← carried from RPI: D6 (the gate runs from main's commit through a hardened snippet, F38-F40), U3b1's contract (git_harden's keys are the HARDEN list caller_gate reads; --state is called with no pairs exported, row 702), rows 200, 281, 311, 495, 505, 644, 648, 666.

**Corrections to branch commit bodies:** a0014ce5's "a bash script body, not a function" (it defines and calls `d6`; nothing lands in the caller's shell). c9648432's "B10: store_check and the snippet's reader name each other" was one-way until 2e51450e. d9515d09's re-hash (A1's first fix) was replaced by c9648432's verified reader.

## Reviewer's path — start here

1. `test/lib/d6-snippet.bash`: the header, then `d6()`. Read the perl `P=` program as the trust core: `obj` (one request, a checked header and size, a SHA-1 match) and `entry` (a tree entry by exact name and mode).
2. `git_harden` in `scripts/lib/dev-cycle-read.sh` and its two call sites (build-loop.sh before `caller_gate`; dev-cycle.sh after arg parsing).
3. `test/scripts/build-loop-orchestrator.bats`, the D6 block (tests 11-21).

## How to test

- Suites, run serially: orchestrator 21, check 146, dispatch 4, merge 12, read 20, dev-cycle 79, hermeticity 2, git-env 2 (286). shellcheck is clean. `scripts/health-check.sh` passed at the branch tip.
- Mutation-checked, each turning a test red: the hash check and its later replacement, the ownership walk, the log.showSignature pair, main's dev-cycle.sh without git_harden, refusing on a failed read, git_harden's once-only guard, and the old parent regex.
- The security critics' two-pack forgery (a forged copy of an id in a second pack) ran planted bytes at c9648432's parent and runs main's real scripts now. A forged packed copy beside a real loose one refuses.

## Areas of uncertainty

- **Q-140 (you: judgment), the snippet's trust root:** the choice of main's copy rests on the repository's own data. In another project, a loop that moves main onto a copy of claude-workflows' public root commit, or rewrites the orchestrator worktree's `.git` entry, gets its own scripts run instead of the image copy. The `.git` route also works here, unseen by --main-log. The options are always the image copy, a trusted outside signal, or Q-103's ruling. Interim: today's rule, named in the header and the plan note; nothing runs the snippet until U4.
- **U4 owes** (rows dated 2026-10-12):
  - Match a first line `refuse d6: ` before parsing any mode's output, as a stop that quotes the reason and stderr.
  - Route the orchestrator's own git reads through a script mode run by the snippet (git_harden is no shell wrapper; row 704 amended).
  - Call --state through the snippet.
  - Write the SKILL.md block, name one canonical copy, and turn T33's pending comment into the byte-equality assertion.
  - Bound a hung snippet.
  - Settle Q-140 before writing the selector.
- **Deferred with rows:**
  - the reader's per-commit cost (63 ms here; a full walk outside claude-workflows on every call);
  - a direct test seam for the perl reader;
  - SHA-1 with no collision detection;
  - the -c vs count-pair precedence;
  - the fork overhead (corrected figure ~80-100 ms).
- dev-cycle.sh in a repository owned by another user that needs a global safe.directory now reports "Not inside a git repository" (its header says so).

Review converged in 3 iterations, with divergence detection fired once:
- Iteration 1 short-circuited at fact-check on A1, an executed red: planted bytes ran after an in-place object rewrite.
- Iteration 2 (full panel) found A1 re-firing as B1 through a second packed copy. The snippet was rebuilt around one verified reader rather than patched again. That was an interim /away call under the flag.
- Iteration 3 was the final confirming pass: k=3 fact-check (95 clusters, 94.7% agreement), full panel, Stage 2.5 (9 endorsement claims, all Verified, executed). It found no Must Fix. One Must Address is deferred to Q-140; the late-parent route, the perl environment and the text were fixed after the pass. That batch's lite check found one wording item, fixed.
- Rubric: `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b3.md`.
- Override rows: 13 dated 2026-10-12 for this branch.
- 389 changed code lines.

Single-sample review; absence of findings is not an attestation.

Confidence: medium
Notes: merged on the recommendation (Q-137 standing instruction). Interim /away calls: the bash -s form, the verified-reader rewrite under divergence detection, and Q-140's interim (today's rule, documented).

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QjZ5sDNnJpnupxpYdLDCnr
