# Test Strategy: CRB direction-1 harness — the two fix commits (`c98343b..4624c5d`)

**Scope:** `git diff c98343b..HEAD -- scripts runs test docs/decisions docs/working` — commits `1d8ea67` ("close all 4 reds and 9 ambers from the iteration-1 review") and `4624c5d` ("close the 5 Incorrects the iteration-2 fact-check found"). 13 files, +912/−201. Commit `197eec6` is context only (already reviewed).
**Reviewed:** 2026-08-19
**Method:** read the implementations, then ran **45 mutations** in a throwaway git worktree at `4624c5d` — **21 caught, 24 survived**. Baseline in that worktree: the five CRB suites are **64/64 green** (37 → 64 tests; `crb-egress-verdict.bats` is new at 13 cases, `crb-disposable-clone.bats` +8, `crb-egress-config.bats` +6). Every "survives" below was executed, not inferred. The out-of-scope failing test (`crb-pipeline-to-benchmark.py`, uncommitted local edit) is not in these five suites and did not affect any result.
**Position:** terminal pass of a review-fix loop at its 3-iteration cap, immediately before a paid sweep.

## Test Conventions

Unchanged from the predecessor pass, plus one addition:

- **Framework:** bats, one file per unit under test in `test/`, `# @category fast`, a prose header explaining which rubric item the file answers.
- **Hermeticity:** fixtures are throwaway git repos in `BATS_TEST_TMPDIR`; no docker, no network.
- **Two Python-under-bats patterns:** `importlib` + monkeypatched roots (`run_mat`, `crb-disposable-clone.bats:57-83`), and the source-rewrite + `subprocess.run` CLI drive (`:179-201`).
- **New this commit — the extraction pattern, done right.** `scripts/crb-egress-verdict.sh` is a pure argument-in/verdict-out script with its own suite. This is the same move `crb-cell-status.py` made out of the same runner and it worked: it converted three unpinnable controls into 13 executing cases. It is the model for what still needs doing.
- **Also new — structural pins over `run-host.sh` source text.** Six cases in `crb-egress-config.bats:128-206` assert control-flow properties by `grep` and by small Python string-index assertions over the runner's source. These are a genuinely weaker instrument, and Section "Are the structural pins real?" below quantifies exactly how much weaker.

## What the commits genuinely closed

Stated first because it is substantial and because the negative findings below should not be read as "nothing improved."

| Predecessor gap | Mutation re-run | Result |
|---|---|---|
| G1 `scrub_object_store` untested | body → `return` (M1) | **CAUGHT** — `crb-disposable-clone.bats:219`. Also caught with only the `FETCH_HEAD` unlink removed (M2) and only the reflog-expire/`gc` removed (M3). |
| G5 leg 2 accepts HTTP 200 | `403\|000` → `200\|403\|000` (M5) | **CAUGHT** — `crb-egress-verdict.bats` "MUTATION: accepting HTTP 200…". |
| G6 leg 3 neutered | `!= "000"` → `-z` (M6) | **CAUGHT** — two cases fail, including the 403 cross-leg trap. |
| G7 `--internal` dropped from the runner | removed from `NET_CREATE_CMD` (M8) | **CAUGHT** — `crb-egress-verdict.bats` "the runner's own network create really carries --internal". The iteration-2 fact-check's specific complaint is fixed. |
| — | `internal-net` verdict always passes (M7) | **CAUGHT**. |
| R3 index hash | tamper (M12), missing file (M13), missing manifest field (M14), tar hash (M15) | **all four CAUGHT**. |
| R3 single layout owner | runner respells `.baselines/$id.tar` (M17) | **CAUGHT**. |
| R1 `--snapshot` deletion | `--snapshot` flag re-added (M42) | **CAUGHT**. |
| Audit hardening (pre-existing) | remotes (M31), nested repo (M32), `--no-reflogs` (M33), fsck-error (M34), foreign-commit note (M30), `artifact_index` symlinks (M37) | **all CAUGHT** — `crb-audit-clone.bats` is the strongest file in the set. |

**G2 is genuinely moot**, and nothing lost coverage in the `--snapshot` deletion: the `--verify`-absent-from-manifest guard (predecessor G3) survives on the `--verify` path, and `restore_clone`'s missing-`.git` guard (G4) is unchanged and still uncovered — neither was `--snapshot`-specific. `test/crb-disposable-clone.bats:328` pins the deletion in both directions (CLI rejects the flag; runner no longer names it).

## The question you asked: is the dead `exit 5` regression now caught?

**No. It is not caught, and the neighbouring mutation is worse than the original defect.** This is the highest-value gap in the suite.

Three mutations of `egress_leg` (`run-host.sh:220-234`), all executed:

```
M9   revert to the pipeline form (`bash "$VERDICT" … | sed` + PIPESTATUS)  → SURVIVED (64/64 green)
M10  `[ "$rc" -eq 0 ] || { echo "  (WARNING …)" >&2; }`  (no exit)          → SURVIVED (64/64 green)
M11  `out=$(bash "$VERDICT" "$1" "$2" || true)`  (rc never captured)        → SURVIVED (64/64 green)
```

I then executed the three forms in isolation against a failing verdict (`filter-blocks 200`):

```
current form :  FAIL printed, "(refusing to spend)" printed, exit=5     ← correct
M9  (old)    :  FAIL printed, no refusal line,              exit=1     ← the defect that was fixed
M10 (warn)   :  FAIL printed, "(WARNING)", then "REACHED PAID CELL", exit=0
```

M9 reproduces the exact iteration-2 defect with the suite green. M10 is strictly worse than anything this loop has found: a preflight that *prints* `FAIL … the allowlist is NOT filtering. The answer key is reachable from a review cell` and then **spends the sweep anyway**. Nothing in 64 tests moves.

The extraction succeeded at making the *rules* testable and did not make the *wiring* testable. `crb-egress-verdict.bats`'s own header admits the shape of this ("a case here mutates the STRING handed to the verdict script, which does not prove the runner hands it a truthful one") and then fixes only the one instance it names (`--internal`), by another grep. The general form is untouched.

## Are the structural pins real? (R2's exit-code branch, A3/A4's guard moves)

**Honest answer: they pin text, not behaviour, and I can defeat every one of them.** Six new cases in `crb-egress-config.bats:128-206` cover the runner. Executed:

| Pin | Mutation that defeats it | Result |
|---|---|---|
| "the audit's exit 2 is NOT treated as contamination" (`:128`) | `-gt 1` → `-gt 10` (M19b) — the grep is `grep -q 'audit_rc" -gt 1'`, and `-gt 10` **contains** `-gt 1` | SURVIVED. Exit 2 now falls through both branches and the cell is **banked as clean**. |
| same | `\|\| audit_rc=$?` → `\|\| true` (M18b) | SURVIVED. Every audit outcome, including a detected void, reads as clean. |
| same | `if [ "$audit_rc" -eq 1 ]; then` → `… -eq 1 ] && false; then` (M20b) | SURVIVED. The VOID branch never fires; the literal the grep wants is still there. |
| "MAX_ATTEMPTS is checked outside the result.json test" (`:142`) | keep the `if`, delete the `continue` (M21b) | SURVIVED. A6 is back: the cell re-runs forever. The pin asserts *nesting*, never *effect*. |
| "the sweep budget is checked before a cell" (`:160`) | `sys.exit(1 if total >= cap else 0)` → `sys.exit(0)` (M22); or the caller's `\|\|` branch stops exiting (M23) | both SURVIVED. A7 is back. The pin asserts the gate's *position*, never that it gates. |
| "a sweep that voided any cell does not exit 0" (`:176`) | `exit 6` → `: exit 6` (M25); `: > "$dest/CONTAINMENT_FAILED"` removed (M24) | both SURVIVED. Two `grep -q` for two tokens. |
| "PREFLIGHT_ONLY … stops before any paid cell" (`:181`) | `exit 0` → `: exit 0` (M26) | SURVIVED. The pin asserts where an *echo string* sits relative to the loop. |
| "proxy liveness is probed per cell" (`:196`) | probe warns instead of `exit 5` (M27) | SURVIVED. The pin asserts `in_cell_net` appears in the loop body. |

Eight of eight defeated. Two of the pins (M19, M21) *did* catch a cruder mutation and so are not worthless — but both catches were incidental to a literal string moving, and the refined variant walked through. The substring hole (`-gt 1` matching `-gt 10`) is the sharpest illustration: the pin is satisfied by a line that inverts the control it names.

This does not mean the pins should be deleted. They document intent and they catch wholesale deletion. It means **they must not be counted as coverage of the behaviour they are named after**, and the rubric should not close R2, A3 or A4 on their strength.

## Untested Paths Touched by the Change

Mutation results quoted per gap. **survived** = 64/64 stayed green with the control removed.

- **G1** — `runs/review-arms/crb-pipeline/run-host.sh:220-234` — `egress_leg`'s failure path: that a nonzero verdict is captured (`|| rc=$?`), reported, and **exits 5**. **Not covered.** M9/M10/M11 all survived; M10 was executed to completion and reaches the paid cell. *This is the gap the whole extraction was supposed to close and did not.* Severity **critical** (silent wrong answer: a sweep whose containment control has already announced its own failure still spends $10–40 per cell and produces numbers that look valid). Confidence **high** — executed three ways. Legibility-target **for-author**.
- **G2** — `run-host.sh:632-651` — the audit's tri-state mapping (`audit_rc` 0 clean / 1 VOID / >1 abort). **Not covered by anything executing.** M18b, M19b, M20b all survived; each collapses a *different* pair of states, and M19b/M18b both end in a contaminated or unchecked cell being **banked as clean**. Severity **critical**. Confidence **high**. Legibility-target **for-author**.
- **G3** — `run-host.sh:493-496` — the `MAX_ATTEMPTS` skip's `continue`. **Not covered** (M21b survived). This is A6, fourth round; the fix moved the guard to the right place and left its effect unpinned. Severity **high** (unbounded re-spend, invisible to `SWEEP_BUDGET` because a died-early cell ledgers `cost_usd: 0`). Confidence **high**.
- **G4** — `run-host.sh:407-435` (`sweep_spend_ok` body) and `:437` (its call) — that the gate actually halts. **Not covered** (M22, M23 survived). Severity **high** (money). Confidence **high**.
- **G5** — `run-host.sh:244`, `:249`, `:251`, `:201-206` — the *observations* handed to the verdict script. The verdicts are now pinned; the probes are not. Executed:
  - M39, `filter-blocks` probes `https://nonexistent.invalid/` instead of `github.com` → 000 → leg **passes** with the allowlist wide open, and leg 1 still passes. **SURVIVED, and fails silently.**
  - M38, the `plain-http` leg probes `https://` → leg 2b becomes a duplicate of leg 2 and the plain-HTTP path (A7's entire remediation) is never exercised. **SURVIVED, and fails silently.**
  - M40, `in_cell_net` stops exporting `HTTP(S)_PROXY` → the refusal legs pass vacuously. **SURVIVED**, but self-limiting: leg 1 then returns 000 and halts the sweep loudly. Severity of this one is lower for that reason, and the leg-ordering comment at `:242-243` is why.
  - M41, `no-direct-route` runs *through* `in_cell_net` → **SURVIVED**, also self-limiting (403 ≠ 000 halts the sweep).
  Severity **high** for M38/M39, **medium** for M40/M41. Confidence **high**. Legibility-target **for-author**.
- **G6** — `run-host.sh:645` — the `CONTAINMENT_FAILED` marker write, which `write_run_meta` (`:356`) and the exit-6 gate (`:693`) both read. **Not covered** (M24 survived). Carried unchanged from the predecessor's G13; the commit added a *reader* (`exit 6`) without adding a test for the *writer*, so the new exit code inherits the old hole. Severity **high**. Confidence **high**.
- **G7** — `run-host.sh:697-699` — the `exit 6` on a voided sweep. **Not covered** (M25 survived). Severity **medium**.
- **G8** — `run-host.sh:294-300` — `PREFLIGHT_ONLY`'s `exit 0`. **Not covered** (M26 survived). Severity **medium** — the failure is "a $0 command silently becomes a paid sweep", which is exactly the surprise a pre-sweep operator cannot afford.
- **G9** — `run-host.sh:522-529` — the per-cell proxy-liveness probe's `exit 5`. **Not covered** (M27 survived). Severity **medium** (A6's amplifier: a dead proxy plus a swallowed probe is the loop-forever state).
- **G10** — `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:26` and `:16` — `ConnectPort` and `Allow` are pinned by **presence, not exclusivity**. M28 (`ConnectPort 80` + `ConnectPort 8080` added) and M29 (`Allow 10.0.0.0/8` added) both **SURVIVED**. Unchanged from the predecessor's G8 — the commit rewrote the *comment* that the fact-check found wrong and left the *test* alone. Severity **medium**. Confidence **high**.
- **G11** — `scripts/crb-materialize.py:241-242` — the `git symbolic-ref -d refs/remotes/origin/HEAD` heal inside `scrub_object_store`. M4 (that call alone deleted) **SURVIVED** while M2/M3 were caught, so the new non-vacuity test covers two of the function's three actions. A dangling `refs/remotes/origin/HEAD` produces an `^error:` from `git fsck`, which `crb-audit-clone.sh:78-81` turns into a VOID — i.e. this is a *false-positive-void* path, the same class as the shallow-clone gap. Severity **medium**. Confidence **medium** (I did not execute the end-to-end false void; the code path is clear from `:78-81`).
- **G12** — `scripts/crb-materialize.py:271-275` — `artifact_index`'s `.git` exclusion. M35 **SURVIVED**, unchanged from the predecessor's G15: the fixture's `.git` still contains no `.md`/`.json`, so the test at `:154` that claims to pin "skips .git" still passes with the filter removed. Severity **low-medium** (a `.git`-polluted index makes the harvest's "the pipeline wrote this" wrong for the whole sweep). Confidence **high**.
- **G13** — `scripts/crb-harvest-artifacts.py:118-122` — the `MAX_FILES`/`MAX_TOTAL_BYTES` cap-reached branch. M36 **SURVIVED**, unchanged from the predecessor's G9. Severity **low**.
- **G14** — `test/crb-disposable-clone.bats:169-174` (the test itself) — `CLI --restore --dry-run destroys nothing` still runs the **unpatched** script, so it resolves `fixture` against the real `external/crb-eval` and the real `runs/review-arms/crb/instances.json` while asserting a `BATS_TEST_TMPDIR` path. Unchanged from the predecessor's G17; the commit added the index guards *in front of* the restore, which makes the test pass for one more incidental reason rather than fewer. Severity **medium** (test hygiene; would destroy a live `fixture` clone and still pass). Confidence **high**.
- **G15** — `scripts/crb-materialize.py:312-315` — the index's atomic `.part` publish. M16 (non-atomic write) **SURVIVED**. Listed for completeness; see What NOT to Test. Severity **low**.
- **G16** — carried unfixed from the predecessor and untouched by these commits: `crb-audit-clone.sh:60` on a **shallow** clone (predecessor G14), and the tag-outside-ancestry variant (predecessor G18). Severity **medium** / **low** respectively.

## Recommended Tests

#### The preflight halts the sweep when a leg fails — executed, not grepped

**Closes gaps:** G1, G5 (M38/M39 half), G8, G9
**Type:** integration (source-extraction + bats)
**Priority:** **high — this is the one to write before the sweep**
**File:** `test/crb-egress-preflight.bats` (new), against a new `scripts/crb-egress-preflight.sh`
**What it verifies:** that a failing leg stops the process with status 5 and the refusal line, and that each leg is handed the observation it claims to be handed.
**Key cases:**
- With a stub `$VERDICT` on `PATH` that exits 1: the preflight exits **5**, prints `refusing to spend`, and the marker file the stub would write for a later leg is **absent** (proves it stopped there, not merely that it printed). This is M9/M10/M11.
- With a stub that exits 0 for every leg: exit 0 and all five legs invoked, in the order `internal-net, api-reachable, filter-blocks, plain-http, no-direct-route` — the order is load-bearing per `:242-243` and is currently asserted nowhere.
- With `docker` stubbed to log its argv: the `filter-blocks` probe URL is `https://github.com/`, the `plain-http` probe URL is `http://github.com/` (M38/M39), and the `no-direct-route` invocation carries **no** `HTTP_PROXY`/`HTTPS_PROXY` env while the other three do (M40/M41).
- `PREFLIGHT_ONLY=1`: the process exits 0 **and** the docker-argv log contains no `-p "/code-review` invocation (M26).

**Setup needed:** the extraction — move `in_cell_net`, `egress_leg` and the five leg invocations from `run-host.sh:199-252` and `:294-300` into `scripts/crb-egress-preflight.sh`, sourced by the runner. This is the same move `crb-egress-verdict.sh` and `crb-cell-status.py` already made from this file, and it is the *second half* of the move this commit started: the verdicts moved, the wiring did not. Plus a `PATH` shim for `docker` (`test/round-log-functions.bats` is the pattern). Estimated: the extraction is ~40 lines relocated; the suite is ~8 cases.

#### The cell loop's decisions, driven with docker stubbed

**Closes gaps:** G2, G3, G4, G6, G7
**Type:** integration
**Priority:** **high**
**File:** `test/crb-run-host-cell-loop.bats` (new — there is still **no executing test of `run-host.sh`**)
**What it verifies:** the five money-and-evidence decisions the structural pins only describe.
**Key cases:**
- Audit stub exits **2** → the runner exits **4**, no `CONTAINMENT_FAILED` is written, `result.json` is not rewritten (M19b, M18b).
- Audit stub exits **127** (docker's own "command not found") → same as above; asserts the branch is `>1`, not `==2`.
- Audit stub exits **1** → `$dest/CONTAINMENT_FAILED` exists, `result.json` gains `subtype: containment_failed`, `run-meta.json`'s `voided_cells` names the slug, and the script exits **6** (M20b, M24, M25 in one case).
- Audit stub exits **0** → no marker, exit 0.
- `attempts.jsonl` pre-seeded with `MAX_ATTEMPTS` lines → the review container is **never launched** for that slug (M21b). Assert on the docker-argv log, not on a message.
- `attempts.jsonl` summing over `SWEEP_BUDGET` → the runner exits **2** and the review container is **never launched** (M22, M23).
- Proxy-liveness stub failing → exit **5**, review container never launched (M27).

**Setup needed:** `PATH` shims for `docker` and for `python3` where it invokes the project's own scripts; a fixture `OUT` dir and a one-slug manifest. This is the largest item in the plan and the only way G2/G3/G4/G6/G7 become testable at all. It is also the item the predecessor recommended and this loop deferred (see A8 below).

#### `ConnectPort` and `Allow` are exclusive, not merely present

**Closes gaps:** G10
**Type:** unit (config pin)
**Priority:** medium — but it is ~6 lines and closes a carried gap
**File:** `test/crb-egress-config.bats:45` (strengthen in place)
**What it verifies:** the tunnel cannot be widened by *addition*, which is how config controls actually rot.
**Key cases:**
- `grep -cE '^[[:space:]]*ConnectPort' tinyproxy.conf` is exactly `1` and that line is `443` (M28).
- `grep -cE '^[[:space:]]*Allow' tinyproxy.conf` is exactly `1` and equals `$EGRESS_SUBNET` (M29 — today the subnet round-trip at `:52-53` breaks incidentally on a second `Allow`, which is luck).

**Setup needed:** none.

#### `scrub_object_store`'s third action

**Closes gaps:** G11
**Type:** unit
**Priority:** medium
**File:** `test/crb-disposable-clone.bats:219` (extend the existing non-vacuity case)
**What it verifies:** the `origin/HEAD` heal, which M4 showed is the one third of the function still unpinned — and whose loss produces a *false* void, i.e. the whole sweep discarded.
**Key cases:**
- Fixture with a dangling `refs/remotes/origin/HEAD` (write the symref, then remove its target ref) → `git fsck` emits `^error:` **before** the scrub and does not **after**.
- End-to-end: the same fixture snapshotted → restored → `crb-audit-clone.sh` exits 0 (and exits 1 with the heal removed, naming `cannot certify containment`).

**Setup needed:** none beyond `$AUDIT`, already exported at `:32`.

#### `artifact_index` really excludes `.git`

**Closes gaps:** G12
**Type:** unit
**Priority:** medium
**File:** `test/crb-disposable-clone.bats:154` (strengthen in place)
**Key cases:** write `$CLONE/.git/hooks/notes.md` and `$CLONE/.git/x.json` before indexing; assert neither appears (M35). Today the filter and no filter give the same answer.
**Setup needed:** none.

#### The `--dry-run` test stops resolving against the live tree

**Closes gaps:** G14
**Type:** unit (test hygiene)
**Priority:** medium
**File:** `test/crb-disposable-clone.bats:169-174` (rewrite in place)
**Key cases:** drive the *patched* copy (the harness already exists at `:179-201`) with `--restore fixture --dry-run` after a successful snapshot and a deliberately dirtied clone → exit 0, `Nothing touched`, and `f.txt` still holds the dirtied value. Add one assertion that `external/crb-eval/fixture` does not exist before or after.
**Setup needed:** none — reuse the existing patched-copy block.

#### Harvest stops at the total-size and file-count caps

**Closes gaps:** G13
**Type:** unit
**Priority:** low-medium
**File:** `test/crb-harvest-artifacts.bats`
**Key cases:** 501 small `.md` files → `harvested 500`, stderr names the cap, exit 0; the byte cap reached with the per-file cap unhit → copy stops, earlier files present. Consider an env override for the caps so the fixture stays small.
**Setup needed:** none.

## What NOT to Test

- **G15 (atomic index publish).** Verifying `.part`-then-`replace` needs crash injection between two syscalls. The rename is one line and reviewers can read it; a test would pin the implementation, not the property. Skip.
- **G16, tag-outside-ancestry.** The descent check's code path is already exercised by the orphan-commit case (`crb-audit-clone.bats:102`); a tag variant would pin git's `rev-list --all` behaviour, not this script's. Skip unless the audit grows a per-refspace filter.
- **G16, shallow clone.** *Do not skip this one, but do not write it either* — see Escalate. It is a false-positive-void control (a wrong result voids **every** cell of a paid sweep) and it was deleted with `crb-containment-reset.bats`. It needs a `file://` fixture repo, which is ~30 lines recoverable from `git show 197eec6^:test/crb-containment-reset.bats`. I rank it below the two high-priority items above only because those two protect money and this one protects a re-run.
- **Anything docker-shaped, in bats.** The images, the `--internal` network and tinyproxy stay out of the hermetic suite. Both high-priority recommendations above stub docker; neither asks for a real container. That boundary is drawn correctly and both commits respect it.
- **The verdict script's rules.** `crb-egress-verdict.bats` is done. Four of my mutations against it were caught and I found none that survives. Adding cases there is the tempting, wrong move — the gap moved one layer out, to the caller.

## Coverage Gaps Beyond Current Scope

**1. A8 — "run-host.sh has no executing test" is *no longer* the right scope call, and the loop being at its cap is the reason, not an excuse.** The predecessor called it a scope call bigger than the commit, and that was right *then*: at `197eec6` the runner's controls were mostly inline and would have moved anyway. It is not right now, for three reasons I can name. (a) The commits added **six new structural pins** over the runner and I defeated **eight of eight**, so the rubric is about to close R2, A3, A4, A9 and A2 on instruments that do not hold. (b) The single defect this loop's iteration 2 found by execution — the dead `exit 5` — is still uncaught, and its neighbour (M10) is worse than the original. (c) The next action is a paid sweep, which is precisely when "the control announced its own failure and we spent anyway" costs real money and produces numbers that look valid. **The minimum executable harness is smaller than it sounds:** one `PATH` shim directory containing a `docker` stub that logs argv and returns a scripted exit code, plus a one-slug fixture manifest and `OUT` dir. That is ~40 lines of `setup()`. With it, `test/crb-run-host-cell-loop.bats` and `test/crb-egress-preflight.bats` cover G1–G9 — nine of my sixteen gaps, including all four rated critical or high on money. My recommendation is: **do not run the paid sweep until the two high-priority suites above exist**, or, if that is unacceptable, run `PREFLIGHT_ONLY=1` first and read its output with a human eye, treating the preflight's *printed* verdicts rather than its *exit code* as the evidence — because G1 means the exit code is exactly the thing not pinned.

**2. Extraction is half-done, and the second half is the cheap half.** `crb-cell-status.py` and now `crb-egress-verdict.sh` both moved *decisions* out of `run-host.sh`; neither moved the *wiring* that acts on them. The runner is now 700 lines of which the untestable part is almost entirely the acting-on. `scripts/crb-egress-preflight.sh` and a `run_cell()` function in a sourced file would leave `run-host.sh` as argument parsing and a loop.

**3. The grep-pin substring hazard is repo-wide, not local.** `grep -q 'audit_rc" -gt 1'` matching `-gt 10` is a class, not an instance. Any `grep -q` pin over a numeric comparison in this repo has it. A cheap mitigation for the pins that stay: anchor them (`grep -qE 'audit_rc" -gt 1$'` or match the whole line).

**4. Carried unfixed and still true:** `external/crb-eval/.baselines` does not exist and no manifest record carries `baseline_sha256`, so the first action of the next sweep is still the no-baseline skip branch → `exit 3`. The commit made the remedy safe (`--slug <id> --force` re-materializes rather than laundering) which was the important half; the state itself is unchanged and is a pre-sweep operator action, not a test.

**5.** `runs/review-arms/crb-pipeline/` remains simultaneously a source directory (`docker/`) and the sweep's output root — the predecessor's item 4, unchanged.

## Summary

The two commits did real work in my domain: **21 of 45 mutations are now caught, and every single mutation the predecessor named as surviving is caught today** — `scrub_object_store` (M1–M3), the two neutered egress verdicts (M5, M6), the dropped `--internal` (M8), plus all four new index-hash guards and the `--snapshot` deletion. `scripts/crb-egress-verdict.sh` + its 13-case suite is the right pattern applied correctly, and `crb-audit-clone.bats` remains the strongest file in the set (six for six). The highest-value test still missing is the one that answers the question this pass was asked: **nothing catches a regression of `egress_leg`'s failure path** — reverting it to the pipeline form that made `exit 5` dead code leaves 64/64 green, and the adjacent one-token mutation that turns the halt into a warning leaves 64/64 green while I executed it reaching the paid cell with the preflight having already printed `the allowlist is NOT filtering`. The main residual risk is not that the controls are wrong — read as source they are right, and better than at `197eec6` — but that **the six new structural pins over `run-host.sh` will be read as coverage when they are not**: I defeated all eight I tried, including two by exploiting `grep`'s substring match on a numeric comparison. Open questions the enumeration surfaced: (a) is the *observation* half of each preflight leg (which URL, with or without proxy env) considered in scope for pinning, given that M38 and M39 silently void the leg's meaning while its verdict test stays green; (b) `scrub_object_store`'s `origin/HEAD` heal (M4) is now the only third of that function unpinned, and its loss produces a *false* void of every cell — is that worth one more case, or is it a pre-`197eec6` migration artifact that can be retired outright?

## Goal-Alignment Note
- Answered: yes — 45 mutations executed on a throwaway worktree, all three predecessor survivors re-run and confirmed closed, the `egress_leg` question answered by execution (**not caught**), the structural pins assessed by defeating eight of eight, A8 re-called with a concrete minimum harness. Report at `docs/reviews/test-strategy-review.md`.
- Out of scope: `197eec6` itself (context only); the pre-existing `crb-pipeline-to-benchmark.py` failure (uncommitted local edit, not in these five suites, confirmed not to affect any mutation result); anything requiring a real docker daemon; the fact-check's prose/doc-accuracy findings, used as input rather than re-verified.
- Escalate: (1) **The loop is at its cap with a critical, executed gap open (G1/G2).** My recommendation is to block the paid sweep on the two high-priority suites, or at minimum on the `egress_leg` halt case alone — it is ~15 lines against a stub verdict script and closes the single worst finding. This is a decision above my scope. (2) The rubric should **not** close R2, A3, A4, A9 or A2 on the strength of `crb-egress-config.bats:128-206`; those pins are text-level and I defeated every one. Downgrade them to "documented, not covered." (3) The shallow-clone false-positive-void control (deleted with `crb-containment-reset.bats`, still gone) voids an entire paid sweep if it regresses and has now survived two review loops without an owner.
