# Research: `migrations.sh check` with a relative root

**Goal**: `bash scripts/lib/migrations.sh check ROOT` and `fingerprint ROOT` give the same result for a relative ROOT (`.`, `../repo`) as for an absolute one (brief `docs/working/briefs/2026-10-29-migrations-relative-root.md`).
**Task status**: complete (research, plan and implementation on `fix/migrations-relative-root`)

Reproduction: `cd <checkout root> && bash scripts/lib/migrations.sh check .` prints "refuse questions: its source was not found in . (conv_source's anchors); fix conv_source with the move" and exits 1, while `bash scripts/lib/migrations.sh check "$PWD"` exits 0 with no output; `fingerprint .` prints "questions (source not found)". As a test: the new case "a relative ROOT (. and ../c) gives the same check and fingerprint as an absolute one" in `test/scripts/convention-migrations.bats`, which failed before the fix.

## What exists

- `scripts/lib/migrations.sh` (150 lines): `conv_source C R` prints the text convention C is fingerprinted from in checkout R. For `questions` it reads `$r/scripts/questions.sh`'s header block (resolves fine relative to the caller's cwd), then runs `(cd "$t" && ... bash "$r/scripts/questions.sh" init)` in a fresh temp repo. After the `cd`, a relative `$r` resolves against `$t`, the script is not found, the subshell fails and `conv_source` returns 1, so `conv_check` reports the source as missing. The roadmap, brief and record cases never `cd`, so only `questions` breaks (matches the reproduction).
- Callers: the run-directly block (`check`, `fingerprint`), and the bats file. `scripts/dev-cycle.sh` sources the lib only for its registry (`MIG_*` arrays); it never calls `conv_source`/`conv_check`. Health check and bats always pass an absolute root, which is why nothing caught it.
- Missing or non-directory ROOT today: every convention prints "refuse C: its source was not found in ROOT ..." and `check` exits 1 (awk names the path on stderr). `fingerprint` prints "(source not found)" per convention and exits 0 (existing behaviour, out of scope).

## Invariants

- Every existing refusal and its text stays as is, including a missing or non-directory ROOT naming ROOT.
- The registry lines are untouched (out of scope), so no fingerprint may change: the fix must not alter the text fed to `sha256sum`.
- `build-loop.sh`, `dev-cycle.sh`, `questions.sh` untouched.

## Design (divergent design, seeded with docs/constraints.md and the brief)

Candidates:
1. **Absolutize ROOT once in the run-directly block** (`root="$(cd -- "$root" && pwd)"`, refusing a bad ROOT there). Fixes the CLI; a sourced caller passing a relative path to `conv_check` still breaks; changes the missing-ROOT message (a new refusal text to test) and needs care to keep it naming ROOT.
2. **Absolutize at the point of the `cd`, inside `conv_source`'s questions case**: resolve `$r/scripts/questions.sh` to an absolute path before entering the temp dir; a failed resolve returns 1 as any other missing anchor does. Fixes every caller (CLI and sourced), leaves every refusal byte-identical, three lines.
3. **Both**. Two mechanisms for one bug (S3), no added coverage over 2 beyond a reworded missing-ROOT message nobody asked for.
4. **Avoid the `cd`** (run `questions.sh init` against `$t` via `git -C`). `questions.sh init` writes relative to its cwd's repo, and `questions.sh` is out of scope; not viable without changing it.

Hard lines (H1-H4) all pass for 1-3 (no gate logic moves, fail-closed behaviour kept, hermetic bats). Soft: S3 and S8 favour 2 (one code path, smallest diff, one revert); 2 is the root cause location, which the brief allows ("or an equivalent"). Option 2 dominates: chosen.

Review round 1 (one independent reviewer, clean, three non-blocking notes) refined it: a relative ROOT named like `x=y` still failed, because awk reads that operand as an assignment, so the resolve moved from the questions case to the top of `conv_source`, covering every operand and every convention. The default ROOT's `cd` also got `CDPATH=''`, and the test gained `x=y` and a non-directory ROOT.

## Gotchas

- Failure-pattern grep: FP-020, FP-062
  - FP-020: a relative build path resolved against the workspace, not the config dir. FP-062: a relative env override resolved against the wrong directory. Same class (a relative path read after the base changed): resolve it against the base it was given in, before anything changes directory.
- `cd` honours `CDPATH`, which can print to stdout and change the target; resolve with `CDPATH= cd -- "$r"`.
- Use `pwd` (logical), as the run-directly default already does; `-P` is not needed since nothing compares paths.

Failure-pattern skip: same class as FP-062 (a relative path resolved after the working directory changed); a new entry would duplicate it.

## Plan

1. bats case in `test/scripts/convention-migrations.bats`: in a source copy `$T`, `cd "$T"`; `check .` exits 0 with no output; `fingerprint .` equals `fingerprint "$T"` and has no "not found"; from `$T/..`, `check c` (a `../`-free relative form) and from a sibling dir `check ../c` exit 0; a missing relative ROOT still exits 1 naming it. Confirm it fails before the fix.
2. Fix in `conv_source` (option 2), resolving `$r` once at its top.
3. Header: "ROOT (absolute or relative to the current directory) defaults to ...".
4. Run `convention-migrations.bats`, then the health check; set the brief's Status to done.

Test strategy: the one gap is G1 (relative ROOT never exercised); the case above covers `.`, a plain relative name, `../`, and the missing-ROOT refusal staying loud. No other behaviour changes, so no other tests.
