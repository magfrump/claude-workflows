# Architecture Review — build-loop handoff (plan)

**Scope:** the proposed module structure in `docs/working/plan-build-loop-handoff.md` (a plan, not a diff), read against `docs/working/research-build-loop-handoff.md`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `test/scripts/dev-cycle.bats`, `scripts/lib/`, `test/lib/`
**Date:** 2026-10-02
**User goal:** Before any code is written, check that the plan's split into `scripts/build-loop.sh`, a new `scripts/lib/dev-cycle-read.sh` and the existing `scripts/dev-cycle.sh` (some calls by sourcing, some by subprocess) is coherent. Also check its dependency direction, CLI surface, where the brief machine-line grammar lives, and how the tests are split.

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

Trust-boundary cross-reference: no-op. No `docs/reviews/security-review-*.md` file exists (the existing security reviews are prefixed `qNNN-`), so the scan matched nothing.

Scope check: in scope. The plan adds a module (`build-loop.sh`) and a shared library, changes `dev-cycle.sh`'s internal structure, adds a public CLI and a persisted data format (the brief machine lines and the `handoff:` marker commits).

## Dependency Map

Proposed:

```
skills/dev-cycle/SKILL.md (prose) ──CLI──▶ dev-cycle.sh --check-*      (exists)
                                  ──CLI──▶ build-loop.sh --status/...  (new, U4)
build-loop.sh ──source──▶ scripts/lib/dev-cycle-read.sh ◀──source── dev-cycle.sh
build-loop.sh ──subprocess──▶ dev-cycle.sh --check-brief / --check-branch
dev-cycle.sh  ──subprocess──▶ questions.sh open                         (exists: prior art)
```

There are no cycles. Stability runs the right way. The lib (pure predicates and an awk program) is the most stable layer. `dev-cycle.sh`'s check-mode output is the next most stable: it is already a published contract, consumed by the skill and pinned by 53 tests. `build-loop.sh` is the new, volatile consumer of both. Nothing stable depends on `build-loop.sh`.

The question to settle is whether **one consumer using two channels into the same module** (sourcing its internals and parsing its CLI output) is principled. The plan never states a rule for which pieces go through which channel. That gap is behind findings 1–3.

## Findings

#### 1. The brief's machine-line schema gets two readers in two scripts, plus a prose source for the branch

**Severity:** Coupling
**Location:** plan "Script interface" (brief machine lines) and step 3; `scripts/dev-cycle.sh:341-383` (`check_brief`); `skills/dev-cycle/SKILL.md:96-98`
**Move:** 2 (responsibility boundaries), 7 (coupling)
**Confidence:** High

After this plan, one file format (a build brief) is parsed in three places:

- `Status:` is read by `dev-cycle.sh check_brief`: the first unfenced line, the trailing CR dropped, an exact grammar, read at the default branch's commit.
- `Branch:`, `Policy:` and `Paths:` are read by a new reader inside `build-loop.sh`, which the plan says works by the same rules. That is a second copy of those rules.
- For the In flight check, the skill still takes the branch name from the brief's `## Branch` prose and passes it to `--check-branch` (SKILL.md:96).

Once `Branch:` exists, the cycle and the loop can disagree about which branch a brief owns. The "first unfenced line, CR, exact grammar" rules will also drift between the two awk bodies. `FENCE_AWK` alone, which is shared, does not stop that drift. The writer of these lines is prose (SKILL step 6), so no test connects the template the cycle writes to the grammar the script reads.

**Recommendation:**

- Put the machine-line reader in the lib, not in `build-loop.sh`: one function such as `brief_fields <sha> <path>` that emits `Status`/`Branch`/`Policy`/`Paths` in one awk pass over `git cat-file blob`. Document the grammar in one place, in the lib header, and have SKILL.md's brief template point to it.
- Leave `check_brief` untouched in U1 to keep the pure-move property. Add one test that `brief_fields` and `--check-brief` agree on `Status` across the T8 fixtures.
- Add a test that a brief built from SKILL.md's template parses.
- In U4, change In flight check 3 to take the branch from the `Branch:` line when present, with the prose `## Branch` section only as the legacy fallback.

#### 2. "Extract and also call as a subprocess" has no stated rule, and the extraction list misses `writable()`, so the cycle-owned-file list will be written twice

**Severity:** Coupling
**Location:** plan step 1, F12, T14; `scripts/dev-cycle.sh:250-257` (`writable`), `575-601` (default-branch resolution)
**Move:** 1, 3, 7
**Confidence:** High

The mix is defensible, but only under a rule the plan should state:

- **The lib** holds pure, git-free predicates and constants (`pathform`, `FENCE_AWK`/`oddwhy`, `INSTRUCTION_FILE`, `isbrief`). `build-loop.sh` needs these in-process over an arbitrary number of diff paths.
- **The subprocess** carries stateful verdicts that are already a published CLI contract (`--check-brief`, `--check-branch`), so brief state keeps one reader. `dev-cycle.sh` already calls `questions.sh` this way, which is prior art.

The plan's extraction list breaks that rule in both directions:

- `writable()` is pure (a regex over `DIGIT`/`SLUG`/`isbrief`) and is exactly the "cycle's own files" set that F12/T14 deny. Because it is not extracted, `build-loop.sh` will re-encode that list. It already differs: build-loop adds `dev-cycle.md`. When the cycle gains a bookkeeping file later, the loop's N-deny list silently lags.
- The default-branch resolution is not pure. It is top-level code that reads `$CHECK` and exits (`dev-cycle.sh:595-601`). Moving it into the lib is a refactor into a function, not a "mechanical move". It also must not carry the `exit` into a sourced file.

**Recommendation:**

- Write the channel rule into the plan's Approach.
- Add `writable` to step 1's extraction list. Define build-loop's N-list as `writable(lower(p)) || lower(p) == docs/dev-cycle.md` and add nothing else.
- Extract the resolution as `resolve_default_branch`, which sets `MAIN`/`MAIN_SHA`/`MAIN_BY_NAME` and never exits; each caller keeps its own exit policy.
- Add a sourcing-contract test (finding 6) so "no side effects at source time" is checked, not assumed.

#### 3. Two processes resolve `MAIN_SHA` independently, and the subprocess location is unpinned

**Severity:** Coupling
**Location:** plan "Approach", "Failure modes" ("the script calls `dev-cycle.sh --check-brief`"), Risks (re-exec cost); `scripts/dev-cycle.sh:737-738`
**Move:** 7
**Confidence:** Medium

Two separate problems come from the two-process design:

- **Two snapshots of main.** `build-loop.sh` resolves main and diffs `MAIN_SHA TIP`. The `dev-cycle.sh` child resolves main again and reads `Status` there. If main moves between the two, `--check` and `--start` report a brief state and a diff taken from different commits. `--merge`'s compare-and-swap covers this only if `build-loop.sh` resolves `MAIN_SHA` **before** the subprocess call; the plan does not fix the order.
- **Unpinned subprocess location.** The precedent `QS="$SCRIPT_DIR/questions.sh"` falls back to `~/.claude/scripts/`. If `build-loop.sh` copies that pattern, it can source the lib from one tree and run a `dev-cycle.sh` from another: a worktree's lib with the installed main's script.

**Recommendation:**

- State in the plan that `build-loop.sh` resolves `MAIN_SHA` first. After every `dev-cycle.sh` call it re-checks `refs/heads/<main>` and refuses with "main moved; retry" on a mismatch. `--merge`'s CAS stays as the final guard.
- Locate the child only as `"$SCRIPT_DIR/dev-cycle.sh"`, with no fallback, so the lib and the child always come from the same tree. Add a test that `build-loop.sh` never resolves a `dev-cycle.sh` outside its own `SCRIPT_DIR`: with `HOME` pointing at a decoy `~/.claude/scripts/dev-cycle.sh`, the decoy is never run.

#### 4. CLI surface departs from the check-mode conventions without saying so

**Severity:** Minor
**Location:** plan "Script interface"
**Move:** 3, 5
**Confidence:** High

`dev-cycle.sh`'s check modes share one shape: many arguments, exactly one `ok`/`skip`/`absent` line per argument, and exit 0 whenever every argument was answered. The `build-loop.sh` modes fit that shape to different degrees:

| Mode | Fits the check-mode shape? |
|---|---|
| `--policy` | Yes |
| `--status BRIEF…` | Yes, except that its 8-field positional `ok` line has no defined value for SHA and DATE when LOOP is `absent`, so positional parsing breaks |
| `--check BRIEF` | No: it takes one brief and prints **one `refuse` line per violation**, which breaks "one line per argument" |
| `--start` | Its exit status on refusal is unspecified |
| `--merge` | Exits 2 on refusal |

There are two more gaps:

- The new verb `refuse` is undefined against `skip`. The intended reading, inferred: `skip` means the input could not be read, and `refuse` means it was read and the answer is no.
- One script now mixes read-only modes with modes that write (a worktree, the main ref). `dev-cycle.sh`'s header promises "Read-only", and readers will assume the sibling does too.

**Recommendation:**

- Write the verb meanings (`skip` = unreadable, `refuse` = a verdict) into the script header.
- Define `-` as the placeholder for every positional field that does not apply.
- Make `--check` take exactly one brief and end with a single summary line (`ok BRIEF SHA POLICY` or `refuse BRIEF: N violation(s)`), so callers parse the last line.
- Give both writing modes the same exit rule: `--start` and `--merge` exit 2 on refusal, and the query modes exit 0.
- Split the header's mode list into "reads" and "writes".
- Optionally rename `--check` to `--check-merge` so it does not read as part of `dev-cycle.sh`'s `--check-*` family.

#### 5. Output scrubbing, a cross-cutting concern, stays private to `dev-cycle.sh`

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:82-125` (`scrub`, `DEV_CYCLE_SCRUBBED` re-exec); plan Risks
**Move:** 2
**Confidence:** Medium

Every byte `dev-cycle.sh` prints goes through `scrub`. `build-loop.sh` prints repo-derived text: branch names, `Paths:` entries in refuse lines, marker reasons, and the brief path in the start prompt. The plan defends each of these field by field (pathform, the reason charset, "without echoing raw bytes"). That works, but it is a second sanitisation policy that no test asserts as a whole. Output from the `dev-cycle.sh` child is already scrubbed. `build-loop.sh`'s own output is not.

**Recommendation:** Pick one approach and write it into the plan:

1. Recommended for U1's size budget: state the invariant "build-loop.sh prints only fixed text and tokens that passed `pathform` or the reason charset". Add a test that feeds a brief with control and bidi bytes in every machine line and asserts that none reach the output.
2. Extract `scrub` into the lib and wrap `build-loop.sh` the same way, under its own marker variable.

#### 6. Test split: the helper's location and the lib's own contract

**Severity:** Minor
**Location:** plan "Size estimate", "Test specification"; `test/lib/hermetic-env.bash`; `scripts/run-tests.sh:3-5`
**Move:** 3
**Confidence:** Medium

Splitting the tests by unit (`build-loop-read`/`-check`/`-merge.bats`) matches the modes and the review units, so keep it. Two things are off:

- **Helper location.** The shared helper goes to `test/scripts/build-loop-helpers.bash`, but the repo's shared test helpers live in `test/lib/` (loaded as `load ../lib/hermetic-env`). The throwaway-repo `setup` is the same one `dev-cycle.bats` uses, so the helper is not specific to build-loop.
- **No direct lib tests.** The lib gets two consumers but no test of its own. T25 shows that `dev-cycle.sh` didn't change. It does not show that the lib is safe to source: no top-level side effects, no `exit`, works under `set -euo pipefail`, safe to source twice. That is the property a second consumer relies on.

**Recommendation:**

- Put the helper in `test/lib/` under a name that does not claim it for build-loop, for example `test/lib/throwaway-repo.bash`. Do not retrofit `dev-cycle.bats` in this change.
- Add a short `test/scripts/dev-cycle-read-lib.bats`: source the lib in a `set -euo pipefail` subshell, check that sourcing defines only the expected names and prints nothing, and check that `resolve_default_branch` returns without exiting when no branch is found.
- Each new `.bats` file needs the `# @category` tag `run-tests.sh` requires.

#### 7. Lib header should name its consumers and the source idiom

**Severity:** Informational
**Location:** plan step 1; `scripts/health-check.sh:57-62`
**Move:** 3
**Confidence:** High

The existing libs are sourced through `$REPO_ROOT/scripts/lib/…` with `# shellcheck source=` hints, because those scripts act on this repo. `dev-cycle.sh` and `build-loop.sh` act on `$PWD`'s repo, so the plan correctly uses `$SCRIPT_DIR/lib/`. Through the `~/.claude/scripts` directory symlink this resolves to the repo's `scripts/lib/`. An implementer copying `health-check.sh` would get this wrong. A future `FENCE_AWK` tightening done for `dev-cycle.sh` also changes `build-loop.sh`'s gate. That is intended (one reader), but only safe if both suites run.

**Recommendation:** The lib's header comment should list its consumers (`dev-cycle.sh`, `build-loop.sh`) and say that changes run both test suites. Each sourcing line should use `$SCRIPT_DIR/lib/` with a `# shellcheck source=lib/dev-cycle-read.sh` hint.

#### 8. F11's existing import walk is not reusable as-is

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:414-456` (`imported_names`); plan F11
**Move:** 8
**Confidence:** Medium

`imported_names` walks `@`-imports in the **working tree**, while the gate must judge main's commit plus the loop's diff. So the plan is right not to extract it. If F11 is ever covered, it needs a commit-based variant rather than a move of this function.

**Recommendation:** None for this plan. In Q-103's F11 text, note "needs a commit-based import walk", so a later fix does not reach for `imported_names`.

## What Looks Good

- **A separate script, not a new `dev-cycle.sh` mode.** `--start`/`--merge` write a worktree and the main ref, and `dev-cycle.sh`'s contract is "Read-only: writes nothing" at 877 heavily reviewed lines. Adding modes there would break the invariant its reviewers relied on.
- **Rejecting duplication.** A second copy of `FENCE_AWK` is the drift decision log 69 exists to prevent.
- **Reusing the CLI for verdicts.** Taking `Status` and branch state from the published `--check-brief`/`--check-branch` keeps a single reader for brief state.
- **No new answer grammar.** Reusing `--check-answer` and the keep-or-drop entry (D3) avoids a second parser.
- **A one-way graph.** The dependency graph is acyclic and points from volatile to stable.
- **The extraction lands alone.** It is its own `refactor:` commit with the existing suite as characterization, and there is a defined fallback unit (U0).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Brief machine lines get two readers (plus prose for the branch) | Coupling | plan interface; `dev-cycle.sh:341-383`; SKILL.md:96 | High |
| 2 | No channel rule; `writable()` not extracted, so the N-list is duplicated; default-branch resolution is not a pure move | Coupling | plan step 1; `dev-cycle.sh:250-257, 575-601` | High |
| 3 | Two `MAIN_SHA` snapshots; subprocess location unpinned | Coupling | plan Approach; `dev-cycle.sh:737-738` | Medium |
| 4 | CLI: multi-line `--check`, undefined `refuse`, fields, exit codes, mixed read and write | Minor | plan Script interface | High |
| 5 | Scrub policy not shared | Minor | `dev-cycle.sh:82-125` | Medium |
| 6 | Helper outside `test/lib/`; no lib sourcing-contract tests | Minor | plan Size estimate | Medium |
| 7 | Lib header: consumers and source idiom | Informational | plan step 1 | High |
| 8 | `imported_names` is working-tree only | Informational | `dev-cycle.sh:414-456` | Medium |

## Overall Assessment

The structure is sound. A new script, a shared lib of pure readers, and the existing published check modes for brief state give an acyclic, stable-pointing graph, and every alternative (duplication, a new `dev-cycle.sh` mode, subprocess-only) is worse. Doing both extraction and subprocess calls is coherent, but only under a rule the plan does not yet state: the lib holds pure predicates, and the subprocess carries stateful verdicts that already have a CLI contract.

Applying that rule exposes the two real gaps:

- `writable()` belongs in the lib, or the cycle-owned-file list is written twice.
- The new brief machine lines belong in a lib reader, not in `build-loop.sh`, or the brief format gets two parsers. The skill would also keep a third source for the branch.

Both are fixable in the plan before any code exists, at roughly 20 extra lines in U1. The most important concern is finding 1: a persisted format with split readers is the kind of drift that the 38 review passes on `dev-cycle.sh` were spent closing.
