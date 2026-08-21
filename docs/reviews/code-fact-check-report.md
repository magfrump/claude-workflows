# Code Fact-Check Report

**Repository:** `/workspace`
**Commit:** 1d8ea67
**Replication:** k=1 (loop pass, decision 031)
**Scope:** commit `1d8ea67` on `feat/crb-direction1-harness` (11 files, +825/−172) — the *fix* commit answering `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness-r2.md`. Parent `197eec6` and the rest of the branch are context only.
**Checked:** 2026-08-19
**Total claims checked:** 31
**Summary:** 19 verified, 4 mostly accurate, 1 stale, 7 incorrect, 0 unverifiable
<!-- Header corrected 2026-08-21: the original run wrote 30 / 18-5-2-5-0, but the
     report body contains 31 claims verdicted 19-4-1-7-0 (counted from the
     **Verdict:** lines). Count fix only; no claim content touched. -->

**Hallucination-pattern log consulted:** `docs/reviews/hallucination-patterns.md` (2 entries — both "a specific measured value quoted from a checked-in artifact set that does not contain it"). Claim 29 below (`+23` test delta) is a near-neighbour of that class: a specific arithmetic figure quoted about a checked-in artifact set that does not yield it. It is a miscount, not a fabricated symbol, so it is reported here only and not appended to the log.

**Headline for the orchestrator.** The specific risk this pass was opened to catch — *this commit's fixes introducing new mechanism errors of the same class* — materialised **three times**:

- **Claim 13 (Incorrect, executed):** the new `egress_leg` helper's `exit 5` is unreachable. Under `run-host.sh`'s `set -euo pipefail`, the piped verdict call trips errexit and the script dies with status **1** before the `exit 5` line and before "(refusing to spend)" ever prints. Every doc that says "the sweep exits 5" is refuted by execution.
- **Claim 26 (Incorrect, executed):** `test/crb-egress-verdict.bats:12` claims all three previously-surviving mutations "now fail a case". Dropping `--internal` from the `docker network create` that `run-host.sh` actually runs still leaves the whole suite green (only the pre-existing unrelated failure appears). The new `internal-net` leg catches that mutation **only at runtime, on a docker host** — the test suite still cannot see it.
- **Claim 28 (Incorrect):** the commit message says `"exactly ONE reachable host"` was "corrected against what the fact-check measured". The correction landed in decision 034 only; the claim survives verbatim at its cited home, `docker/Dockerfile.review:6-8`.

Two further Incorrects are ordinary drift rather than mechanism errors: `crb-harvest-artifacts.py` still points operators at the `--snapshot` mode this same commit deleted (Claim 22), and `baseline_paths`'s "the ONE place this layout is defined" is falsified by `crb-materialize.py:581` (Claim 24).

Everything else the commit claims — R1's deletion of `--snapshot`, R2's tri-state audit branch, R3's index hash ordering, R4's 034 correction, A3/A4's guard moves, A5–A13's corrections — verified.

---

## Claim 1: "A five-leg egress preflight — the network really is `--internal`, the API is reachable through the proxy, github is refused through it over HTTPS and over plain HTTP, and github is unroutable without it — must pass before any paid cell. `PREFLIGHT_ONLY=1` runs exactly that and stops."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:48-51`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the leg inventory and what `PREFLIGHT_ONLY=1` executes; does not establish the legs' runtime outcomes (docker is unavailable here) — and the "must pass" half is separately refuted as to *how* it fails, see Claim 13.

Five legs run, in the stated order:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:228-242
egress_leg internal-net "$NET_CREATE_CMD"
egress_leg api-reachable "$(in_cell_net '...https://api.anthropic.com/v1/models || echo 000')"
egress_leg filter-blocks "$(in_cell_net '...https://github.com/ || echo 000')"
egress_leg plain-http "$(in_cell_net '...http://github.com/ || echo 000')"
egress_leg no-direct-route "$(docker run --rm --network "$EGRESS_NET" ... https://github.com/ || echo 000')"
```

What "runs exactly that and stops" understates: the stop point sits *after* the paid auth preflight, not after the egress legs.

```bash
# runs/review-arms/crb-pipeline/run-host.sh:284-290
if [ -n "$PREFLIGHT_ONLY" ]; then
  ...
  echo "auth and skill registration confirmed. No cell ran; only the preflight's"
  echo "own auth turn was billed. Re-run without PREFLIGHT_ONLY to sweep."
  exit 0
fi
```

The runner itself is honest about the billed turn; 034's "exactly that" is the imprecise wording. Precise version: "`PREFLIGHT_ONLY=1` runs the five egress legs and the auth/skill preflight (which bills one turn), then stops."

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:48-51`, `runs/review-arms/crb-pipeline/run-host.sh:228-242`, `runs/review-arms/crb-pipeline/run-host.sh:284-290`

---

## Claim 2: "a running cell needs only one reachable host (it will *attempt* others — the autoupdater and telemetry endpoints listed in `devcontainer-config/egress/base.txt` — which the allowlist refuses)"

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:45-49`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the correction of the prior "exactly ONE reachable host" wording in 034 and the existence/content of the cited list; does not establish which endpoints a running CLI actually contacts (requires docker), and does not cover the same claim's surviving copy in `Dockerfile.review` (Claim 28).

The cited file lists five hosts besides `api.anthropic.com`:

```
# devcontainer-config/egress/base.txt:6-14
api.anthropic.com
claude.ai
console.anthropic.com
sentry.io
statsig.com
registry.npmjs.org
```

and the arm's allowlist holds exactly one entry, so the others are refused:

```
# runs/review-arms/crb-pipeline/docker/egress-allowlist:10
^api\.anthropic\.com$
```

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:45-49`, `devcontainer-config/egress/base.txt:6-14`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:10`

---

## Claim 3: "The harvest changed shape rather than strictly improving: … it also stops copying symlinked artifacts, which the old loop copied with `cp --no-dereference`, and imposes 5 MB / 50 MB / 500-file caps the old loop had none of."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:70-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named differences (symlink handling, the three caps, the gitignore gain); does not re-establish the gitignore-visibility gain itself, which the k=3 pass already confirmed.

The old loop did copy symlinks as links:

```bash
# a80bb48:runs/review-arms/crb-pipeline/run-host.sh:377-381
# --no-dereference so a symlink the agent left behind is copied as a link
cp --no-dereference "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
done < <(git -C "$clone" status --porcelain=v1 -z --untracked-files=all)
```

The three caps exist and are new:

```python
# scripts/crb-harvest-artifacts.py:47-49
MAX_FILE_BYTES = 5 * 1024 * 1024
MAX_TOTAL_BYTES = 50 * 1024 * 1024
MAX_FILES = 500
```

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:70-76`, `scripts/crb-harvest-artifacts.py:47-49`, `scripts/crb-harvest-artifacts.py:113-120`, `a80bb48:runs/review-arms/crb-pipeline/run-host.sh:377-381`

---

## Claim 4: "**R6 did not dissolve — it moved.** Every clone materialized before this change lacks a baseline, so `run-host.sh` skips all of them and exits 3 … the remedy is a rebuild (`--slug <id> --force`) rather than a repair."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:77-86`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the on-disk state, the skip path and the exit-3 path; does not establish what happens after an operator actually rebuilds.

No baseline exists on disk and no manifest record carries a baseline hash (paraphrased — no quote available because the claim covers the *absence* of a directory and of a JSON key: `ls external/crb-eval` lists only the five clone dirs with no `.baselines`, and a `json.load` over `runs/review-arms/crb/instances.json` yields `[]` for records having `baseline_sha256`).

The skip and the exit are both as described:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:429-437
if [ ! -f "${_bl[0]:-/nonexistent}" ] || [ ! -f "${_bl[1]:-/nonexistent}" ]; then
    echo "$id: no baseline — rebuild the clone and its baseline with:" >&2
    echo "      python3 scripts/crb-materialize.py --slug $id --force" >&2
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:665-668
if [ "$ran" -eq 0 ] && [ "$skipped_bad" -gt 0 ]; then
  echo "NO CELL RAN and $skipped_bad instance(s) were unusable — not a clean sweep." >&2
  exit 3
fi
```

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:77-86`, `runs/review-arms/crb-pipeline/run-host.sh:429-437`, `runs/review-arms/crb-pipeline/run-host.sh:665-668`, `runs/review-arms/crb/instances.json`

---

## Claim 5: "a low-bandwidth DNS side channel through docker's embedded resolver (`run-host.sh` names it where spend is authorized, not only here)"

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:89-91`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the disclosure exists in the runner header; does not assess the side channel's severity.

```bash
# runs/review-arms/crb-pipeline/run-host.sh:50-55
#   WHAT IT DOES NOT CLOSE, stated here rather than only in decision 034 because
#   this is where spend is authorized: containers on $EGRESS_NET still reach
#   docker's embedded DNS resolver, which is a low-bandwidth exfiltration and
#   retrieval side channel. Leg 3 proves one internet host is unroutable; it
#   proves nothing about the docker host itself or sibling containers.
```

The second sentence is also accurate: `no-direct-route` observes `https://github.com/` only (`run-host.sh:241-242`).

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:89-91`, `runs/review-arms/crb-pipeline/run-host.sh:50-55`, `runs/review-arms/crb-pipeline/run-host.sh:241-242`

---

## Claim 6: "`scripts/crb-materialize.py --all  # all 50 (~13 GB: clones + baselines)`"

**Location:** `docs/working/crb-direction1-setup.md:27`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the arithmetic consistency of the figure with the measured 5-PR pilot; does not establish the true `--all` size, since 45 of the 50 PRs have never been materialized.

The manifest's own measurements give a 670 MB pilot (paraphrased — no quote available because the value is a sum over a JSON file, not a snippet: `sum(v["clone_mb"])` over the five records in `runs/review-arms/crb/instances.json` is 670). Doubling for baselines and scaling ×10 gives ~13.4 GB, which matches both this line and the in-code estimate:

```python
# scripts/crb-materialize.py:485-487
# Doubles the disk cost of the arm (pilot ~670 MB -> ~1.3 GB; --all ~6.5 -> ~13 GB), which is
# the price of never running host git against a container-written .git.
```

The prior `~6-7 GB` figure is gone. The remaining imprecision is inherent: the extrapolation assumes the unmaterialized 45 clones average the pilot's size.

**Evidence:** `docs/working/crb-direction1-setup.md:27`, `scripts/crb-materialize.py:483-488`, `runs/review-arms/crb/instances.json`

---

## Claim 7: "note the ordering dependency: the two refusal legs accept `000`, which a *dead proxy* also returns, so they mean 'the filter works' only once the reachability leg has passed."

**Location:** `docs/working/crb-direction1-setup.md:105-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the accept-set of `filter-blocks`/`plain-http` and the leg ordering in the runner; does not establish that `api-reachable` passing proves the *plain-HTTP* forward-proxy path is alive (it exercises CONNECT only).

The two refusal legs do accept `000`:

```bash
# scripts/crb-egress-verdict.sh:58-63
  filter-blocks|plain-http)
    case "$observed" in
      403|000)
        echo "ok  non-allowlisted host refused ($leg, HTTP $observed)" ;;
```

and `api-reachable` is invoked before both (`run-host.sh:231` vs `:234` and `:239`), with the dependency restated at the call site:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:229-230
# (1) positive: the API is reachable THROUGH the proxy. Must be first — the
# refusal legs accept "000", which a dead proxy also produces.
```

**Evidence:** `docs/working/crb-direction1-setup.md:105-109`, `scripts/crb-egress-verdict.sh:58-63`, `runs/review-arms/crb-pipeline/run-host.sh:229-239`

---

## Claim 8: "**egress**, five legs, all of which must pass or the sweep exits 5 before spending anything"

**Location:** `docs/working/crb-direction1-setup.md:98-99`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit code produced when a leg fails; does not dispute the leg count (five, per Claim 1) or the "before spending anything" half, which holds — the failure is still fail-closed, just not with the documented code or message.

A failing leg exits **1**, not 5. See Claim 13 for the mechanism and the executed reproduction; this line is the doc-side copy of the same refuted claim. `docs/decisions/034:48-51` ("must pass before any paid cell") is the vaguer sibling and escapes the verdict by not naming a code.

Command: `bash eg.sh` (a verbatim extract of `run-host.sh:220-224` plus `set -euo pipefail`, calling the real `scripts/crb-egress-verdict.sh`) · cwd `/tmp/claude-1000/-workspace/b5dac707-d9e6-4214-b47b-22e9dc265bc8/scratchpad` · exit code **1** · 2026-08-20T00:09:33Z.

**Evidence:** `docs/working/crb-direction1-setup.md:98-99`, `runs/review-arms/crb-pipeline/run-host.sh:220-224`, `docs/reviews/execution-logs/2026-08-19-egress-leg-errexit.log`

---

## Claim 9: "**`PREFLIGHT_ONLY=1` runs all of the above and stops.** That command is what makes 'the control tests itself at $0 before the first paid cell' a claim you can cash"

**Location:** `docs/working/crb-direction1-setup.md:117-121`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cost of what `PREFLIGHT_ONLY=1` runs; does not dispute that the *egress* legs themselves are free.

"All of the above" is the doc's own numbered list, whose item 2 is the auth/skill preflight — a real headless `claude` invocation that bills a turn. So the command that cashes the "$0" claim is not itself $0. The runner states this correctly where it matters:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:288
  echo "auth and skill registration confirmed. No cell ran; only the preflight's"
```

Precise version: the five egress legs cost $0; `PREFLIGHT_ONLY=1` additionally bills the one-turn auth preflight, which is still ~$0.01 against a $10–40 cell.

**Evidence:** `docs/working/crb-direction1-setup.md:88-121`, `runs/review-arms/crb-pipeline/run-host.sh:253-262`, `runs/review-arms/crb-pipeline/run-host.sh:284-290`

---

## Claim 10: "NOTE what this does NOT do: ConnectPort scopes the CONNECT method alone. A plain `GET http://host/` is an ordinary forward-proxy request that never reaches this directive — HTTP_PROXY and http_proxy are both exported to every cell, so that path is live. It is the Filter below, not this line, that refuses a non-allowlisted host over plain HTTP"

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-26`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the correction of the prior claim (that `ConnectPort` blocked plain HTTP) and the fact that lowercase `http_proxy` reaches every cell; does not execute tinyproxy, so the Filter's plain-HTTP behaviour rests on its documented semantics plus the config below.

The lowercase env var is exported on both the preflight and the paid cell path:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:202-204
  docker run --rm --network "$EGRESS_NET" \
    -e HTTP_PROXY="$PROXY_URL" -e HTTPS_PROXY="$PROXY_URL" \
    -e http_proxy="$PROXY_URL" -e https_proxy="$PROXY_URL" \
```

and the Filter is host-matched with default-deny, which applies to forward-proxy requests as well as CONNECT:

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:31-35
Filter "/etc/tinyproxy/filter"
FilterURLs Off
...
FilterDefaultDeny Yes
```

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-35`, `runs/review-arms/crb-pipeline/run-host.sh:201-205`, `runs/review-arms/crb-pipeline/run-host.sh:532-539`

---

## Claim 11: "── Egress preflight: PROVE the allowlist, three ways ───"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:208`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section header only; the body comment beneath it ("each leg is separate because they fail for different reasons") remains accurate.

The block below this header now runs five legs, not three:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:208
# ── Egress preflight: PROVE the allowlist, three ways ───────────────────────
```

against `run-host.sh:228-242` (five `egress_leg` calls, quoted in Claim 1). Every other statement of the count in this commit — `034:48`, `crb-direction1-setup.md:98`, `test/crb-egress-config.bats:110` — was updated to five; this header was not. Precise version: "PROVE the allowlist, five ways".

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:208`, `runs/review-arms/crb-pipeline/run-host.sh:228-242`, `test/crb-egress-config.bats:110`

---

## Claim 12: "run `PREFLIGHT_ONLY=1` to do exactly that and stop" / "PREFLIGHT_ONLY=1 ... run-host.sh  # build + prove the egress control, then stop"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:48`, `:74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the stop point is after both preflights and before the cell loop, and that no *cell* is paid for; does not cover the auth turn's cost, which Claim 9 handles.

The gate sits between the auth preflight's heredoc and the `for id` loop:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:284-290
if [ -n "$PREFLIGHT_ONLY" ]; then
  echo
  echo "PREFLIGHT_ONLY=1 — images built, egress allowlist proven by execution,"
  ...
  exit 0
fi
```

with `for id in "${INSTANCES[@]}"; do` at `:426`. `DRY_RUN`'s exit at `:148-151` genuinely precedes the `docker build` calls at `:160-163`, so the commit's stated reason for needing a second switch holds. The ordering is additionally pinned by `test/crb-egress-config.bats:180-192`, which passed in this run.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:148-163`, `runs/review-arms/crb-pipeline/run-host.sh:284-290`, `runs/review-arms/crb-pipeline/run-host.sh:426`, `docs/reviews/execution-logs/2026-08-19-r2-crb-suites.log`

---

## Claim 13: "`[ "$rc" -eq 0 ] || { echo "  (refusing to spend)" >&2; exit 5; }`" — i.e. a failing egress leg prints "(refusing to spend)" and exits 5

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:220-224`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what a failing leg actually produces (exit code and message); does not dispute that the failure is fail-closed — nothing is spent either way — nor the `PIPESTATUS` capture itself, which is correct in isolation.

`run-host.sh` sets `set -euo pipefail` (`:75`). The helper's first statement is an unguarded pipeline:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:220-224
egress_leg() {  # <leg> <observed>
  bash "$VERDICT" "$1" "$2" | sed 's/^/  /'
  local rc=${PIPESTATUS[0]}
  [ "$rc" -eq 0 ] || { echo "  (refusing to spend)" >&2; exit 5; }
}
```

With `pipefail`, a leg verdict of 1 makes the pipeline return 1; the pipeline is neither in a condition context nor followed by `||`, so `errexit` terminates the shell **at line 221** — lines 222–223 never execute. Reproduced verbatim:

```
# docs/reviews/execution-logs/2026-08-19-egress-leg-errexit.log
  FAIL api-reachable: api.anthropic.com unreachable through the proxy — every cell would fail
EXIT=1
```

Note what is missing from that output: `(refusing to spend)` never prints, and the status is 1, not 5. This is the same "a line credited with an effect it does not have" class as the prior loop's three mechanism errors — the `exit 5` is dead code as written. (`shellcheck`-style fix would be `bash "$VERDICT" ... | sed ... || true` before reading `PIPESTATUS`, or `set +e` around the pipeline.)

Command: `bash eg.sh` · cwd `/tmp/claude-1000/-workspace/b5dac707-d9e6-4214-b47b-22e9dc265bc8/scratchpad` · exit code 1 · 2026-08-20T00:09:33Z.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:75`, `runs/review-arms/crb-pipeline/run-host.sh:220-224`, `docs/reviews/execution-logs/2026-08-19-egress-leg-errexit.log`

---

## Claim 14: "(0) the flag the whole story rests on — asserted against the command that was actually run, not against the author's intention."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:226-228`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the asserted string and the executed command are the same shell variable; does not establish that any *test* can see a mutation of that string (it cannot — Claim 26).

`NET_CREATE_CMD` is both executed and passed to the leg:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:175-177
  NET_CREATE_CMD="docker network create --internal --subnet $EGRESS_SUBNET $EGRESS_NET"
  $NET_CREATE_CMD >/dev/null
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:228
egress_leg internal-net "$NET_CREATE_CMD"
```

`setup_egress` is called as a plain function at `:190` (not a subshell), so the assignment survives to the preflight.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:171-183`, `runs/review-arms/crb-pipeline/run-host.sh:190`, `runs/review-arms/crb-pipeline/run-host.sh:228`

---

## Claim 15: "A FUNCTION called at the TOP of the loop body, not a step at the bottom: at the bottom, every early `continue` … jumped straight past it"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:392-396`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate's position relative to every `continue` in the loop body; does not cover what happens when the `python3` heredoc itself errors (any nonzero is read as "over budget", which fails closed).

`sweep_spend_ok` is the first statement of the loop body, before the baseline check, the cell-status check, the MAX_ATTEMPTS check and the restore — the four `continue` sites:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:426-427
for id in "${INSTANCES[@]}"; do
  sweep_spend_ok || { echo "SWEEP BUDGET EXCEEDED — stopping before this cell. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
```

The earliest `continue` in the loop body is at `:444`, seventeen lines later (paraphrased — no quote available because the claim covers the *absence* of any `continue` in the intervening span `:428-443`, which is a comment block, the `mapfile` call and the baseline test; the four `continue` sites are `:444`, `:456`, `:485`, `:506`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:388-424`, `runs/review-arms/crb-pipeline/run-host.sh:426-437`

---

## Claim 16: "Paths come from crb-materialize.py rather than being spelled here: the `.baselines/` layout has one owner" and "BOTH halves are required here, before the cell is paid for"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:429-437`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the *runner* side of the single-owner claim and the pre-payment position of the both-halves gate; the broader "ONE place this layout is defined" claim inside `crb-materialize.py` is Claim 24 and does not hold.

```bash
# runs/review-arms/crb-pipeline/run-host.sh:438-439
  mapfile -t _bl < <(python3 "$ROOT/scripts/crb-materialize.py" --baseline-paths "$id")
  if [ ! -f "${_bl[0]:-/nonexistent}" ] || [ ! -f "${_bl[1]:-/nonexistent}" ]; then
```


A repo-wide grep finds no remaining hand-spelled `.baselines/$id` path in the runner — the only surviving mention is the explanatory comment at `:436` (paraphrased — no quote available because the claim covers the absence of grep results: `rg '\.baselines'` over `*.sh`/`*.py`/`*.bats` returns hits only in `crb-materialize.py`, the bats pins, and that comment). The gate at `:439` and the hash verification inside `--restore` (`:501`) both precede the paid `docker run` at `:532`.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:429-444`, `runs/review-arms/crb-pipeline/run-host.sh:501`, `runs/review-arms/crb-pipeline/run-host.sh:532-547`

---

## Claim 17: "MAX_ATTEMPTS is checked OUTSIDE the result.json test … a container that dies before emitting a `result` event writes NO result.json, so the guard never ran … attempts.jsonl is the ledger either way, so it is the right thing to gate on."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:465-486`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the guard is unnested AND that the no-result path reaches the ledger append, closing the loop the fix depends on; does not cover the abort paths (`exit 4` from harvest or audit), on which no ledger line is written for the in-flight attempt — see Claim 20's scope note.

The guard now precedes, rather than nests inside, the `result.json` test:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:483-487
  if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
    echo "=== $id — $attempts attempt(s) already made, at MAX_ATTEMPTS — skipping (delete $dest to reset)" >&2
    skipped_bad=$((skipped_bad+1)); continue
  fi
  if [ -s "$dest/result.json" ]; then
```

The fix is only non-cosmetic if a no-result cell actually gets an `attempts.jsonl` line. It does: the transcript reducer exits 0 without writing `result.json`

```python
# runs/review-arms/crb-pipeline/run-host.sh:566-568
if res is None:
    print("  !! no result event — treat this instance as failed", file=sys.stderr)
    sys.exit(0)
```

and the ledger step tolerates the missing file and appends regardless:

```python
# runs/review-arms/crb-pipeline/run-host.sh:647-654
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    d = {}
rec = {"cost_usd": d.get("total_cost_usd") or 0, ...}
with open(sys.argv[2], "a") as fh:
    fh.write(json.dumps(rec) + "\n")
```

So the attempt is counted, and `MAX_ATTEMPTS` bounds the loop.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:465-491`, `runs/review-arms/crb-pipeline/run-host.sh:556-568`, `runs/review-arms/crb-pipeline/run-host.sh:642-655`

---

## Claim 18: "The proxy is `--restart no` and its liveness was proven once, at t=0 … One $0 probe per cell is the cheapest possible insurance"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:507-515`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe's presence, position (after restore, before the paid container) and the `--restart no` premise; does not execute it (docker unavailable), and does not establish the probe's own cost is literally zero — it is a container launch, ~1 s, no API key.

```bash
# runs/review-arms/crb-pipeline/run-host.sh:177-179
  docker run -d --name "$PROXY_NAME" --network "$EGRESS_NET" \
    --restart no "$PROXY_IMAGE" >/dev/null
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:511-515
  if ! in_cell_net 'curl -s -o /dev/null --max-time 15 https://api.anthropic.com/v1/models' >/dev/null 2>&1; then
    echo "$id: egress proxy is not answering — the sweep cannot reach the API." >&2
```

Pinned structurally by `test/crb-egress-config.bats:194-205`, which passed.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:177-179`, `runs/review-arms/crb-pipeline/run-host.sh:507-516`, `docs/reviews/execution-logs/2026-08-19-r2-crb-suites.log`

---

## Claim 19: "Nothing resets it afterwards — the NEXT cell's `--restore` above wipes and re-extracts it … (This comment used to say 'the tree reset below', which survived the deletion of the reset it referred to.)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:521-526`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the A12 correction of the stale "reset below" wording; does not cover the *last* cell of a sweep, whose clone is left as written until some later sweep restores it.

The restore does sit above (`:501`) and the only wipe is inside it:

```python
# scripts/crb-materialize.py:403-407
    dst = DST_ROOT / slug
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True)
    sh(["tar", "--extract", "--file", str(tar), "-C", str(dst)])
```

Nothing between the container exit and the end of the loop body touches the clone (paraphrased — no quote available because the claim covers the absence of a reset across `run-host.sh:548-655`; the harvest and audit are read-only/containerised).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:501`, `runs/review-arms/crb-pipeline/run-host.sh:521-526`, `scripts/crb-materialize.py:403-410`

---

## Claim 20: "The audit publishes THREE states … 0 clean, 1 VOID … anything else 'could not check'. … This file already gets that distinction right twice (crb-cell-status.py above, the harvest just now), both times by aborting the sweep rather than guessing."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:593-607`
**Type:** Error-handling / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tri-state branch and the "matches the other two consumers" comparison; does **not** establish that spend is correctly ledgered on the new abort path — on `exit 4` the in-flight attempt's cost never reaches `attempts.jsonl` (the append at `:654` is below the abort), so a *retry* attempt's cost is dropped from `sweep_spend_ok`. That is a consequence of the fix, not a claim it makes, and the sweep halts anyway.

```bash
# runs/review-arms/crb-pipeline/run-host.sh:605-613
        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha" || audit_rc=$?
  if [ "$audit_rc" -gt 1 ]; then
    echo "$id: containment audit could not run (exit $audit_rc) — NOT a void." >&2
    ...
    exit 4
  fi
  if [ "$audit_rc" -eq 1 ]; then
```

The "already right twice" comparison holds — cell-status:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:461-462
      *) echo "$id: crb-cell-status.py invocation error — $cell_status" >&2
         exit 4 ;;
```

and the harvest:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:580
      echo "$id: HARVEST invocation failed — see above" >&2; exit 4; }
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:455-462`, `runs/review-arms/crb-pipeline/run-host.sh:578-580`, `runs/review-arms/crb-pipeline/run-host.sh:593-624`, `runs/review-arms/crb-pipeline/run-host.sh:645-655`

---

## Claim 21: "A void is a paid cell whose result cannot be used. Exiting 0 on a sweep that voided anything reads as success" (i.e. a sweep that voided any cell exits 6)

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:669-682`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the exit-6 path's trigger condition; does not cover `run-meta.json`'s `voided_cells`, which uses the same marker and is consistent.

The condition is not "this sweep voided" but "the output directory contains any `CONTAINMENT_FAILED` marker":

```python
# runs/review-arms/crb-pipeline/run-host.sh:675-676
print(sum(1 for n in os.listdir(out)
          if os.path.isfile(os.path.join(out, n, "CONTAINMENT_FAILED"))))
```

Nothing ever removes the marker — a repo-wide grep finds one writer (`: > "$dest/CONTAINMENT_FAILED"` at `:614`) and three readers, no `rm` (paraphrased — no quote available because the claim covers the absence of a deletion: `rg CONTAINMENT_FAILED` over `*.sh`/`*.py` returns `run-host.sh:346`, `:614`, `:676` and `crb-pipeline-to-benchmark.py:242` only). So a later resumed sweep that voids nothing — or that runs zero cells — still exits 6 on a stale marker from a previous sweep. Precise version: "a sweep exits 6 if any cell in `$OUT` carries a void marker, from this sweep or an earlier one."

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:614`, `runs/review-arms/crb-pipeline/run-host.sh:669-682`, `scripts/crb-pipeline-to-benchmark.py:242`

---

## Claim 22: "The comparison is against the baseline index written by `crb-materialize.py --snapshot`" / "no baseline index at {index_path} — run `crb-materialize.py --snapshot` for this slug"

**Location:** `scripts/crb-harvest-artifacts.py:19-20`, `scripts/crb-harvest-artifacts.py:102-103`
**Type:** Reference / Staleness
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers two references to a CLI mode; does not affect the harvest's behaviour, which reads the index by path.

`--snapshot` was removed by this same commit — the argparse option is gone and a bats case asserts its absence:

```python
# scripts/crb-materialize.py:512-516
    # There is deliberately NO mode that baselines an EXISTING clone. The one
    # that existed (--snapshot) was the last place host `git` ran against a
```

Yet the file this commit edited still names it, including in an operator-facing error message:

```python
# scripts/crb-harvest-artifacts.py:102-103
        print(f"no baseline index at {index_path} — run "
              f"`crb-materialize.py --snapshot` for this slug", file=sys.stderr)
```

An operator following that message gets `unrecognized arguments`. Both sites should read `--slug <id> --force`, matching `run-host.sh:432` and `:502`. The commit's R1 claim that "both remediation messages" now point at `--slug <id> --force` is true of the runner's two messages but not of this third one.

**Evidence:** `scripts/crb-harvest-artifacts.py:19-20`, `scripts/crb-harvest-artifacts.py:96-104`, `scripts/crb-materialize.py:512-527`, `test/crb-disposable-clone.bats:326-333`

---

## Claim 23: "Runs ONLY on trees no container has touched: the freshly cloned tree inside materialize(), and a temp extract of the baseline under --verify."

**Location:** `scripts/crb-materialize.py:192-199`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all call sites of `verify_containment`, `scrub_object_store` and `snapshot_baseline` in the shipped code; does not cover the test harness, which calls `scrub_object_store` directly on a fixture.

Both call sites are as described — the fresh clone:

```python
# scripts/crb-materialize.py:460-462
    scrub_object_store(dst)

    n_commits, stat = verify_containment(dst, slug, head)
```

reached only after `materialize()` has thrown away any pre-existing directory:

```python
# scripts/crb-materialize.py:414-419
    if dst.exists():
        if not force:
            print(f"{slug}: exists, skipping (use --force to rebuild)")
            return None
        shutil.rmtree(dst)
```

and the `--verify` temp extract:

```python
# scripts/crb-materialize.py:592-594
                    with tempfile.TemporaryDirectory(prefix=f"crb-verify-{slug}-") as tmp:
                        sh(["tar", "--extract", "--file", str(tar), "-C", tmp])
                        n_commits, stat = verify_containment(Path(tmp), slug, head)
```

`--verify` never touches the work clone. `snapshot_baseline` has exactly one caller, `materialize()` at `:488` (paraphrased — no quote available because the claim covers a grep result set: the only `snapshot_baseline(` occurrences are the `def` at `:286` and the call at `:488`).

**Evidence:** `scripts/crb-materialize.py:192-199`, `scripts/crb-materialize.py:413-419`, `scripts/crb-materialize.py:455-488`, `scripts/crb-materialize.py:581-596`

---

## Claim 24: "(tar, index) for a slug. The ONE place this layout is defined."

**Location:** `scripts/crb-materialize.py:341`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the uniqueness assertion within `crb-materialize.py`; does not dispute the companion claim that `run-host.sh` stopped restating the layout, which is Verified (Claim 16).

The `--verify` branch, in the same file, re-derives the tar path by hand rather than calling `baseline_paths`:

```python
# scripts/crb-materialize.py:581
                    tar = BASELINE_ROOT / f"{slug}.tar"
```

The `.part` staging names are also spelled independently:

```python
# scripts/crb-materialize.py:302
    part = BASELINE_ROOT / f"{slug}.tar.part"
```
```python
# scripts/crb-materialize.py:310
    idx_part = BASELINE_ROOT / f"{slug}.index.json.part"
```

A reader acting on the docstring — changing the baseline filename convention in `baseline_paths` alone — would silently break `--verify`. Precise version: "the one place the (tar, index) *pair* is defined for external callers; `BASELINE_ROOT` at `:73` owns the directory, and `--verify` still spells `{slug}.tar` itself." Note the accompanying bats case (`test/crb-disposable-clone.bats:315-322`) only asserts the *runner* stopped restating the layout, so it cannot see this.

**Evidence:** `scripts/crb-materialize.py:73`, `scripts/crb-materialize.py:300-312`, `scripts/crb-materialize.py:340-348`, `scripts/crb-materialize.py:581`, `test/crb-disposable-clone.bats:311-322`

---

## Claim 25: "The index … was previously written non-atomically, hashed by nothing, and first required ~110 lines into the cell — i.e. AFTER the $10-40 review was paid" (and is now atomic + hashed + verified before the cell)

**Location:** `scripts/crb-materialize.py:326-334`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the atomic publish, the manifest field, and the verification's position relative to the paid container; does not re-measure the "~110 lines" figure against the parent commit precisely.

Atomic publish and hash:

```python
# scripts/crb-materialize.py:310-313
    idx_part = BASELINE_ROOT / f"{slug}.index.json.part"
    idx_part.write_text(json.dumps(index, indent=0, sort_keys=True) + "\n")
    idx_part.replace(idx_path)
    digest = sha256_file(tar)
```

Verification in `restore_clone`, i.e. before any container:

```python
# scripts/crb-materialize.py:396-402
    idx_got = sha256_file(idx_path)
    if idx_got != idx_want:
        raise RuntimeError(
            f"baseline INDEX sha256 mismatch (manifest {idx_want[:12]}…, file "
            f"{idx_got[:12]}…) — refusing to restore. Re-materialize this slug.")
```

`--restore` runs at `run-host.sh:501`; the paid `docker run` at `:532`; the harvest's first read of the index at `:579` (`"${_bl[1]}"`). The ordering claim holds. Four bats cases (tampered index, missing index, missing manifest field, hash recorded) passed in this run.

**Evidence:** `scripts/crb-materialize.py:300-336`, `scripts/crb-materialize.py:385-402`, `runs/review-arms/crb-pipeline/run-host.sh:501`, `runs/review-arms/crb-pipeline/run-host.sh:532`, `runs/review-arms/crb-pipeline/run-host.sh:578-580`, `docs/reviews/execution-logs/2026-08-19-r2-crb-suites.log`

---

## Claim 26: "widening leg 2 to accept HTTP 200, neutering leg 3 to `[ -n "$direct" ]`, and dropping `--internal` from `docker network create` each left 37/37 tests green … Each of those three mutations now fails a case below."

**Location:** `test/crb-egress-verdict.bats:5-13` (restated in `scripts/crb-egress-verdict.sh:6-14` as history only, and in the commit message's A1/A2 paragraph as a present claim)
**Type:** Behavioral (test-efficacy)
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether each of the three named mutations now fails a test. Two of three do. The `--internal` mutation, applied where the test-strategy pass applied it (the runner's `docker network create`), still fails nothing. The historical half of the sentence ("each left 37/37 green") is not disputed.

Three mutations were applied one at a time to the working tree and the suites re-run; the tree was restored to `1d8ea67` after each.

- **Drop `--internal` from `run-host.sh`'s `NET_CREATE_CMD`** — full suite still green apart from the pre-existing unrelated failure:

```
# docs/reviews/execution-logs/2026-08-19-r2-mutations.log
--- MUT A: drop --internal from run-host.sh NET_CREATE_CMD ---
not ok 183 only the three finding sections are emitted from the golden rubric
MUT_A not-ok count: 1
```

- **Accept HTTP 200 on a refusal leg** — caught:

```
--- MUT B: filter-blocks accepts HTTP 200 (crb-egress-verdict.sh) ---
not ok 6 MUTATION: accepting HTTP 200 from a non-allowlisted host FAILS
```

- **Neuter `no-direct-route`** — caught, twice:

```
--- MUT C: neuter no-direct-route (always pass) ---
not ok 9 MUTATION: any answer at all without the proxy FAILS
not ok 10 403 passes filter-blocks and FAILS no-direct-route
```

The reason is structural: `test/crb-egress-verdict.bats:32-36` mutates the *string handed to the verdict script*, not the command the runner builds, and `test/crb-egress-config.bats:116-118` only greps that `egress_leg internal-net` is present — which a `--internal`-less `NET_CREATE_CMD` leaves untouched. The new leg does catch the mutation, but only at runtime on a docker host; the claim as written says a *case* fails, and none does. Precise version: "two of the three mutations now fail a case; the `--internal` mutation is caught by the `internal-net` leg at runtime, not by the suite."

Commands: `bats test/*.bats` and `bats test/crb-egress-verdict.bats` after each mutation · cwd `/workspace` · MUT A exit 1 (1 pre-existing failure), MUT B exit 1, MUT C exit 1 · 2026-08-20T00:15:02Z. Working tree verified clean afterwards (`git status --porcelain` on both mutated files returned nothing).

**Evidence:** `test/crb-egress-verdict.bats:5-13`, `test/crb-egress-verdict.bats:26-36`, `test/crb-egress-config.bats:110-119`, `runs/review-arms/crb-pipeline/run-host.sh:175-177`, `docs/reviews/execution-logs/2026-08-19-r2-mutations.log`

---

## Claim 27: "Measured on the five materialized pilot clones: none ignores `docs/reviews/` specifically and two ignore other `docs/`-adjacent paths"

**Location:** `scripts/crb-harvest-artifacts.py:12-17`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `.gitignore` contents across all five materialized clones (root and nested); does not evaluate `.git/info/exclude` or a global gitignore, and does not re-check the 45 unmaterialized PRs.

A search across all 46 `.gitignore` files in the five clones finds no `docs/reviews`-matching pattern anywhere, and `docs`-matching patterns in exactly two clones (paraphrased — no quote available because the claim covers a multi-file grep result across five third-party trees): `grafana-PR79265/.gitignore` (`/docs/menu.yaml`, `docs/AWS_S3_BUCKET`, …) and `sentry-greptile-PR5/.gitignore` (`/src/sentry/integration-docs`, `/tests/apidocs/...`). `cal_com`, `discourse-graphite` and `keycloak` have none.

The one imprecision worth noting: sentry's two are `apidocs`/`integration-docs`, which are "docs-adjacent" only under a loose reading; under a strict `docs/` reading the count is one, not two.

**Evidence:** `scripts/crb-harvest-artifacts.py:8-18`, `external/crb-eval/grafana-PR79265/.gitignore:15,54-57`, `external/crb-eval/sentry-greptile-PR5/.gitignore:25,32,36-39`

---

## Claim 28 (commit message): "A12/A13 — the stale disk figure, the 'tree reset below' comment, 'strictly more complete', **'exactly ONE reachable host'**, the audit's header example and exit legend, and the harvest's prevalence claim all corrected against what the fact-check measured."

**Location:** commit `1d8ea67` message, A12/A13 paragraph
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "exactly ONE reachable host" item only; the other five items in the same sentence are each Verified (Claims 6, 19, 3, 30, 27).

The k=3 report located that claim in the Dockerfile — `code-fact-check-report-r1.md:852` cites `runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-8`, and r2 cites `:3-8`. That file is not in this commit's diff, and the wording survives verbatim:

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-8
# every paid cell. Baking the CLI means a running cell needs exactly ONE
# reachable host, `api.anthropic.com`, which is what makes the allowlist a
# meaningful control rather than a gesture.
```

What was corrected is decision 034's paraphrase (Claim 2). The claim at its cited home is unchanged, and now contradicts 034. This is a **Stale** comment at `Dockerfile.review:6-8` and an **Incorrect** commit-message claim; they are reported together because they are one defect.

**Evidence:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:1-12`, `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:45-49`, `HEAD:docs/reviews/code-fact-check-report-r1.md:852`, `HEAD:docs/reviews/code-fact-check-report-r2.md:837`

---

## Claim 29 (commit message): "Tests: 439 total, +23 (12 verdict, 8 disposable-clone, 6 egress-config wiring, less the 3 replaced). The one failure, `only the three finding sections are emitted from the golden rubric`, is pre-existing and unrelated: it belongs to an uncommitted local edit to crb-pipeline-to-benchmark.py"

**Location:** commit `1d8ea67` message, Tests paragraph
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the total, the per-file component counts, the net delta, and the attribution of the single failure. The total and the failure attribution are correct; the `+23` delta is not. Splitting was not applied because the parts are one sentence's arithmetic and the most-severe part governs (decision 033) — the incorrect part is the delta.

**439 total and one failure — confirmed by execution.** `bats test/*.bats` reports `1..439` with exactly one `not ok`, the named test:

```
# docs/reviews/execution-logs/2026-08-19-r2-full-bats.log
not ok 183 only the three finding sections are emitted from the golden rubric
```

**Attribution — confirmed.** The working tree carries an uncommitted edit that removes exactly the section the test asserts:

```python
# git diff scripts/crb-pipeline-to-benchmark.py
-FINDING_SECTIONS = ("Must Fix", "Must Address", "Consider")
+# Exclude consider sections from review
+FINDING_SECTIONS = ("Must Fix", "Must Address") #, "Consider")
```

against the assertion `[ "$output" = "['consider', 'must address', 'must fix']" ]` at `test/crb-injector-sections.bats:48`. That file is not in `1d8ea67`.

**The delta is wrong.** Counting `@test` across top-level `test/*.bats` at the parent gives 413; at HEAD, 439 — a net **+26**, not +23 (paraphrased — no quote available because the figures are grep counts over 34 and 35 files respectively). The components are individually right: 12 new in `crb-egress-verdict.bats`, 8 added in `crb-disposable-clone.bats`, and in `crb-egress-config.bats` 7 added / 1 removed = net 6 "wiring". 12 + 8 + 6 = 26. The "less the 3 replaced" term double-counts: only **one** test was replaced (`the egress preflight tests both directions and blocks the sweep` → `…runs all five legs…`), and that removal is already netted out inside the 6.

Commands: `bats test/*.bats` · cwd `/workspace` · exit 1 (439 tests, 1 failure) · 2026-08-20T00:12Z. `git show 197eec6:<file> | grep -c '^@test'` summed over top-level test files · cwd `/workspace` · exit 0 · same session.

**Evidence:** `docs/reviews/execution-logs/2026-08-19-r2-full-bats.log`, `test/crb-injector-sections.bats:44-49`, `test/crb-egress-verdict.bats`, `test/crb-egress-config.bats`, `test/crb-disposable-clone.bats`

---

## Claim 30: "docker run --rm --network none -u node -v "$clone":/repo -v .../crb-audit-clone.sh:/audit.sh:ro --entrypoint bash <image> /audit.sh /repo <head-sha>" (header example) and "Exit: 0 = nothing detected · 1 = VOID · 2 = could not check (usage/no repo). … a `git fsck` that ERRORS exits 1, not 2"

**Location:** `scripts/crb-audit-clone.sh:12-38`
**Type:** Reference / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's docker example against the real invocation, the exit legend against the three exit sites, and the fsck asymmetry; does not cover the "counted in full" wording, which is Claim 31.

The example now matches the caller flag-for-flag, including the `-u node` and `--entrypoint bash` the prior version omitted:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:602-605
  docker run --rm --network none -u node \
        -v "$clone":/repo \
        -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha" || audit_rc=$?
```

and the `--entrypoint bash` rationale is correct:

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.review:28
ENTRYPOINT ["claude"]
```

The legend's "usage/no repo" is exact — all three `exit 2` sites are argument/`.git`/sha validation (`:41`, `:44`, `:46`), and the fsck-error path adds a trace rather than exiting 2:

```bash
# scripts/crb-audit-clone.sh:80-82
if printf '%s\n' "$fsck_out" | grep -q '^error:'; then
  note "git fsck errored ($(...)) — cannot certify containment"
fi
```

A populated `traces` array exits 1 (`:105-108`), so a fsck error voids — as documented.

**Evidence:** `scripts/crb-audit-clone.sh:12-46`, `scripts/crb-audit-clone.sh:75-82`, `scripts/crb-audit-clone.sh:105-112`, `runs/review-arms/crb-pipeline/run-host.sh:602-605`, `runs/review-arms/crb-pipeline/docker/Dockerfile.review:28`

---

## Claim 31: "strays are counted rather than adjudicated … (Foreign commits are counted in full but only the first is named, to keep the trace readable when a fetch brought in many.)"

**Location:** `scripts/crb-audit-clone.sh:24-28`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the audit's output actually contains for foreign commits; does not dispute the total-stray count, which *is* printed on the clean path.

`n_foreign` is incremented for every foreign commit, but the variable is never printed anywhere — only the first commit is named, with no count:

```bash
# scripts/crb-audit-clone.sh:89-96
n_strays=0; n_foreign=0
for c in $strays; do
  n_strays=$((n_strays+1))
  if ! git merge-base --is-ancestor "$HEAD_SHA" "$c" >/dev/null 2>&1; then
    n_foreign=$((n_foreign+1))
    [ "$n_foreign" -gt 1 ] || note "commit ${c:0:12} is reachable outside the reviewed head and does NOT descend from it"
  fi
done
```

`n_strays` is reported on the clean path (`:110`); `n_foreign` is computed and discarded. So "counted in full" is true of the loop and false of the trace a human reads. This is a softer version of the same defect A13 flagged in the prior wording ("every stray is reported"). Precise version: "…counted internally but not reported; only the first foreign commit is named, and the foreign count does not appear in the trace."

**Evidence:** `scripts/crb-audit-clone.sh:24-28`, `scripts/crb-audit-clone.sh:84-96`, `scripts/crb-audit-clone.sh:105-112`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`docs/working/crb-direction1-setup.md:98-99`): "the sweep exits 5" — a failing egress leg exits **1**. Fix follows from Claim 13.
- **Claim 13** (`runs/review-arms/crb-pipeline/run-host.sh:220-224`): `exit 5` and the `(refusing to spend)` message are unreachable — `set -euo pipefail` kills the script on the unguarded `bash "$VERDICT" … | sed` pipeline. Append `|| true` to the pipeline (or wrap in `set +e`/`set -e`) before reading `PIPESTATUS`. **This is the highest-value finding of the pass**: a comment crediting a line with an effect it does not have, in this commit's own new code.
- **Claim 22** (`scripts/crb-harvest-artifacts.py:19-20`, `:102-103`): still directs operators to `crb-materialize.py --snapshot`, deleted by this same commit. Replace with `--slug <id> --force`.
- **Claim 24** (`scripts/crb-materialize.py:341`): "The ONE place this layout is defined" is falsified by `:581` (and the two `.part` names at `:302`/`:310`). Either route `--verify` through `baseline_paths()` or soften the docstring.
- **Claim 26** (`test/crb-egress-verdict.bats:12`, and the commit message's A1/A2 paragraph): "Each of those three mutations now fails a case" — dropping `--internal` from the runner's `docker network create` still leaves the suite green (executed). Either add a bats case that greps `NET_CREATE_CMD` for `--internal`, or restate the claim as "two of three; the third is caught at runtime only".
- **Claim 28** (commit message, A12/A13): "'exactly ONE reachable host' … corrected" — corrected only in decision 034; the claim survives verbatim at its cited home, `docker/Dockerfile.review:6-8`, where it now contradicts 034.
- **Claim 29** (commit message, Tests): "+23 … less the 3 replaced" — the real net is **+26** (413 → 439). The `439 total` figure and the pre-existing-failure attribution are both correct.

### Stale
- **Claim 11** (`runs/review-arms/crb-pipeline/run-host.sh:208`): section header still says "PROVE the allowlist, three ways"; five legs run. Every other statement of the count was updated.
- **Claim 28** (`runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-8`): "a running cell needs exactly ONE reachable host" — same defect as the commit-message entry above, counted once.

### Mostly Accurate
- **Claim 1** (`docs/decisions/034-…:51`): "`PREFLIGHT_ONLY=1` runs exactly that and stops" — it also runs the auth preflight, which bills a turn.
- **Claim 9** (`docs/working/crb-direction1-setup.md:117-121`): the "$0" claim is cashed by a command that bills one auth turn; the runner discloses this, the doc does not.
- **Claim 21** (`runs/review-arms/crb-pipeline/run-host.sh:669-682`): exit 6 fires on any `CONTAINMENT_FAILED` marker in `$OUT`, including stale ones from earlier sweeps — nothing ever removes the marker.
- **Claim 31** (`scripts/crb-audit-clone.sh:27`): foreign commits are counted in a variable that is never printed; the trace names only the first, with no count.
- **Claim 20's scope note** (`runs/review-arms/crb-pipeline/run-host.sh:602-607`): not a claim defect, but flagged for the orchestrator — on the new `exit 4` abort path the in-flight attempt's cost never reaches `attempts.jsonl`, so a retried cell's spend is dropped from `sweep_spend_ok`. The sweep halts, so the exposure is bounded to one cell.

### Unverifiable
None. Every claim in scope was resolvable statically or by execution; the docker-shaped claims in scope (Claims 1, 10, 18) were verdicted on their *structural* content only, with the runtime half explicitly excluded in each `Scope` field rather than left as a false Verified.

---

## Hallucination-pattern log

No entry appended. The five Incorrect verdicts are a dead code path (13), two stale references to a just-deleted mode and a just-corrected doc (22, 28), a falsified uniqueness assertion (24), a refuted test-efficacy claim (26), and a miscount (29). None asserts a symbol, method, API or parameter that does not exist, which is the log's stated admission criterion.

---

## Goal-Alignment Note
- **Answered:** yes — commit `1d8ea67` fact-checked end to end against the eleven claim families the brief named; all four reds and the nine claimed ambers traced to the code that exercises them.
- **Out of scope:** parent `197eec6` and the rest of the branch (context only, per the brief); `docs/working/crb-egress-and-disposable-clones-plan.md`, which still describes `--heal` and a pre-2026-08-19 world but was not touched by this commit; the runtime behaviour of anything docker-shaped (no docker in this sandbox — the egress legs, the proxy, the audit container, the review cell).
- **Escalate:** (1) **Claim 13** — the egress preflight's `exit 5` is dead code; it fails closed at exit 1 but the documented protocol, the operator message, and two docs are all refuted. This is a new mechanism error introduced by this commit's own fix, i.e. exactly the recurrence the loop was watching for, and it should gate the paid sweep. (2) **Claim 26** — the `--internal` mutation still survives the suite, so the commit's confidence line ("high on A1-A5 … each is pinned by a test written as the mutation it must catch") overstates coverage for the one flag the containment story rests on. (3) **Claim 29** — the commit message's test delta is wrong by 3; worth correcting since the rubric's Confirmed-Good row from iteration 1 was "the commit message's count is exact".
