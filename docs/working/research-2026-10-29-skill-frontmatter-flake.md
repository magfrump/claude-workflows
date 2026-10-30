# Research: the flaky "missing field" reports from the skill-frontmatter check

Brief: `docs/working/briefs/2026-10-29-skill-frontmatter-flake.md` · Date: 2026-10-29 · Branch: fix/skill-frontmatter-flake

## The case

`check_skill_frontmatter` in `scripts/health-check.sh` (gate 1) twice reported a field missing
from a skill file that had it: `test-strategy: missing 'description' field` (tests 198, 199
and 208 of the 2026-10-29-2003 run, while the outer check passed the same file) and
`user-testing-workflow: missing 'name' field` once on a build loop's branch. Both under load.

The check reads the frontmatter once into `$yaml`, then tests each required field with

    if ! echo "$yaml" | grep -qE '^name:'; then fail ...

and the script runs under `set -euo pipefail`.

## Reproduction

Reproduction: `cd <worktree> && LC_ALL=C timeout 90 taskset -c 5 bash probe2.sh "$PWD" 3000`,
where probe2.sh (scratch, not committed) sources `scripts/lib/md-utils.sh`, reads
`skills/test-strategy/SKILL.md`'s frontmatter, and runs `echo "$yaml" | grep -qE '^name:'` and
the same for `^description:` 3000 times each under `set -o pipefail`, recording
`${PIPESTATUS[@]}` for every run that is not `0 0`.

- Pinned to one CPU, four runs of 2000 to 3000: 2, 3, 0 and 0 false reports; every one with
  PIPESTATUS `141 0` (echo killed by SIGPIPE, grep matched).
- Unpinned, 2000 and 3000 runs: 0 false reports (so a normal run rarely loses the race).
- Deterministic form: a frontmatter larger than the pipe buffer (~280 KB, `name:` first)
  gives 50 of 50 false reports through `echo | grep -q`, 50 of 50 through `printf | grep -q`,
  and 0 of 50 through a here-string (`grep -q ... <<<"$yaml"`). The new bats cases in
  `test/scripts/health-check.bats` ("larger than the pipe buffer") use this form.

## Hypothesis log

- H1: under `pipefail`, `echo "$yaml" | grep -q` fails when grep matches and exits before
  echo's last write, because echo then dies of SIGPIPE (141) and the pipeline's status is 141
  · tested: the loop above, pinned to one CPU, logging PIPESTATUS; then the >64 KiB fixture
  · result: confirmed · learned: every false report is `141 0`; bash line-buffers its builtins'
  stdout, so a multi-line `$yaml` is several `write()`s and grep (matching on line 1 or 2) can
  exit between them whenever the scheduler runs it mid-echo, which is what load does. A
  frontmatter past the pipe buffer makes echo block, so grep always exits first.

The brief's other candidates were not needed once H1 reproduced with no other process
touching the file: the frontmatter is read once into a variable (`extract_yaml_frontmatter`,
an awk over the file) before the greps, so a concurrent rewrite would show as a missing
frontmatter or a missing field consistently, not as one `141`; and the check uses no temp
file.

## Cause

`grep -q` stops reading at its first match by design; `pipefail` turns the writer's SIGPIPE
into a pipeline failure; `!` turns that into "field missing". The check is right about the
file and wrong about its own plumbing. The same shape guards `requires:` (line 194): there a
lost race silently skips the mixed-forms check instead of failing (fail-open), which no one
would notice.

Shared with other sections? (Line numbers here are at 0388b194, before the fix; the fix
adds three comment lines above them.) A scan of `scripts/health-check.sh` for early-exit readers
(`| grep -q`, `| head`) finds only line 549 (`head -1 "$wf" | grep -q '^---$'`: head writes
one line in one write and exits, so grep cannot exit before it) and line 850 (`grep -o ... |
head -1` on one line of input: grep writes its output in one flush at exit). Neither can lose
the race, so no other section shares the cause and the scope stays at gate 1. Other scripts
were not audited (out of scope); the FP entry carries the grep-able shape for whoever meets it.

Failure-pattern grep: FP-009, FP-129 (`grep -inE 'sigpipe|pipefail|141|flake|frontmatter' docs/thoughts/failure-patterns.md`; FP-141 and FP-174 also matched on the word but are unrelated mechanisms)

## Gotchas

- FP-009 (SIGPIPE exit 141 from `jq | sort | head`): the same SIGPIPE-under-pipefail
  mechanism, there with output lost; here it inverts a check. Implies: any early-exit reader
  (`grep -q`, `head`) fed by a pipe under `pipefail` is suspect.
- FP-129 (grep's exit 1 under pipefail made an else branch unreachable): pipefail changes what
  `!`/`if` on a pipeline means; the fix must keep a real non-match failing.
- A fix that drops `pipefail` or `-q` would also work but hides the reason; a later "tidy"
  back to `| grep -q` would reintroduce the bug. The test must catch that.

## Options (divergent design, seeded with docs/constraints.md and the brief)

| Option | What it is | Strict as today? | Notes |
|---|---|---|---|
| **A. Here-string** | `grep -qE '^name:' <<<"$yaml"` | yes | No writer process, so nothing to SIGPIPE. Already the idiom at lines 758, 767 of this file (S3). One-token change per site. |
| B. Bash match | `[[ $'\n'$yaml =~ $'\n'name: ]]` | yes | No subprocess, but a second regex dialect in one function and harder to read. |
| C. Drop `-q` | `echo "$yaml" \| grep -E ... >/dev/null` | yes | grep drains its input, so no race; but the reason is invisible and a "tidy" to `-q` regresses it. |
| D. Local `set +o pipefail` | toggle around the greps | yes | Weakens the script's error regime (H2) for a plumbing problem. |
| E. Accept 141 | `\|\| [[ ${PIPESTATUS[1]} == 0 ]]` | yes | Clumsy, and PIPESTATUS is easily clobbered. |

A dominates: it removes the race rather than tolerating it, matches existing code in the same
file, and a really missing field still fails (grep exits 1 on the here-string). Decision: A,
at all three `echo "$yaml" | grep -q` sites in gate 1 (`name`, `description`, `requires`).
The other `echo "$yaml" | ...` pipelines in the function (sed, grep -o, wc) read all their
input and cannot lose the race; left as they are.

The brief's "name the bytes it read" diagnostic is for the not-reproduced branch; with the
cause reproduced and removed it is not added (S8, small units).

## Plan

1. `test/scripts/health-check.bats`: three cases that source the script and call
   `check_skill_frontmatter` on a lone fixture whose frontmatter is past the pipe buffer: all
   fields present passes; `name` missing still fails (strictness); a mixed `requires:` block
   is still flagged (the fail-open site). Confirm the first and third fail before the fix.
2. `scripts/health-check.sh`: the three here-strings, with a comment saying why.
3. Run the whole health check; add FP entry; set the brief's Status to done.

## Verification

- Before the fix (at 0388b194 plus the new cases): `bats -f 'pipe buffer'
  test/scripts/health-check.bats` gives `not ok` for all three. The full-fields fixture
  reports `missing 'name'` and `missing 'description'`; the mixed `requires:` fixture is not
  flagged at all (the fail-open site); the missing-name fixture also reports a false
  `missing 'description'`.
- After the fix: all three `ok`; the whole health check result is recorded in the commit.
