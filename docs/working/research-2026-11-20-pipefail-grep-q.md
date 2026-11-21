# Research: other `printf | grep -q` pipelines under `pipefail`

Brief: `docs/working/briefs/2026-11-20-pipefail-grep-q.md`. Branch: `fix/pipefail-grep-q`.

Failure-pattern grep: `rg -n -i -e pipefail -e sigpipe -e 'grep -q' docs/failure-patterns.md` -> FP-009, FP-129, FP-175, FP-182. FP-175 (a pipe into `grep -q` dying of SIGPIPE 141 under pipefail, fixed by removing the pipe) is this bug's mechanism, cause and fix.
Failure-pattern skip: FP-175 already records this mechanism, cause category and fix shape; these sites are more instances of it (as the rubric-selection flake was), so a new entry would duplicate it.

## Mechanism, measured

Under `set -o pipefail`, `writer | grep -q` exits at its first matching line. If the writer still has bytes to write, it dies of SIGPIPE (141) and the pipeline reports 141, which an `if` reads as "no match". Probes in the sandbox (bash, `echo "$x" | grep -qE ...`, 50 to 3000 runs each):

| Input | Lost matches |
|---|---|
| 3 short lines, match on line 1 | 1 of 3000 |
| one 200 KB line holding the match | 0 of 50 (grep must read to the line's end) |
| match on line 1, then 70 / 100 / 120 KB | 2 / 1 / 6 of 200 |
| match on line 1, then 200 KB | 50 of 50 |

So the risk needs text after the matching line. A single-line input is safe at any size. A short multi-line input loses rarely, mostly under load (FP-175's flake). From about 128 KiB of trailing text the loss is certain.

## Sites

`pipefail` comes from `set -euo pipefail` in `scripts/self-improvement.sh`, `scripts/health-check.sh` and `scripts/board.sh`. `scripts/lib/si-functions.sh` is sourced by `self-improvement.sh` and by `health-check.sh`, so it runs under it too. The hooks below set no `pipefail`. Search: `rg -n '\|\s*(grep|rg|egrep|fgrep)\b[^|]*\s-[a-zA-Z]*[qm]' scripts/ hooks/`, which also catches `-Eq`, `-iq` and `-m1` forms that `\| *grep -q` misses.

| Site | pipefail | Largest input (why) | Verdict |
|---|---|---|---|
| `scripts/self-improvement.sh:824` `head -1 "$IDEAS_FILE" \| grep -qi DONE` | yes | one line (`head -1`) | safe: single line |
| `scripts/self-improvement.sh:1512` `echo "$WEAK_DIMS" \| grep -qi` | yes | one line (`WEAK_DIMS` is `paste -sd,` output) | safe: single line |
| `scripts/self-improvement.sh:1830` `git diff --name-only --diff-filter=U \| grep -q .` | yes | one conflicted path per line. Empty once `merge_landed` holds, unless the resolver started a new conflicted operation after committing | fix: fail-open (reads "no conflicts"), one line. No bats case: no realistic large input |
| `scripts/lib/si-functions.sh:110` `head -n 1 "$plan_path" \| grep -q` | yes | one line | safe: single line |
| `scripts/lib/si-functions.sh:241/253/290` `echo " $ALLOWED " \| grep -q " $v "` | yes | one line (constant allow-list; the planner value is the pattern, not the input) | safe: single line. A loss would also reject, which is fail-closed |
| `scripts/lib/si-functions.sh:320` traversal check, `echo "$fpath" \| grep -qE` | yes | unbounded: `fpath` is `jq -r` of planner JSON, and a JSON string can hold newlines. `dirname` of `../x\n<tail>` is `..`, so nothing later rejects it | fix: fail-open on a path guard. Bats case |
| `scripts/lib/si-functions.sh:327` glob check, same shape | yes | same | fix, with a bats case |
| `scripts/board.sh:82` `printf '%s\n' "$1" \| grep -a -m1 '✗' \|\| printf ... \| head -n1` (missed by the brief's list) | yes | `questions.sh check` output, one line per refusal (3000 refusals is about 220 KB) | fix: a lost match also ran the fallback, so the board printed the refusal line twice. Bats case |
| `scripts/health-check.sh:555` `head -1 "$wf" \| grep -q` | yes | one line | safe: single line |
| `scripts/run-tests.sh:335` `head -15 "$f" \| grep -m1` | yes | 15 header lines of a bats file, far under one pipe write | safe: head's single write ends before grep can exit |
| `hooks/claude-config-audit.sh:112` `printf '%s' "$OUTPUT" \| grep -q` | no (`set -e` deliberately off, no pipefail) | large | safe: the pipeline status is grep's own |
| `hooks/live-verify-gate.sh:65/68/75`, `hooks/batch-feedback-routing-reminder.sh:90/95`, `hooks/dd-routing-reminder.sh:52` | no | the command or prompt text | safe: no pipefail |
| `scripts/self-improvement.sh:394`, `scripts/health-check.sh:144` | yes | already here-strings | fixed before (FP-175, the rubric flake) |

## Design

Fix form: a here-string (`grep … <<< "$x"`). The other forms are `< <(printf …)`, a `[[ =~ ]]` rewrite, or masking the 141. The here-string dominates: it is the prior art at the two fixed sites and keeps the regexes unchanged, and a `git revert` undoes it. Path A (one option dominates), no divergent-design pass. For the board fallback, `head -n1 <<< "$1"` also removes that pipe's own 141. For `1830`, `<<< "$(git diff …)"` keeps the old semantics: a failing `git diff` still reads as no conflicts, as it did when pipefail turned its status into the `!`'s true.

## Tests

- `test/validate-task-json.bats`: two cases, a traversal path and a glob path, each followed by about 200 KB. They assert the rejection message. On the old code both fail (verified by restoring the old `si-functions.sh`).
- `test/scripts/board.bats`: 3000 malformed headings. The UNREADABLE line must be the first refusal, printed once. It fails on the old `board.sh`.
- Touched suites (`validate-task-json`, `scripts/board`, `merge-safety`, `scripts/self-improvement-smoke`, `rubric-selection`) pass. `scripts/hermeticity-lint --root .` passes.
- `scripts/confine-tests.sh --probe` exits 3: "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the suites ran plain, backed by the lint.
- No changed file is in `hooks/live-verify-gate.sh`'s enforcement or host-tool sets, so no trailer is needed.

## Out of scope, noted

`| head` readers under pipefail are a related class: the writer's 141 fails the substitution rather than losing a match. Example: `scripts/self-improvement.sh:1695/1699`, `sed … | head -1` in an assignment under `set -e`, with no `|| true`. The brief allows no other change, so these are left for the cycle to weigh.
