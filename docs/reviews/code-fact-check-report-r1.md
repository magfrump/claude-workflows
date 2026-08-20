# Code Fact-Check Report

**Repository:** `/workspace`
**Commit:** 4624c5d
**Also under review:** 1d8ea67 (this pass checks the two fix commits `c98343b..HEAD` together)
**Replication:** k=1 — TERMINAL pass of a review-fix loop at its 3-iteration cap
**Scope:** `git diff c98343b..HEAD -- scripts runs test docs/decisions docs/working` (13 files, +912/−201). Commit `197eec6` and everything earlier on the branch is context only, not under review.
**Checked:** 2026-08-19
**Total claims checked:** 28 (27 numbered; Claim 11 split into 11a/11b on verdict divergence)
**Summary:** 23 verified, 3 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

**Hallucination-pattern log consulted:** `docs/reviews/hallucination-patterns.md` (2 entries, both "a specific measured value quoted from a checked-in artifact set that does not contain it"). This pass checks four such measured values in `4624c5d`'s commit message — the `440 (+1)` total, the `+26` correction to `1d8ea67`, the pre-existing-failure attribution, and the `--internal` mutation result. **All four were recomputed from the artifact set and all four hold** (Claims 22, 23, 24, 25). No entry appended: the one Incorrect verdict below is a dead-guarantee comment, not a fabricated symbol.

---

## Headline: is there a mechanism error number six?

**Yes — one, and it is small.** The brief named five consecutive rounds in which a fix round credited a flag, call, or deletion with an effect it does not have, and asked whether `1d8ea67`+`4624c5d` produced a sixth. It did, at `run-host.sh:586-587`:

> "Ledger this attempt's spend IMMEDIATELY, before the audit **and before any path that can leave the loop**."

The ledger is genuinely before the audit and before the artifact harvest's `exit 4` — both verified. But the block *immediately above it* (`run-host.sh:567`, the result-extraction heredoc) is the one heredoc in the cell body with **no `|| true`**, so under this file's `set -euo pipefail` a nonzero exit there kills the sweep **after the container was paid for and before the attempt is ledgered**. Reproduced by execution (Claim 11b). It is the same shape as the prior five — an absolute guarantee asserted about a relocation that is only relative — but the exposure is one narrow failure mode (a write error on `result.json`/`review.md`) rather than a dead code path.

**Everything else the two commits claim, verified — including all five things the iteration-2 fact-check called Incorrect.** `exit 5` is now reachable and a passing leg now continues (executed, Claim 8); the `--internal` mutation is now caught (executed, Claim 20 — suite goes red on exactly that case); `baseline_paths` really is the one definition now (exhaustive grep, Claim 18); the harvest's recommended remedy really does produce an index (executed, Claim 16); the Dockerfile's needs-vs-attempts distinction is exact (Claim 6).

**Two things the orchestrator should see before authorizing spend:**

1. **A different mutation of the same control still survives the suite** (Claim 14, executed). The `internal-net` verdict is a glob, `*--internal*`. Changing `run-host.sh`'s create to `docker network create --internal=false …` leaves **13/13 green in `crb-egress-verdict.bats` and 0 failures in `crb-egress-config.bats`**, and docker accepts `--internal=false` as "not internal". The brief asked for this explicitly; it is the answer. (Mutating the *subnet* instead is caught — `crb-egress-config.bats` case 16 goes red.)
2. **One Stale comment from iteration 2 was not closed and `4624c5d` does not claim to have closed it**: `run-host.sh:208` still says "PROVE the allowlist, **three ways**" over five legs (Claim 7).

---

## Claim 1: "`PREFLIGHT_ONLY=1` runs those five legs plus the auth/skill preflight (which bills one turn, not zero) and then stops."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:51-52`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the leg inventory, the presence of a billed auth turn, and the stop point; does not establish the legs' runtime outcomes (no docker in this sandbox) or that the auth turn's cost is nonzero in dollars.

This is the fix for iteration-2 Claim 1 ("runs exactly that and stops"). Five legs run, then the auth/skill preflight, then the stop:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:238-252
egress_leg internal-net "$NET_CREATE_CMD"
egress_leg api-reachable "$(in_cell_net '...https://api.anthropic.com/v1/models || echo 000')"
egress_leg filter-blocks "$(in_cell_net '...https://github.com/ || echo 000')"
egress_leg plain-http "$(in_cell_net '...http://github.com/ || echo 000')"
egress_leg no-direct-route "$(docker run --rm --network "$EGRESS_NET" ... || echo 000')"
```

The auth preflight is a real headless invocation, and the stop sits after it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:284-290
if [ -n "$PREFLIGHT_ONLY" ]; then
  ...
  echo "auth and skill registration confirmed. No cell ran; only the preflight's"
  echo "own auth turn was billed. Re-run without PREFLIGHT_ONLY to sweep."
  exit 0
fi
```

The doc now matches the runner's own output.

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:51-52`, `runs/review-arms/crb-pipeline/run-host.sh:238-252`, `runs/review-arms/crb-pipeline/run-host.sh:265-290`

---

## Claim 2: "R6 did not dissolve — it moved. Every clone materialized before this change lacks a baseline, so `run-host.sh` skips all of them and exits 3, which is R6's exact symptom."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:71-77`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the on-disk precondition state and the exit-3 branch as written; does not establish that the sweep would exit 3 in a live run (the exit is reached only after the docker preflights, which cannot run here).

Executed against disk. The baseline directory does not exist and no manifest record carries the pin:

```
$ ls external/crb-eval/.baselines
ls: cannot access 'external/crb-eval/.baselines': No such file or directory
$ python3 -c "...json.load(open('runs/review-arms/crb/instances.json'))..."
5 records; with baseline_sha256: 0
with baseline_index_sha256: 0
```

Every instance therefore fails the pre-cell precondition and is counted `skipped_bad`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:449-454
  if [ ! -f "${_bl[0]:-/nonexistent}" ] || [ ! -f "${_bl[1]:-/nonexistent}" ]; then
    echo "$id: no baseline — rebuild the clone and its baseline with:" >&2
    ...
    skipped_bad=$((skipped_bad+1)); continue
  fi
```

which reaches the exit the decision names:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:682-685
if [ "$ran" -eq 0 ] && [ "$skipped_bad" -gt 0 ]; then
  echo "NO CELL RAN and $skipped_bad instance(s) were unusable — not a clean sweep." >&2
  exit 3
fi
```

The remedy the decision names (`--slug <id> --force`) is the one that writes a baseline — see Claim 16.

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:71-77`, `runs/review-arms/crb-pipeline/run-host.sh:449-454`, `runs/review-arms/crb-pipeline/run-host.sh:682-685`, `runs/review-arms/crb/instances.json`, command run in `/workspace`, exit 0, 2026-08-20T00:33Z

---

## Claim 3: "Note one residual gap the test suite cannot close: the `internal-net` leg asserts the network-create command, but whether docker honours `--internal` is itself only observable at runtime."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:89-93`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two things the note asserts — that the leg's subject is the command string and that docker's honouring of the flag is unobservable here. It does not assert that the string assertion is *strict*; that separate question is Claim 14, where a surviving mutation is recorded.

The leg's input is the literal command line, not a network state:

```bash
# scripts/crb-egress-verdict.sh:23-25 (usage contract)
# `<observed>` is the curl `%{http_code}` for the http legs ..., or the literal
# network-create command line for the `internal-net` leg.
```

and it is handed exactly the string the runner ran:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:176-177, :238
  NET_CREATE_CMD="docker network create --internal --subnet $EGRESS_SUBNET $EGRESS_NET"
  $NET_CREATE_CMD >/dev/null
egress_leg internal-net "$NET_CREATE_CMD"
```

No test in the repo starts a docker network (paraphrased — no quote available because the claim covers the absence of code: `grep -rn 'docker network' test/` returns only string assertions in `test/crb-egress-verdict.bats:36,41` and the two greps at `:138-148`, none of which invoke docker).

**Evidence:** `docs/decisions/034-…:89-93`, `scripts/crb-egress-verdict.sh:23-25`, `runs/review-arms/crb-pipeline/run-host.sh:176-177`, `runs/review-arms/crb-pipeline/run-host.sh:238`

---

## Claim 4: "**egress**, five legs, all of which must pass or the sweep exits 5 before spending anything"

**Location:** `docs/working/crb-direction1-setup.md:98-99`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit code and the fail-closed ordering (all five legs precede the paid auth preflight); does not establish the legs' runtime verdicts, which require docker.

This is the fix for iteration-2 Claim 8 (`exit 5` was dead — the sweep died at status 1). Re-executed against the current `egress_leg` extracted verbatim from `run-host.sh:220-234` and run under the same `set -euo pipefail`:

```
--- FAILING leg (internal-net without --internal) ---
  FAIL internal-net: network was created WITHOUT --internal — containers would route directly.
  (refusing to spend — egress leg 'internal-net' failed)
exit=5
--- FAILING leg (no-direct-route observed 200) ---
  FAIL no-direct-route: reached a non-allowlisted host (HTTP 200) with NO proxy env — the network is not internal.
  (refusing to spend — egress leg 'no-direct-route' failed)
exit=5
```

"Before spending anything" holds: all five `egress_leg` calls sit at `run-host.sh:238-252`, ahead of the auth preflight's `docker run` at `:265`, which is the first billed call in the file.

**Evidence:** `docs/working/crb-direction1-setup.md:98-99`, `runs/review-arms/crb-pipeline/run-host.sh:220-252`, `docs/reviews/execution-logs/2026-08-19-r1-egress-leg.log` — cmd `bash <harness> <leg> <observed>`, cwd `/workspace`, exit 5 on both failing legs, 2026-08-20T00:29Z

---

## Claim 5: "It is **not quite $0**: the five egress legs are free, but the auth/skill-registration preflight is a real headless invocation and bills one turn."

**Location:** `docs/working/crb-direction1-setup.md:120-124`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claim that `PREFLIGHT_ONLY=1` bills and that the egress legs do not; does not establish the dollar amount of the billed turn, nor that the five legs are literally free of every cost (they start containers, which cost time, not API spend).

The preflight is a real invocation with the key attached:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:265-276
preflight=$(docker run --rm -u node -e ANTHROPIC_API_KEY \
  --network "$EGRESS_NET" \
  ...
    -p "List the names of your available skills, comma separated. Nothing else." \
    --model "$MODEL" --output-format json 2>&1) || true
```

and its success predicate requires a turn to have happened:

```python
# runs/review-arms/crb-pipeline/run-host.sh:281-282
if d.get("num_turns", 0) < 1 or "log in" in low or "logged in" in low:
    sys.exit(f"  auth failed: {r[:200]!r}")
```

The five egress legs pass no `ANTHROPIC_API_KEY` and issue no `claude` invocation (paraphrased — no quote available because the claim covers the absence of code across `run-host.sh:238-252`: none of the five lines contains `-e ANTHROPIC_API_KEY`, and all four container legs use `--entrypoint bash`).

**Evidence:** `docs/working/crb-direction1-setup.md:120-124`, `runs/review-arms/crb-pipeline/run-host.sh:238-252`, `runs/review-arms/crb-pipeline/run-host.sh:265-290`

---

## Claim 6: "Baking the CLI means a running cell NEEDS only one reachable host … It will still ATTEMPT others — this repo's own `devcontainer-config/egress/base.txt` lists claude.ai, console.anthropic.com, sentry.io, statsig.com and registry.npmjs.org, and nothing here disables the autoupdater or telemetry."

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the host list, the absence of autoupdater/telemetry disabling in this Dockerfile, and the single-entry allowlist; does not establish which endpoints a running CLI actually contacts (requires docker).

This is the fix for iteration-2 Claim 28 (the "exactly ONE reachable host" wording surviving here after being corrected in 034). The named list is exactly the file's contents besides `api.anthropic.com`:

```
# devcontainer-config/egress/base.txt:7-14
api.anthropic.com
claude.ai
console.anthropic.com
sentry.io
statsig.com
...
registry.npmjs.org
```

The Dockerfile sets no autoupdater or telemetry variable (paraphrased — no quote available because the claim covers the absence of code: the file's only `ENV`-adjacent directives are `ARG NODE_TAG`, `ARG CC_VERSION`, and `LABEL crb.cc_version`; there is no `DISABLE_AUTOUPDATER`, `DISABLE_TELEMETRY`, or `CLAUDE_CODE_*` setting anywhere in `runs/review-arms/crb-pipeline/docker/`).

"lets the allowlist hold a single entry" is exact — one non-comment line:

```
# runs/review-arms/crb-pipeline/docker/egress-allowlist:9
^api\.anthropic\.com$
```

**Evidence:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-14`, `devcontainer-config/egress/base.txt:7-14`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:9`

---

## Claim 7: "Egress preflight: PROVE the allowlist, three ways"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:208`
**Type:** Configuration / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the count in this section header only; every other statement of the leg count in the branch was updated and is correct.

Carried unfixed from iteration-2 Claim 11. The header still says three:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:208
# ── Egress preflight: PROVE the allowlist, three ways ───────────────────────
```

but five legs follow it, at `run-host.sh:238-252` (quoted in Claim 1). `git log -S'PROVE the allowlist, three ways'` attributes the line to `197eec6`, which is context-only for this pass; `4624c5d`'s commit message does not claim to have fixed it, so this is an open carry rather than a refuted claim.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:208`, `runs/review-arms/crb-pipeline/run-host.sh:238-252`

---

## Claim 8: "the assignment is guarded with `|| rc=$?` rather than relying on a pipeline's exit status at all" (and, by implication, that `exit 5` now runs)

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:221-234`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both directions — a failing leg reaches `exit 5` and a passing leg does not — for a directly-invoked leg under `set -euo pipefail`. Does not cover the case where the *observed* argument's own command substitution (`$(in_cell_net …)`) fails, which is a separate path (see the note below).

The rewritten body:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:231-234
  local out rc=0
  out=$(bash "$VERDICT" "$1" "$2") || rc=$?
  printf '%s\n' "$out" | sed 's/^/  /'
  [ "$rc" -eq 0 ] || { echo "  (refusing to spend — egress leg '$1' failed)" >&2; exit 5; }
```

`local out rc=0` is on its own line, so `local`'s own exit status cannot mask the substitution's — the `out=$(…)` assignment is a separate statement in a `||` list, where errexit is suppressed and `$?` is readable. Executed both directions:

```
--- PASSING leg (internal-net with --internal) ---
  ok  network created --internal
AFTER-LEG-REACHED
exit=0
--- FAILING leg (internal-net without --internal) ---
  FAIL internal-net: network was created WITHOUT --internal — containers would route directly.
  (refusing to spend — egress leg 'internal-net' failed)
exit=5
```

One behaviour worth recording rather than verdicting: the verdict script's `exit 2` (usage error) also lands on `exit 5` here, since the guard tests `-eq 0` rather than `-eq 1` — executed, `bogus-leg` printed the usage block and exited 5. The comment claims nothing about exit 2, so this is a scope note, not a defect against a claim.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:221-234`, `scripts/crb-egress-verdict.sh:26-42`, `docs/reviews/execution-logs/2026-08-19-r1-egress-leg.log` — cmd `bash <harness> <leg> <observed>`, cwd `/workspace`, exits 0 / 5 / 5 / 5, 2026-08-20T00:29Z

---

## Claim 9: "A void marker from an EARLIER sweep must not make this sweep exit 6: **nothing else ever deletes it**, so the status would be sticky forever once any cell had ever voided. This cell is about to be re-decided, so its old verdict goes."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:503-506`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the uniqueness of the deleter, the stickiness the fix removes, and whether the deletion can defeat the `exit 6` count for a cell that is *not* re-decided. Does not cover the loss of the historical void record when a re-decided cell subsequently passes (noted below as a consequence, not a claim defect).

"Nothing else ever deletes it" — a repo-wide grep finds exactly five references to the marker and only one removal, the new one:

```
runs/review-arms/crb-pipeline/run-host.sh:356   os.path.join(out, name, "CONTAINMENT_FAILED")),   # read (run-meta)
runs/review-arms/crb-pipeline/run-host.sh:506   rm -f "$dest/CONTAINMENT_FAILED"                   # the only delete
runs/review-arms/crb-pipeline/run-host.sh:645   : > "$dest/CONTAINMENT_FAILED"                     # write
runs/review-arms/crb-pipeline/run-host.sh:693   if os.path.isfile(os.path.join(out, n, "CONTAINMENT_FAILED"))))  # read (exit 6)
scripts/crb-pipeline-to-benchmark.py:242        if (cell / "CONTAINMENT_FAILED").exists():        # read (injector)
```

**The at-MAX_ATTEMPTS case the brief asked about does not defeat the count.** The MAX_ATTEMPTS `continue` fires at `:493-495`, eleven lines *before* the `rm -f` at `:506`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:493-495
  if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
    echo "=== $id — $attempts attempt(s) already made, at MAX_ATTEMPTS — skipping ..." >&2
    skipped_bad=$((skipped_bad+1)); continue
  fi
```

so a cell skipped as at-MAX_ATTEMPTS keeps its marker and still trips `exit 6`. The same is true of the already-complete `continue` at `:465-466`, the missing-baseline `continue` at `:454`, and the failed-restore `continue` at `:520`. The only cell whose marker is removed is one that goes on to be re-audited in this sweep, and the audit re-writes the marker at `:645` when it voids again.

Consequence, not a claim defect: if a previously-voided cell is re-run and passes, the fact that it once voided is no longer recoverable from `$OUT` — `write_run_meta` recomputes `voided_cells` from the markers on each invocation and carries forward only `requested_instances` (`run-host.sh:317-320`, `:359`). Nothing in the comment claims otherwise.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:454`, `:465-466`, `:493-495`, `:503-506`, `:520`, `:645`, `:693`, `scripts/crb-pipeline-to-benchmark.py:242`

---

## Claim 10: "Ledger this attempt's spend IMMEDIATELY, before the audit … the audit's `exit 4` abort would additionally have dropped THIS attempt's spend on the floor"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:586-590`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ledger's position relative to the audit, the artifact harvest, and the budget gate, and that it appends exactly once per attempt. The "before any path that can leave the loop" half is verdicted separately as Claim 11b.

The ledger now sits at `:591`; the two `exit 4` paths that can leave the loop after money is spent both sit below it — the artifact harvest at `:609-611` and the audit at `:637-641`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:609-611
  python3 "$ROOT/scripts/crb-harvest-artifacts.py" \
    "$clone" "${_bl[1]}" "$dest/artifacts" || {
      echo "$id: HARVEST invocation failed — see above" >&2; exit 4; }
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:637-641
  if [ "$audit_rc" -gt 1 ]; then
    echo "$id: containment audit could not run (exit $audit_rc) — NOT a void." >&2
    ...
    exit 4
  fi
```

**Exactly once per attempt**, not double-appended: `grep -n 'attempts.jsonl' run-host.sh` returns five hits and only one is an append — `:591` (the writer), `:490` (the `grep -c` read that computes `attempts`), `:339` and `:413` (read-only sums in `write_run_meta` and `sweep_spend_ok`), `:482` (a comment). The old bottom-of-loop copy was deleted, not duplicated (`git diff 1d8ea67..4624c5d` removes the `:673-686` block).

The **budget-halt** path is also covered: `sweep_spend_ok` is called at the *top* of the loop body, so it can only fire before a cell is paid for, never between payment and ledgering:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:436-437
for id in "${INSTANCES[@]}"; do
  sweep_spend_ok || { echo "SWEEP BUDGET EXCEEDED — stopping before this cell. ..." >&2; exit 2; }
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:339`, `:413`, `:436-437`, `:490`, `:586-600`, `:609-611`, `:637-641`

---

## Claim 11a: "before the audit"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:586`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ledger's ordering against the audit block only; see Claim 10 for the full ordering trace and Claim 11b for the second half of the same sentence.

Ledger at `:591`, audit `docker run` at `:633`, audit's abort at `:637-641` — quoted in Claim 10.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:591`, `:633`, `:637-641`

---

## Claim 11b: "and before any path that can leave the loop"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:586-587`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers paths between the paid `docker run` at `:546` and the ledger at `:591`. Does not establish how often the surviving path fires in practice — the failure modes are write errors, not routine ones — nor anything about paths after the ledger, which Claim 10 verifies.

Split from Claim 10 per the compound-claim rule: the two halves earn different verdicts, and this half asserts a mechanism the code refutes.

One block sits between the paid container and the ledger, and it is the **only heredoc in the cell body without `|| true`**:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:567  (no `|| true`)
python3 - "$dest/transcript.jsonl" "$dest/result.json" "$dest/review.md" <<'EOF'
...
json.dump(res, open(sys.argv[2], "w"))
open(sys.argv[3], "w").write(res.get("result") or "")
EOF
```

compared with the ledger's own guarded form four lines later:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:591
python3 - "$dest/result.json" "$dest/attempts.jsonl" <<'EOF' || true
```

Under this file's `set -euo pipefail`, a nonzero exit at `:567` terminates the sweep before `:591` runs. Reproduced with the same shape:

```
container ran (PAID)
exit=1
```

— "LEDGER APPENDED" never printed. The realistic triggers are narrow (`json.dump`/`write` failing on a full or read-only `$OUT`; `res.get("result")` returning a non-string), and `sys.exit(0)` already covers the common "no result event" case, so this is a small hole rather than a dead path. But a reader acting on "before **any** path that can leave the loop" — for instance, concluding that `attempts.jsonl` is a complete record of everything billed — is misled.

Precise version: "before the audit, before the artifact harvest, and before every `exit 4`; the result-extraction block above is the one remaining unguarded statement between the paid container and this line."

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:546-559`, `:567-585`, `:591`, `docs/reviews/execution-logs/2026-08-19-r1-ledger-order.log` — cmd `bash <repro>.sh`, cwd `/workspace`, exit 1, 2026-08-20T00:34Z

---

## Claim 12: "A FUNCTION called at the TOP of the loop body, not a step at the bottom: at the bottom, every early `continue` (missing baseline, already-complete cell, MAX_ATTEMPTS, failed restore) jumped straight past it"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:402-406`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the gate's position and the enumeration of the four early `continue`s; does not establish the arithmetic of the spend sum, which Claim 10 touches only for ordering.

The call is the first statement of the loop body (`run-host.sh:436-437`, quoted in Claim 10), and the four named `continue`s all sit after it: missing baseline `:454`, already-complete `:466`, MAX_ATTEMPTS `:495`, failed restore `:520`. The enumeration is exact — those are the only four `continue` statements in the loop (paraphrased — no quote available because the claim covers a count over the whole loop body: `grep -c 'continue' run-host.sh` inside `:436-700` yields those four plus the three `continue`s inside embedded Python, which are not shell control flow).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:400-406`, `:436-437`, `:454`, `:466`, `:495`, `:520`

---

## Claim 13: "(Foreign commits are counted in full but only the first is named, to keep the trace readable when a fetch brought in many.)"

**Location:** `scripts/crb-audit-clone.sh:27-28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the header comment's description of the output for the foreign-commit check; does not cover the other four checks' output shapes.

Executed against a fixture with two orphan commits and a pinned head:

```
CONTAINMENT VOID:
  - 2 commit(s) reachable outside the reviewed head and NOT descended from it (first: e90993a0e529)
exit=1
```

Counted in full (2), first named only. The header comment now matches the output; before `4624c5d` the count was computed and discarded (iteration-2 Claim 31).

**Evidence:** `scripts/crb-audit-clone.sh:27-28`, `scripts/crb-audit-clone.sh:88-99`, `docs/reviews/execution-logs/2026-08-19-r1-audit-foreign.log` — cmd `bash /workspace/scripts/crb-audit-clone.sh . <head-sha>`, cwd `<scratchpad>/repo`, exit 1, 2026-08-20T00:34Z

---

## Claim 14: "`internal-net <cmdline>` the network-create must **actually** be `--internal`" / "Without `--internal` the network routes to the internet directly and every other leg still passes"

**Location:** `scripts/crb-egress-verdict.sh:34`, `scripts/crb-egress-verdict.sh:80-89`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the `internal-net` matcher accepts and rejects, and what the two bats suites see. Does not establish docker's runtime behaviour for `--internal=false` (no docker here) — the mechanism gap is in the matcher, and the runtime consequence is inferred from docker's documented boolean-flag syntax.

This is the *different mutation of the same control* the brief asked for. The matcher is a substring glob, not a flag parse:

```bash
# scripts/crb-egress-verdict.sh:84-89
    case "$observed" in
      *--internal*)
        echo "ok  network created --internal" ;;
      *)
        echo "FAIL internal-net: network was created WITHOUT --internal — containers would route directly."
        exit 1 ;;
    esac
```

`--internal=false` contains `--internal`, so it passes the leg. Executed: with `run-host.sh:176` mutated to `docker network create --internal=false --subnet …`,

```
1..13
ok 12 the runner's own network create really carries --internal
... (13/13 ok)
```

and `test/crb-egress-config.bats` reported 0 failures. The new bats case at `test/crb-egress-verdict.bats:138-148` asserts `[[ "$output" == *"--internal"* ]]` against the runner's line, so it inherits the same substring weakness.

The claim's *conclusion* is right — without the flag, containment is gone and no other leg notices — and the *ordinary* mutation is caught (Claim 20). What "actually" overstates is strictness: the check is `contains the token`, not `enables the flag`. Precise version: "the create command must contain `--internal`; a `--internal=false` spelling satisfies this check and is not distinguished."

For contrast, the adjacent same-control mutation *is* caught: changing `EGRESS_SUBNET`'s default away from `tinyproxy.conf`'s `Allow 172.31.250.0/24` turns `crb-egress-config.bats` case 16 ("the proxy tunnels 443 only and serves only the pinned subnet") red.

**Evidence:** `scripts/crb-egress-verdict.sh:34`, `scripts/crb-egress-verdict.sh:80-89`, `test/crb-egress-verdict.bats:138-148`, `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:16`, `docs/reviews/execution-logs/2026-08-19-r1-internal-mutation.log` — cmds `bats test/crb-egress-verdict.bats`, `bats test/crb-egress-config.bats` under mutations A/B/C, cwd `/workspace`, exits 0 (B survives) / 1 (A and C caught), 2026-08-20T00:31Z

---

## Claim 15: "The comparison is against the baseline index written by `crb-materialize.py` when it materializes a clone"

**Location:** `scripts/crb-harvest-artifacts.py:19-20`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers where the index is written and that materialization is now the only writer; does not cover the index's contents beyond the `{relpath: sha256}` shape the same docstring describes.

This is the fix for iteration-2 Claim 22 (the docstring named the deleted `--snapshot` mode). `snapshot_baseline` is now called from exactly one place, the tail of `materialize()`:

```python
# scripts/crb-materialize.py:485-490
    # Snapshot LAST, and only after verify_containment has passed: the baseline
    # is the definition of "clean" every later cell restores to, ...
    rec.update(snapshot_baseline(dst, slug))
```

`grep -n 'snapshot_baseline' scripts/crb-materialize.py` returns exactly two lines — the `def` at `:286` and that call at `:490` (paraphrased — no quote available because the claim covers a call-site count, i.e. the absence of other callers).

**Evidence:** `scripts/crb-harvest-artifacts.py:19-21`, `scripts/crb-materialize.py:286`, `scripts/crb-materialize.py:485-490`

---

## Claim 16: "no baseline index at {index_path} — rebuild this slug with `crb-materialize.py --slug <slug> --force`"

**Location:** `scripts/crb-harvest-artifacts.py:102-103`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the recommended mode reaches the code that writes the index, and that that code writes both halves atomically. Does not cover the network-dependent clone step of `materialize()`, which cannot run in this sandbox.

The recommended flags reach `materialize(..., force)` — `--slug` is a `select()` mode (`crb-materialize.py:501`, `:623`) and `--force` is passed straight through (`:637`) — and `materialize()` ends at the `snapshot_baseline` call quoted in Claim 15. Executed the index-writing half directly, with `BASELINE_ROOT` redirected to a scratch dir:

```
files written: ['fixture.index.json', 'fixture.tar']
index contents: {
"a.json": "6a021504b02dc18c0b6bf8dfebdbdca579f0ab4d75eccb09ceeae89880a007ad",
"b.md": "045d2d07c2db3b9e6cef022457ee89434045a508c2dadccf9abe182ad633c273"
}
```

Both published names appear and no `.part` sibling is left behind, so the `.replace()` publish at `:305`/`:313` completes. The path the deleted `--snapshot` mode used is gone: `crb-materialize.py:515-527` documents that there is deliberately no in-place baseline mode.

**Evidence:** `scripts/crb-harvest-artifacts.py:99-104`, `scripts/crb-materialize.py:299-315`, `scripts/crb-materialize.py:485-490`, `scripts/crb-materialize.py:515-527`, `scripts/crb-materialize.py:623-637`, `docs/reviews/execution-logs/2026-08-19-r1-baseline-index.log` — cmd `python3 -` (exec of `crb-materialize.py` with `BASELINE_ROOT` redirected, calling `snapshot_baseline`), cwd `/workspace`, exit 0, 2026-08-20T00:34Z

---

## Claim 17: "Derived from the published names, not respelled: `.part` siblings were the last two places the layout was written out by hand."

**Location:** `scripts/crb-materialize.py:302-304`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two `.part` derivations and the "last two" count as of `4624c5d`; the third hand-spelling the same commit removed (`--verify`'s tar path) is Claim 18's subject.

Both `.part` names now derive from `baseline_paths()`' return values:

```python
# scripts/crb-materialize.py:301-313
    tar, idx_path = baseline_paths(slug)
    ...
    part = tar.with_name(tar.name + ".part")
    ...
    idx_part = idx_path.with_name(idx_path.name + ".part")
```

`grep -n '\.tar\|index\.json\|\.part' scripts/crb-materialize.py` now returns only these two derivations, the `baseline_paths` return at `:350`, and two docstring mentions — no other literal spelling remains (paraphrased — no quote available because the claim covers the absence of further hand-spellings).

**Evidence:** `scripts/crb-materialize.py:299-315`, `scripts/crb-materialize.py:350`

---

## Claim 18: "(tar, index) for a slug. **The ONE place this layout is defined.**"

**Location:** `scripts/crb-materialize.py:343`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every producer of a `.baselines/<slug>.{tar,index.json}` path in `scripts/` and `runs/`. Prose restatements in docstrings/comments and the assertion in `test/crb-disposable-clone.bats` are counted as pins/descriptions, not definitions.

This is the fix for iteration-2 Claim 24, which was falsified by `crb-materialize.py:581` re-deriving the tar path by hand. That site now calls the accessor:

```python
# scripts/crb-materialize.py:583
                    tar, _idx = baseline_paths(slug)
```

An exhaustive grep of `scripts`, `runs`, and `test` for `baseline_paths|BASELINE_ROOT|index\.json|\.tar` leaves four call sites (`:301`, `:374`, `:535`, `:583`), the single definition (`:350`), and the constant it composes (`:73`); the two `.part` siblings derive from the accessor's output (Claim 17). The runner no longer spells it either — it asks via `--baseline-paths` (`run-host.sh:448`), and `test/crb-disposable-clone.bats:315-322` pins both the output shape and the absence of `\.baselines/\$(id|slug)` in `run-host.sh`.

**Evidence:** `scripts/crb-materialize.py:73`, `:301`, `:342-350`, `:374`, `:535`, `:583`, `runs/review-arms/crb-pipeline/run-host.sh:448`, `test/crb-disposable-clone.bats:315-322`

---

## Claim 19: "The count is now reported, not merely tallied — it was computed into a variable nothing ever printed."

**Location:** `test/crb-audit-clone.bats:110-112`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the assertion the test makes and that it passes; does not establish that the case would catch every regression of the reporting line (it asserts a substring of the message, so a reworded message would fail it — which is the intent).

The case now asserts the count text:

```bash
# test/crb-audit-clone.bats:108-113
  [[ "$output" == *"NOT descended from it"* ]]
  # The count is now reported, not merely tallied — it was computed into a
  # variable nothing ever printed.
  [[ "$output" == *"1 commit(s) reachable outside"* ]]
```

and passes in the full suite (`ok 107` in the run log). The "nothing ever printed" half is confirmed by the pre-fix code, which assigned `first_foreign` and never emitted `n_foreign` (`git diff 1d8ea67..4624c5d -- scripts/crb-audit-clone.sh`).

**Evidence:** `test/crb-audit-clone.bats:106-113`, `scripts/crb-audit-clone.sh:88-99`, `docs/reviews/execution-logs/2026-08-19-r1-full-bats.log`

---

## Claim 20: "Dropping `--internal` from the runner's own `docker network create` survived every case in this file until the last one below was added."

**Location:** `test/crb-egress-verdict.bats:15-19`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the specific mutation named (dropping the flag) and this file's cases. Does not claim the pin is exhaustive — a different mutation of the same control survives, verdicted as Claim 14.

Executed. Baseline: `bats test/crb-egress-verdict.bats` → `1..13`, 13 ok, exit 0. With `run-host.sh:176` mutated to `docker network create --subnet $EGRESS_SUBNET $EGRESS_NET`:

```
not ok 12 the runner's own network create really carries --internal
# (in test file test/crb-egress-verdict.bats, line 142)
#   `[[ "$output" == *"--internal"* ]]' failed
exit=1
```

Case 12 is "the last one below" that the comment refers to (`test/crb-egress-verdict.bats:138`), and it is the only case that goes red — confirming both halves: the mutation is now caught, and it was caught by nothing else.

**Evidence:** `test/crb-egress-verdict.bats:12-19`, `test/crb-egress-verdict.bats:134-148`, `runs/review-arms/crb-pipeline/run-host.sh:176`, `docs/reviews/execution-logs/2026-08-19-r1-internal-mutation.log` — cmd `bats test/crb-egress-verdict.bats`, cwd `/workspace`, exit 0 baseline / 1 mutated, 2026-08-20T00:31Z

---

## Claim 21: "Verified by execution: a failing leg now exits 5 and prints why."

**Location:** commit message `4624c5d`, item 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Independently re-executed, not accepted on the commit message's word; covers both directions of the leg. Same execution as Claim 8.

Reproduced: failing legs exit 5 and print `(refusing to spend — egress leg '<name>' failed)`; a passing leg returns 0 and the caller continues. Output quoted in Claims 4 and 8.

**Evidence:** `docs/reviews/execution-logs/2026-08-19-r1-egress-leg.log`, `runs/review-arms/crb-pipeline/run-host.sh:221-234`

---

## Claim 22: "Added a case that asserts the command the runner constructs, that it is executed via that variable, and that the leg is handed the same one; verified by applying the mutation."

**Location:** commit message `4624c5d`, item 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three assertions the case makes and the mutation result; the strictness of the first assertion is Claim 14.

All three assertions are present:

```bash
# test/crb-egress-verdict.bats:139-147
  run grep -E '^\s*NET_CREATE_CMD="docker network create' "$runner"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--internal"* ]]
  grep -qE '^\s*\$NET_CREATE_CMD >' "$runner"
  grep -q 'egress_leg internal-net "$NET_CREATE_CMD"' "$runner"
```

and the mutation makes exactly this case fail (Claim 20's execution).

**Evidence:** `test/crb-egress-verdict.bats:134-148`, `docs/reviews/execution-logs/2026-08-19-r1-internal-mutation.log`

---

## Claim 23: "Tests: 440 (+1). The single failure is the pre-existing, unrelated Consider-sections case from an uncommitted local edit to `crb-pipeline-to-benchmark.py`."

**Location:** commit message `4624c5d`, Tests paragraph
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the total, the delta from `1d8ea67`, the identity of the single failure and its attribution to the uncommitted edit. Does not cover the correctness of the uncommitted edit itself, which is outside this scope.

Executed `bats test/` in `/workspace`: plan `1..440`, 439 ok, one `not ok`:

```
not ok 184 only the three finding sections are emitted from the golden rubric
```

`git status --porcelain` shows exactly one tracked modification, `M scripts/crb-pipeline-to-benchmark.py` (+4/−3), and the failing case lives in `test/crb-injector-sections.bats:44`, whose subject is that script. Stashing the edit and re-running that suite gives `1..8`, 8 ok — including `ok 2 only the three finding sections are emitted from the golden rubric`. So at the committed tree the suite is 440/440, and the failure is caused by the uncommitted edit, exactly as claimed.

Counting `@test` declarations in top-level `test/*.bats` at each SHA: `1d8ea67` → 439, `4624c5d` → 440. `+1` is exact.

**Evidence:** `docs/reviews/execution-logs/2026-08-19-r1-full-bats.log` — cmd `bats test/`, cwd `/workspace`, exit 1 (439/440), 2026-08-20T00:32Z; `test/crb-injector-sections.bats:44`; `scripts/crb-pipeline-to-benchmark.py`

---

## Claim 24: "Correction to `1d8ea67`'s own message: the test delta there was +26, not +23 — 'less the 3 replaced' double-counted a single replaced test."

**Location:** commit message `4624c5d`, final paragraph
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the arithmetic of the delta only; does not adjudicate the "double-counted a single replaced test" explanation of *why* `1d8ea67` got it wrong, which is a claim about the author's arithmetic rather than about the code.

Counting `@test` declarations in top-level `test/*.bats` at each SHA (`git ls-tree` + `git show | grep -c '^@test'`):

```
c98343b: top-level test/*.bats @test = 413
1d8ea67: top-level test/*.bats @test = 439
4624c5d: top-level test/*.bats @test = 440
```

439 − 413 = **+26**. This matches the iteration-2 fact-check's own finding (its Claim 29, "the real net is +26 (413 → 439)"), recomputed here independently. The correction is right, and recording it in `4624c5d` rather than amending `1d8ea67` does preserve the SHA the iteration-2 verdicts point at.

**Evidence:** `docs/reviews/execution-logs/2026-08-19-r1-full-bats.log`, commands run in `/workspace` at 2026-08-20T00:33Z; `docs/reviews/code-fact-check-report.md` (iteration-2 Claim 29)

---

## Claim 25: "the attempt ledger now runs immediately after harvest rather than after the audit"

**Location:** commit message `4624c5d`, drift-items paragraph
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which block the ledger now follows; the substantive half of the sentence ("so the new `exit 4` abort path cannot drop the spend of the cell that just cost money") is verified under Claim 10.

The word "harvest" names two different blocks in this file. The ledger at `:591` follows the **result-extraction** block, whose own comment opens `# Harvest: the final result event (cost/turns) + the review text …` (`:565-566`) — so the sentence is defensible. But the file's other harvest, `crb-harvest-artifacts.py` at `:609`, runs **after** the ledger, not before it. A reader tracing "after harvest" to the artifact harvest would place the ledger one block too late.

Precise version: "the attempt ledger now runs immediately after the result-extraction block — before the artifact harvest, before the audit, and before both `exit 4` paths."

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:565-567`, `:591`, `:609-611`

---

## Claim 26: "Plus two drift items and **three** the fact-check rated Mostly Accurate"

**Location:** commit message `4624c5d`, drift-items paragraph
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the count and classification of the iteration-2 verdicts this paragraph enumerates; does not affect whether the items were actually fixed (Claims 9, 10, 13, 15, 16, 18 verify that they were).

The paragraph enumerates three items — `exit 6`'s stale markers, the unprinted foreign count, and the attempt-ledger move. Only the first two carried a **Mostly accurate** verdict in the iteration-2 report (its Claims 21 and 31). The third was filed under "Mostly Accurate" as an explicitly non-verdict entry: *"**Claim 20's scope note** … not a claim defect, but flagged for the orchestrator"*. Separately, two further Mostly-Accurate items (its Claims 1 and 9, the `PREFLIGHT_ONLY` `$0` wording) were fixed by this commit but are described in a different paragraph ("Also corrected: …"), so the message under-counts what it closed.

Net effect: all five Mostly-Accurate items plus the scope note were addressed; only the label "three the fact-check rated Mostly Accurate" is imprecise. Precise version: "two Mostly-Accurate items plus a flagged scope note here, and two more Mostly-Accurate items in the paragraph below."

**Evidence:** `docs/reviews/code-fact-check-report.md` ("Claims Requiring Attention → Mostly Accurate" section), commit message `4624c5d`

---

## Claim 27: "Still not verified: everything docker-shaped, including whether docker honours `--internal`, which no test can observe."

**Location:** commit message `4624c5d`, Confidence paragraph
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the absence of docker in this sandbox and the absence of any test that starts a container; does not evaluate whether the limitation is acceptable, which is a reviewer question, not a fact-check one.

`docker` is not on `PATH` in this sandbox and no bats case invokes it: every `docker` string under `test/` is inside a grep assertion or a fixture string (`test/crb-egress-verdict.bats:36`, `:41`, `:139`; `test/crb-egress-config.bats:72`, `:86`) — paraphrased — no quote available because the claim covers the absence of code across the whole `test/` tree. The full suite ran to completion (440 cases) without a docker daemon, which is itself evidence that nothing in it requires one.

**Evidence:** `test/crb-egress-verdict.bats:36`, `:41`, `:139`, `test/crb-egress-config.bats:72`, `:86`, `docs/reviews/execution-logs/2026-08-19-r1-full-bats.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11b** (`runs/review-arms/crb-pipeline/run-host.sh:586-587`): "before **any** path that can leave the loop" — the result-extraction heredoc at `:567` is the one unguarded statement between the paid container and the ledger; under `set -euo pipefail` a nonzero exit there drops the attempt's spend. Reproduced by execution. **Fix:** append `|| true` to `:567`'s heredoc (matching `:591`), or reword to "before the audit, before the artifact harvest, and before both `exit 4` paths." **This is mechanism error number six** — the smallest of the six, but the same class.

### Stale
- **Claim 7** (`runs/review-arms/crb-pipeline/run-host.sh:208`): section header still says "PROVE the allowlist, **three ways**" over five legs. Carried unfixed from iteration-2 Claim 11; introduced by `197eec6` (context-only), and `4624c5d` does not claim to have closed it. One-word fix.

### Mostly Accurate
- **Claim 14** (`scripts/crb-egress-verdict.sh:34`, `:80-89`): "must **actually** be `--internal`" is a substring glob. `--internal=false` passes the leg **and** the new bats case — executed, 13/13 green and 0 failures in `crb-egress-config.bats`. Tighten to a word-boundary match that rejects `=false`, e.g. `*--internal[[:space:]]*|*--internal`, and add the mutation as a case.
- **Claim 25** (commit message `4624c5d`): "immediately after harvest" is ambiguous between the result-extraction block (true) and `crb-harvest-artifacts.py` (false — that runs after the ledger).
- **Claim 26** (commit message `4624c5d`): "three the fact-check rated Mostly Accurate" — two of the three enumerated carried that verdict; the third was an explicitly-flagged scope note, and two further Mostly-Accurate items are closed in the next paragraph.

### Unverifiable
None. Every claim in scope resolved statically or by execution. The docker-shaped claims (1, 3, 4, 5, 6, 27) were verdicted on their structural content only, with the runtime half named in each `Scope` field rather than left as a false Verified.

---

## Hallucination-pattern log

No entry appended. The single Incorrect verdict is an over-broad guarantee about statement ordering, not a fabricated symbol, method, API, or parameter — which is the log's stated admission criterion. Checked explicitly against the two logged patterns ("a specific measured value quoted from a checked-in artifact set that does not contain it"): the four measured values in `4624c5d`'s commit message (`440`, `+1`, `+26`, the single-failure attribution) were each recomputed from the artifact set and each held, so the pattern did not recur.

---

## Goal-Alignment Note
- **Answered:** yes — both fix commits fact-checked against the code that exercises them, with the nine claim families in the brief each traced by execution where executable; mechanism error number six found and named.
- **Out of scope:** `197eec6` and everything earlier on the branch (context only, per the brief) — Claim 7 is reported because iteration 2 flagged it and it is still open, not as a new finding against these commits; the runtime behaviour of anything docker-shaped (no docker in this sandbox); the uncommitted local edit to `scripts/crb-pipeline-to-benchmark.py` (checked only far enough to confirm it causes the single test failure).
- **Escalate:** (1) **Claim 11b** — the ledger comment's "before any path that can leave the loop" is refuted by the unguarded heredoc four lines above it; one-token fix (`|| true`), and it should be taken before the sweep because the loop's whole spend-accounting story rests on `attempts.jsonl` being complete. (2) **Claim 14** — `--internal=false` defeats containment and survives the entire suite, including the new pin `4624c5d` added; the brief asked for a surviving mutation of that control and this is it. Worth tightening the glob before a paid sweep, since `--internal` is the flag the containment story rests on. (3) **Claim 7** — the "three ways" header is still stale; cosmetic, but it is the last surviving instance of the count-drift the two commits otherwise cleaned up everywhere else.
