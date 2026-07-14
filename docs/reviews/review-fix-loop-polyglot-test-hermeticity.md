# Review-fix loop — polyglot test hermeticity

**Branch:** `feat/polyglot-test-hermeticity` (now the integration branch)
**Loop:** 3 iterations, 30 verified findings, all fixed
**Cap decision: `split`**

## Outcome

The loop hit its 3-iteration cap (`workflows/review-fix-loop.md`). The cap-exceeded
gate requires an explicit `escalate | split | abandon` selection before a 4th
iteration; the selection was **`split`**. This branch is closed as a development
line and repurposed as the integration branch. Each piece below gets its own branch
and its own fresh 3-iteration budget.

## Why the loop did not converge cleanly

Not because findings ran out of steam — because *my own fixes kept seeding the next
round*. The arc is the finding:

| Iteration | Found | Character of the findings |
|---|---|---|
| 1 | 10 | Bugs in the original branch: five fail-open paths in the lint, `confine-tests.sh` missing `--tmpfs /tmp`, a silently-ignored `--no-loopback`, an unanchored `.claude` prune, missing real-tree anchors |
| 2 | 10 | Bugs **in iteration 1's fixes**: I closed the `test/lib` blind spot by *enumerating* another search dir, and the review found the dir I forgot (`test/skills/`, 20 suites, two live `claude -p`) |
| 3 | 10 | Bugs **in iteration 2's fixes**: `run ! bash x.sh` not followed, `load "$DIR/x"` unresolved, a `(` in a comment read as a call site, and a wrapper-chain regex that backtracked exponentially (~30 flags on a line hung CI) |

Three passes of tightening regexes over shell syntax, three new holes. Iteration 3
finally attacked the class rather than the instances: shell source is now
**tokenized**, and the matcher and the closure ask structural questions of the same
tokens. That removed the whole family at once and is ~1s on the full tree.

The lesson worth keeping: **a heuristic that must model a grammar should parse it.**
Each regex fix looked local and safe, and each one shipped a new false-green into a
gate whose entire job is to not produce false greens.

## Why `split` (not `escalate`)

The tokenizer rewrite (`346b0dd`) is the largest change of the three and is the only
one **no review has ever seen** — it landed in the fix phase after the last review
ran. Given that every prior fix phase seeded the next round's findings, the base rate
says a fresh pass would find something in it. Rather than spend a 4th iteration on one
oversized branch, the work splits into independently reviewable pieces that each
converge on their own budget.

## Known-weak seams (carry into the per-piece loops)

1. **`_split_functions` brace-matches without quote awareness** (`scripts/hermeticity-lint`).
   A `{` inside a string in a shell helper can mis-slice a function body. Fail-safe-ish
   — a mis-sliced body is not credited as a stub — but it is the weakest seam in the
   lint and the first place to look.
2. **The bwrap paths in `confine-tests.sh` have never been executed.** bwrap is absent
   from the devcontainer and the script correctly refuses to run without a namespace
   primitive (017 finding 1). `--tmpfs /tmp`, `--setenv TMPDIR`, and the
   `--no-loopback` primitive switch are verified *by construction* against the spike's
   demoed profile, not by a run. **This needs a real CI runner or dev host.**
3. **`confine-tests.sh` ships with no automated test at all** — a consequence of (2).

## The split

Merge order matters only where noted; otherwise independent.

| Branch | Content | Notes |
|---|---|---|
| `feat/devcontainer-uv` | `devcontainer-config/*`, `guides/devcontainer-setup.md`, decision-log row 18 | Independent (decision 18). Untouched by the loop. |
| `fix/test-env-hermeticity` | `test/lib/hermetic-env.bash`, the suites decoupled from `~/.claude` + locale, `bats_require_minimum_version` in 11 suites | Independent. The second hermeticity axis (host coupling), not the network one. |
| `fix/health-check-shellcheck-prune` | `scripts/health-check.sh` | Independent, tiny, one confirmed bug (green gate that linted zero files). |
| `feat/hermeticity-lint` | `scripts/hermeticity-lint`, `scripts/hermeticity/adapters/*`, `test/hermeticity-lint.bats`, `test/fixture-hermeticity.bats`, `guides/test-hermeticity.md`, decision 017 + DD, decision-log row 17 | **The big one.** Carries decision 017 and ~all of the loop's churn. Gets its own full budget. |
| `feat/confine-tests-netns` | `scripts/confine-tests.sh`, spike-doc update | Layer 2 of decision 017. Merge **after** `feat/hermeticity-lint`, which carries the decision record. Ships untested — see weak seam (2). |
