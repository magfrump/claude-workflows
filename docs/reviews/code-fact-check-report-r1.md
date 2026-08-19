# Code Fact-Check Report

**Repository:** /workspace (branch `feat/crb-direction1-harness`)
**Commit:** 197eec6
**Scope:** the single commit `197eec6` ("feat(crb): egress allowlist + disposable clones (decision 034)") — 16 files: `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md`, `docs/working/crb-direction1-setup.md`, `docs/working/crb-egress-and-disposable-clones-plan.md`, `runs/review-arms/crb-pipeline/docker/*`, `runs/review-arms/crb-pipeline/run-host.sh`, `scripts/crb-audit-clone.sh`, `scripts/crb-harvest-artifacts.py`, `scripts/crb-materialize.py`, `test/crb-{audit-clone,disposable-clone,egress-config,harvest-artifacts}.bats`, and the commit message itself. The two >40% churn files (`scripts/crb-materialize.py`, `runs/review-arms/crb-pipeline/run-host.sh`) were evaluated on the resulting code, not the diff. Sibling commits on `main..HEAD` were read as context only.
**Checked:** 2026-08-19
**Total claims checked:** 26 (24 numbered; Claim 3 split into 3a/3b/3c on verdict divergence)
**Summary:** 12 verified, 8 mostly accurate, 2 stale, 2 incorrect, 2 unverifiable

**Hallucination-pattern log:** `docs/reviews/hallucination-patterns.md` was read before checking. Its two entries are both "a specific measured value quoted from a checked-in artifact set that does not contain it." Claims 1 and 3 in this report are of that shape (disk figures, clone sizes) and were checked against `runs/review-arms/crb/instances.json` directly; neither recurs the pattern — see those verdicts.

**Known and out of scope by instruction:** nothing docker-shaped has been executed (the authoring environment has no docker — probe captured at `docs/reviews/execution-logs/code-fact-check-r1-docker-probe.txt`). That absence is not reported as a defect; claims *about* what those artifacts will do are still checked against the files as written, and capped at Unverifiable where the mandatory-execution rule applies.

---

## Claim 1: "Disk roughly doubles: pilot ~670 MB → ~1.3 GB, `--all` ~6.5 → ~13 GB."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`
**Type:** Configuration / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arithmetic of both figures against the checked-in manifest and the tar-creation call; does not establish the actual on-disk size of a baseline tar, since no baseline has been built yet (`baseline_mb` is absent for all five records).

The pilot figure is exact. Summing `clone_mb` over the five records in the checked-in manifest gives 670:

```json
// runs/review-arms/crb/instances.json — clone_mb per slug
cal_com-PR11059 190 · discourse-graphite-PR4 33 · grafana-PR79265 125 · keycloak-PR36880 127 · sentry-greptile-PR5 195   (sum 670)
```
(paraphrased — no quote available because the values are scattered across a 5-record JSON object and read more clearly as a table than as a multi-fragment quote; recomputed with `python3 -c "sum(v['clone_mb'] ...)"` over the tracked file.)

The "doubles" mechanism holds: the baseline is an *uncompressed* tar of the same tree, so its size tracks the clone's —

```python
# scripts/crb-materialize.py:302
sh(["tar", "--create", "--file", str(part), "-C", str(dst), "."])
```

What is imprecise is the `--all` half. No `--all` run exists; `~6.5 GB` is an extrapolation from the pilot (670 MB / 5 = 134 MB × 50 ≈ 6.7 GB), and the pilot is not a random sample — `select()` takes the most-goldens-first PRs per project:

```python
# scripts/crb-materialize.py:160-162
ranked = sorted(by_repo[repo],
                key=lambda p: (-len(p[2]["golden_comments"]), p[0]))
sel.extend(ranked[: args.per_repo])
```

The precise version would mark the `--all` pair as a projection from a 5-PR non-random sample rather than a measurement. The same `~13 GB` figure appears in `scripts/crb-materialize.py:38` and is internally consistent.

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63-64`, `runs/review-arms/crb/instances.json`, `scripts/crb-materialize.py:302`, `scripts/crb-materialize.py:160-162`, `scripts/crb-materialize.py:38`
**Legibility-target:** for-author

---

## Claim 2: "R3 (nested clone) and A8 (a voided cell leaving a permanently dead clone) are closed structurally rather than by a flag or a message."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:65-66`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named items' mechanisms (nested-repo destruction on restore; restore running unconditionally at the top of every cell); does not establish that no *other* rubric item is affected, and does not cover the R3 on the 2026-08-18 rubric (the egress one), which is a different R3.

Nested clone: restore is a wipe-and-extract, not a repair, so a nested repository cannot survive —

```python
# scripts/crb-materialize.py:359-363
dst = DST_ROOT / slug
if dst.exists():
    shutil.rmtree(dst)
dst.mkdir(parents=True)
sh(["tar", "--extract", "--file", str(tar), "-C", str(dst)])
```

pinned by an executed test (`ok 3 restore destroys a nested clone of the answer key`, see log).

A8: the restore runs before every cell unconditionally, and the loop's precondition is now the *baseline*, not a healthy clone —

```bash
# runs/review-arms/crb-pipeline/run-host.sh:366, 413
[ -f "$CLONES/.baselines/$id.tar" ] || { ... skipped_bad ... }
python3 "$ROOT/scripts/crb-materialize.py" --restore "$id" || { ... }
```

so a cell voided at `run-host.sh:497-498` leaves a dirty clone that the next iteration deletes rather than a permanently failing one.

Note for scope: the 2026-08-19 rubric already records its R3 as `✅ Fixed` in iteration 3 (`git clean -qffdx`), so this commit re-closes an item that was not open — that does not make the claim false, only redundant.

**Evidence:** `scripts/crb-materialize.py:359-363`, `runs/review-arms/crb-pipeline/run-host.sh:363-369`, `runs/review-arms/crb-pipeline/run-host.sh:406-418`, `runs/review-arms/crb-pipeline/run-host.sh:493-512`, `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md:95`, `docs/reviews/execution-logs/code-fact-check-r1-bats.txt`
**Execution provenance:** `bats test/crb-disposable-clone.bats test/crb-audit-clone.bats test/crb-harvest-artifacts.bats test/crb-egress-config.bats` · cwd `/workspace` · exit 0 · 2026-08-19T23:02:47Z · output `docs/reviews/execution-logs/code-fact-check-r1-bats.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3a: "`git status --untracked-files=all` honours `.gitignore`, so a rubric written to an ignored path used to vanish."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:67-68` (restated at `scripts/crb-harvest-artifacts.py:11-14` and `runs/review-arms/crb-pipeline/run-host.sh:475-477`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the git-semantics half and the test's negative control; does not establish that any specific benchmark repo actually ignores `docs/reviews/` (see Claim 3c).

The test does not assume the git behaviour, it asserts it as a negative control before asserting the harvest's positive:

```bash
# test/crb-harvest-artifacts.bats:95-99
run git -C "$CLONE" status --porcelain --untracked-files=all
[[ "$output" != *"rubric.md"* ]]
harvest
[ "$status" -eq 0 ]
[ -f "$DEST/docs/reviews/rubric.md" ]
```

Executed and passing (`ok 22 an artifact written to a gitignored path is still harvested`).

**Evidence:** `test/crb-harvest-artifacts.bats:82-100`, `scripts/crb-harvest-artifacts.py:11-14`, `docs/reviews/execution-logs/code-fact-check-r1-bats.txt`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3b: "The harvest became **strictly** more complete."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:67`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the set-inclusion relation between the old git-based harvest and the new baseline-diff harvest for `.md`/`.json` files; does not dispute that the new harvest is more complete on the `.gitignore` axis (Claim 3a), only that the relation is *strict*.

Two categories the old harvest captured and the new one does not.

Symlinked artifacts. The old loop copied them, deliberately, as links:

```bash
# 197eec6^:runs/review-arms/crb-pipeline/run-host.sh:377-380
# --no-dereference so a symlink the agent left behind is copied as a link
# rather than followed into host files. ...
cp --no-dereference "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
```

The new one skips them entirely:

```python
# scripts/crb-harvest-artifacts.py:72-73
if fp.is_symlink() or not fp.is_file():
    continue
```

Size and count caps. The old harvest had none; the new one drops artifacts above them and stops the harvest at the aggregate cap:

```python
# scripts/crb-harvest-artifacts.py:110-119
if size > MAX_FILE_BYTES: ... skipped += 1; continue
if copied >= MAX_FILES or total + size > MAX_TOTAL_BYTES:
    print(f"  !! harvest cap reached ...") ; skipped += 1; break
```

Both narrowings are defensible and both are reported rather than silent, so the *conclusion* ("more complete on the axis that mattered") holds — but the stated relation "strictly more complete" is refuted, and a reader acting on it (e.g. assuming the new artifacts dir is a superset when reconciling a re-run against an old cell) is misled. The precise version: "more complete on ignored paths; narrower on symlinks and on artifacts above the 5 MB / 50 MB / 500-file caps."

Also note the old harvest already filtered to `.md`/`.json` (`197eec6^:run-host.sh:368-371`), so that dimension is unchanged and is not part of this finding.

**Evidence:** `scripts/crb-harvest-artifacts.py:39-46`, `scripts/crb-harvest-artifacts.py:70-73`, `scripts/crb-harvest-artifacts.py:110-119`, `197eec6^:runs/review-arms/crb-pipeline/run-host.sh:365-381`
**Legibility-target:** for-author

---

## Claim 3c: "Several benchmark repos ignore `docs/`-adjacent paths; the code-review skill writes its rubric under `docs/reviews/`."

**Location:** `scripts/crb-harvest-artifacts.py:13-14`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the "several benchmark repos" half can be checked from the repository as committed; does not dispute the second half.

`external/` is gitignored and no clone tree is present in this checkout (paraphrased — no quote available because the claim covers the absence of files: `external/crb-eval/` does not exist here, only `runs/review-arms/crb/instances.json` describing what would be cloned). Verifying "several benchmark repos ignore `docs/`-adjacent paths" requires materializing the clones (network + ~670 MB) and grepping their `.gitignore` files. The second half is checkable and true — the harvest test writes the rubric to exactly that path (`test/crb-harvest-artifacts.bats:92`, `echo '# rubric' > "$CLONE/docs/reviews/rubric.md"`). What would be needed: run `scripts/crb-materialize.py --per-repo 1` and grep the five clones' `.gitignore` files.

**Evidence:** `scripts/crb-harvest-artifacts.py:11-14`, `test/crb-harvest-artifacts.bats:88-92`, `runs/review-arms/crb/instances.json`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "`--reset` and `--heal` are gone; `--restore` and `--snapshot` replace them. R6 (no existing clone could pass the pre-run gate) dissolves with them."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:69-70`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removal of the two modes and the removal of the pre-run gate; does not establish what happens on a clone materialized *after* this commit (which gets a baseline automatically).

The first half is exact — a repo-wide grep finds no surviving `--reset`/`--heal` mode, `reset_clone`, `fetch_traces`, or `classify_strays` outside two retrospective comments (`scripts/crb-materialize.py:330`, `:479`) and one in the setup doc, and the pinning test passes (`ok 36 the runner restores from the baseline before every cell`, which asserts `grep -E 'crb-materialize\.py" --(reset|heal)'` finds nothing).

"R6 dissolves" is the imprecise half. R6's symptom was *"the harness as committed cannot run a single cell against any clone that currently exists."* That symptom survives in a milder form: all five checked-in manifest records lack `baseline_sha256`/`baseline_mb` (paraphrased — no quote available because the claim covers the absence of keys in a JSON object; `python3 -c "print(v.get('baseline_mb'))"` prints `None` for all five), so every existing clone still fails the new precondition —

```bash
# runs/review-arms/crb-pipeline/run-host.sh:366-369
[ -f "$CLONES/.baselines/$id.tar" ] || {
  echo "$id: no baseline — run scripts/crb-materialize.py --slug $id (or --snapshot $id" >&2
```

— and still requires a one-shot operator command before the arm can run, exactly the shape of the `--heal` remediation R6's fix introduced. The precise version: "the *gate* is gone; pre-2026-08-19 clones still need a one-shot `--snapshot`."

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:69-70`, `runs/review-arms/crb-pipeline/run-host.sh:363-369`, `runs/review-arms/crb-pipeline/run-host.sh:413-418`, `test/crb-egress-config.bats:101-108`, `runs/review-arms/crb/instances.json`, `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md:98`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-author

---

## Claim 5: "`scripts/crb-materialize.py --all           # all 50 (~6-7 GB)`"

**Location:** `docs/working/crb-direction1-setup.md:27`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the disk figure on this line; the surrounding command list on lines 28-30 was correctly updated by this commit.

This commit rewrote the three lines immediately below it to the new `--verify`/`--restore`/`--snapshot` modes but left the `--all` disk figure at its pre-baseline value:

```
# docs/working/crb-direction1-setup.md:27-30
scripts/crb-materialize.py --all           # all 50 (~6-7 GB)
scripts/crb-materialize.py --verify   <slug> # re-check the BASELINE (read-only)
scripts/crb-materialize.py --restore  <slug> # wipe + re-extract (what each cell does)
scripts/crb-materialize.py --snapshot <slug> # baseline a clone made before 2026-08-19
```

The same commit's other two statements of the figure both say roughly double:

```python
# scripts/crb-materialize.py:38
  scripts/crb-materialize.py --all                      # all 50 (~13 GB w/ baselines)
```

and `docs/decisions/034:63` ("`--all` ~6.5 → ~13 GB"). The setup doc is the one an operator sizing a disk would read.

**Evidence:** `docs/working/crb-direction1-setup.md:25-30`, `scripts/crb-materialize.py:38`, `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`
**Legibility-target:** for-author

---

## Claim 6: "an empty or commented-out filter file with FilterDefaultDeny would still *start* ... Assert both halves here so the image cannot be built in that state."

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:15-23`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the three `grep` assertions actually match the two files as committed and whether they catch the two named states; does not establish tinyproxy's runtime behaviour in the un-asserted state (that would need docker), and does not check that the allowlist *regex* matches any host.

The assertion is a build-failing `RUN` chain:

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:21-23
RUN grep -qE '^[[:space:]]*FilterDefaultDeny[[:space:]]+Yes' /etc/tinyproxy/tinyproxy.conf \
 && grep -qE '^[[:space:]]*Filter[[:space:]]+"/etc/tinyproxy/filter"' /etc/tinyproxy/tinyproxy.conf \
 && grep -qE '^[^#[:space:]]' /etc/tinyproxy/filter
```

Each of the three matches the committed files: `FilterDefaultDeny Yes` (`tinyproxy.conf:29`), `Filter "/etc/tinyproxy/filter"` (`tinyproxy.conf:25`), and the single non-comment allowlist line `^api\.anthropic\.com$` (`egress-allowlist:9`). A mistyped directive name or a fully commented-out filter file fails the chain, which is exactly the "both halves" the comment claims. `test/crb-egress-config.bats:36-43` re-asserts the first two on the host and passed (`ok 30`).

**Evidence:** `runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:15-23`, `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:22-29`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:9`, `test/crb-egress-config.bats:36-43`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "`FilterURLs Off` => the filter matches the HOST, which for a CONNECT request is the tunnel target. `FilterDefaultDeny` inverts the usual sense: entries are what is ALLOWED."

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:22-24`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the documented semantics of the two tinyproxy directives and the fact that the config sets them; does not establish the proxy's actual runtime filtering behaviour, which is what run-host.sh's preflight leg 2 exists to prove (and which cannot be run here — no docker).

Both directives are set as described:

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:25-29
Filter "/etc/tinyproxy/filter"
FilterURLs Off
FilterExtended On
FilterCaseSensitive Off
FilterDefaultDeny Yes
```

tinyproxy's documented semantics match the comment: with `FilterURLs Off` the filter is applied to the destination *host* rather than the full URL, and a CONNECT request's destination host is the tunnel target; `FilterDefaultDeny Yes` makes the filter file an allowlist (paraphrased — no quote available because this is tinyproxy's upstream `tinyproxy.conf(5)` semantics, not a fact resident in this repository). Confidence is Medium rather than High for that reason: the semantics come from outside the codebase, and the file is not exercised here. The allowlist file itself is consistent with a host-anchored regex under `FilterExtended On` — `^api\.anthropic\.com$` (`egress-allowlist:9`), which anchors the whole host and would not match `api.anthropic.com.evil.test`.

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:22-29`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:1-9`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "The proxy is reachable only from the internal `crb-inner` network, whose subnet run-host.sh pins so this line can be exact."

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:12-16`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pinning relationship between `Allow` and `EGRESS_SUBNET` and what happens when the env override is used; does not establish that no *other* container could join `crb-inner` and thereby fall inside the `Allow` range.

The two values do match today, and a test enforces the match:

```bash
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:16
Allow 172.31.250.0/24
# runs/review-arms/crb-pipeline/run-host.sh:99
EGRESS_SUBNET="${EGRESS_SUBNET:-172.31.250.0/24}"
```

```bash
# test/crb-egress-config.bats:52-53
subnet=$(grep -oE '^[[:space:]]*Allow[[:space:]]+[0-9./]+' "$DOCKER_DIR/tinyproxy.conf" | awk '{print $2}')
grep -q "EGRESS_SUBNET=\"\${EGRESS_SUBNET:-$subnet}\"" "$RUNNER"
```

(executed, `ok 31 the proxy tunnels 443 only and serves only the pinned subnet`).

What "pins" overstates: `EGRESS_SUBNET` is an overridable default, and `run-host.sh:96-98` explicitly invites the override ("Override only if it collides with something already on the machine"). An override desyncs the `Allow` line from the network — the proxy would then refuse the review container. That fails safe (preflight leg 1 exits 5 before any spend, `run-host.sh:202-204`), but the config comment does not say the pin is conditional on the env var being unset. The precise version: "whose default subnet run-host.sh pins; overriding `EGRESS_SUBNET` desyncs this line and the preflight's positive leg will fail."

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:12-16`, `runs/review-arms/crb-pipeline/run-host.sh:96-99`, `runs/review-arms/crb-pipeline/run-host.sh:202-205`, `test/crb-egress-config.bats:45-54`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-author

---

## Claim 9: "Baking the CLI means a running cell needs exactly ONE reachable host, `api.anthropic.com`."

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-8` (restated at `runs/review-arms/crb-pipeline/run-host.sh:140-143` and `docs/decisions/034:44-46`)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the claim can be settled from the repository; the *npm* half of the rationale (baking removes `registry.npmjs.org` from the per-cell path) is separately verified below.

The npm half is verified statically: the CLI is installed at build time, before the restricted network exists —

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.review:18-19
RUN npm install -g "@anthropic-ai/claude-code@${CC_VERSION}" \
 && npm cache clean --force
```

and no `npx -y @anthropic-ai/claude-code` survives in the runner (`test/crb-egress-config.bats:56-63`, executed, `ok 32`).

The "exactly one reachable host" half is an executable guarantee about a running cell — what a headless Claude Code invocation contacts at startup (version/telemetry endpoints, error reporting, DNS resolution of the proxy name on an `--internal` network). Per the mandatory-execution rule the verdict is capped at Unverifiable. **Blocker:** docker is not installed in this environment (`command -v docker` → exit 1; probe log below), so neither the image nor the network can be built. The repository itself contains the instrument that would settle it — the auth/skill preflight deliberately runs a real headless invocation inside `$EGRESS_NET`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:235-240
preflight=$(docker run --rm -u node -e ANTHROPIC_API_KEY \
  --network "$EGRESS_NET" \
  -e HTTPS_PROXY="$PROXY_URL" ... "$REVIEW_IMAGE" \
```

What would be needed: run `run-host.sh` on a docker host through the preflight (it costs one short headless call, and exits before any paid cell). The commit message already names the same two open assumptions (HTTPS_PROXY honoured; docker embedded DNS on `--internal`).

**Evidence:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:3-19`, `runs/review-arms/crb-pipeline/run-host.sh:140-150`, `runs/review-arms/crb-pipeline/run-host.sh:225-242`, `test/crb-egress-config.bats:56-63`, `docs/reviews/execution-logs/code-fact-check-r1-docker-probe.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "each leg is separate because they fail for different reasons — a single test passing for the wrong reason is how this harness has gone wrong before."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:194-196`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the discriminating power of the three legs as written against each other; does not establish that any leg produces its expected code at runtime (no docker — see Claim 9).

As a *set* the claim holds: leg 1 fails when the tunnel to the API is broken, leg 2 when the filter is not filtering, leg 3 when the network is not internal, and each exits 5 —

```bash
# runs/review-arms/crb-pipeline/run-host.sh:202-204, 211-213, 220-222
[ "$api_code" != "000" ] || { echo "  FAIL: api.anthropic.com unreachable through the proxy ..."; exit 5; }
  *) echo "  FAIL: github.com returned HTTP $gh_code through the proxy — the allowlist is NOT filtering." >&2 ... exit 5 ;;
[ "$direct" = "000" ] || { echo "  FAIL: github.com returned HTTP $direct with NO proxy env ..."; exit 5; }
```

What is imprecise is "separate" at the individual-leg level. Leg 2 accepts `000` as evidence of refusal:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:209-210
case "$gh_code" in
  403|000) echo "  ok  github.com refused through the proxy (HTTP $gh_code)" ;;
```

`000` is curl's "no HTTP status obtained" and is produced equally by a filter-refused CONNECT, a dead proxy, a DNS failure on `crb-egress-proxy`, and a 25-second timeout. So leg 2 alone can pass for the wrong reason; it is leg 1 (which demands a non-`000` code through the same proxy) that rules the wrong reasons out. The precise version: the three legs are jointly sufficient, and leg 2's `000` acceptance is discriminating only because leg 1 has already run.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:190-223`, `test/crb-egress-config.bats:110-119`
**Legibility-target:** for-author

---

## Claim 11: "The clone is mounted read-write on purpose ... Artifacts are harvested and the tree reset below, so re-runs start from the same state."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:423-425`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "reset below" half of the sentence; the read-write mount rationale and the "re-runs start from the same state" conclusion are both still true.

There is no reset below this comment. The remainder of the loop body is: harvest the transcript (`:453-471`), harvest artifacts (`:478-480`), run the containerised audit (`:490-509`), print a summary (`:514-524`), ledger the attempt (`:529-539`), and check the sweep budget (`:544-569`) — no restore, no reset (paraphrased — no quote available because the claim covers the absence of a call across a ~150-line loop body; verified by reading `run-host.sh:449-570` and by `grep -n 'restore' run-host.sh`, whose only loop-body hit is line 413, above this comment).

The commit's own replacement comment thirty lines later states the correct mechanism:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:510-512
# The clone is left as the container wrote it; the NEXT cell's --restore wipes
# it. Nothing on the host touches it in between, and a voided cell no longer
# leaves a permanently dead clone (2026-08-19 A8).
```

This is a survivor of the pre-197eec6 wording (the old runner did reset in place after harvesting) that the commit did not update. The conclusion still holds via a different mechanism, so a reader is misled only about *where* the reset happens — but that "where" is the entire point of the disposable-clone change.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:423-425`, `runs/review-arms/crb-pipeline/run-host.sh:406-413`, `runs/review-arms/crb-pipeline/run-host.sh:449-570`, `runs/review-arms/crb-pipeline/run-host.sh:510-512`, `197eec6^:runs/review-arms/crb-pipeline/run-host.sh:382-396`
**Legibility-target:** for-author

---

## Claim 12: "Nothing below reads `.git`." (of the artifact harvest)

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:477` (restated at `scripts/crb-harvest-artifacts.py:10`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the harvest script's own tree walk and the host commands in `run-host.sh` after the container exits; does not cover the operator-invoked `--snapshot` path (Claim 20).

The harvest prunes `.git` at every depth before any file is read:

```python
# scripts/crb-harvest-artifacts.py:64-65
dirs[:] = [d for d in dirs
           if d != ".git" and not (Path(root) / d).is_symlink()]
```

and nothing in it shells out to git (paraphrased — no quote available because the claim covers the absence of a call: `grep -n 'git' scripts/crb-harvest-artifacts.py` matches only `.git` string literals and comment prose, no `subprocess`/`os.system` at all — the module imports `hashlib, json, os, shutil, sys, pathlib` only, `:32-37`).

Pinned by two executed tests: `ok 24 repository internals are never harvested` and the runner-level `ok 35 the runner never runs host git against the work clone`, the latter asserting that no `git ... "$clone"` or `git -C "$CLONES` line exists in the runner (`test/crb-egress-config.bats:94-99`).

**Evidence:** `scripts/crb-harvest-artifacts.py:32-37`, `scripts/crb-harvest-artifacts.py:60-65`, `test/crb-harvest-artifacts.bats:102-111`, `test/crb-egress-config.bats:92-99`, `docs/reviews/execution-logs/code-fact-check-r1-bats.txt`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "RUNS INSIDE A THROWAWAY CONTAINER, never on the host ... run-host.sh invokes it as: `docker run --rm --network none -v "$clone":/repo -v .../crb-audit-clone.sh:/audit.sh:ro <image> bash /audit.sh /repo <head-sha>`"

**Location:** `scripts/crb-audit-clone.sh:4-13`
**Type:** Architectural / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the single production invocation in `run-host.sh` and the documented command line's fidelity to it; does not cover the test suite, which drives the script directly on the host (documented at `test/crb-audit-clone.bats:25-27`).

The containment properties the header claims are all true of the real call — `--rm`, `--network none`, the two mounts with the script read-only, and no API key:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:493-496
if ! docker run --rm --network none -u node \
      -v "$clone":/repo \
      -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
      --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha"; then
```

pinned by `test/crb-egress-config.bats:79-90` (executed, `ok 34 the audit container has no network and no key`).

Two discrepancies in the quoted command, both in the direction of "the documented form would not work": the real call needs `--entrypoint bash`, because the review image sets `ENTRYPOINT ["claude"]` (`docker/Dockerfile.review:28`) — the header's `<image> bash /audit.sh ...` would invoke `claude bash /audit.sh /repo <sha>`. It also omits `-u node`. The precise version is the line at `run-host.sh:493-496` verbatim.

**Evidence:** `scripts/crb-audit-clone.sh:4-13`, `runs/review-arms/crb-pipeline/run-host.sh:490-496`, `runs/review-arms/crb-pipeline/docker/Dockerfile.review:26-28`, `test/crb-egress-config.bats:79-90`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-author

---

## Claim 14: "every stray is reported, and only contamination changes the exit code."

**Location:** `scripts/crb-audit-clone.sh:19-21`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what check 4 prints for each class of stray commit; does not dispute the exit-code half, which is correct.

The exit-code half is exact and tested (`ok 12 an agent commit on top of the head does NOT void`, `ok 13 a surviving remote VOIDS`).

"Every stray is reported" is looser than the code. Strays that descend from the reviewed head are counted, never named, and their count is printed **only on the clean path**:

```bash
# scripts/crb-audit-clone.sh:73-81
strays=$(git rev-list --all --not "$HEAD_SHA" 2>/dev/null)
n_strays=0; n_foreign=0
for c in $strays; do
  n_strays=$((n_strays+1))
  if ! git merge-base --is-ancestor "$HEAD_SHA" "$c" >/dev/null 2>&1; then
```

```bash
# scripts/crb-audit-clone.sh:95
echo "audit clean — no contamination detected (${n_strays} agent commit(s) on top of the head)"
```

Non-descending strays are also reported only once, however many there are:

```bash
# scripts/crb-audit-clone.sh:79
    [ "$n_foreign" -gt 1 ] || note "commit ${c:0:12} is reachable outside the reviewed head and does NOT descend from it"
```

So on a voided cell the descendant-stray count never appears in the record at all. The precise version: "every stray is *counted*; non-descending strays name the first one; the count prints only when the audit passes."

**Evidence:** `scripts/crb-audit-clone.sh:19-21`, `scripts/crb-audit-clone.sh:69-81`, `scripts/crb-audit-clone.sh:90-96`, `test/crb-audit-clone.bats:63-69`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-author

---

## Claim 15: "Exit: 0 = nothing detected · 1 = VOID (contamination) · 2 = could not check."

**Location:** `scripts/crb-audit-clone.sh:23`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three exit paths in the script; does not cover how `run-host.sh` interprets them (it treats any non-zero as a void, `run-host.sh:493-498`).

Exit 2 is reached only from the two usage guards — wrong argument count, non-hex sha, missing `.git` (`:26-32`) — pinned by `ok 19 usage errors exit 2, distinct from a void`. But the script's *own* "could not check" case, a `git fsck` that errors out, exits **1**, not 2:

```bash
# scripts/crb-audit-clone.sh:65-67
if printf '%s\n' "$fsck_out" | grep -q '^error:'; then
  note "git fsck errored (...) — cannot certify containment"
fi
```

`note` appends to `traces`, and any non-empty `traces` exits 1 (`:90-93`). The test asserts exactly that (`test/crb-audit-clone.bats:122-131`: a truncated object store → `[ "$status" -eq 1 ]`). This is deliberate and the inline comment at `:63-64` says why ("a check that could not run is the failure mode this file exists to avoid") — the header's one-line legend is what is imprecise. The precise version: "2 = usage/invocation error; a check that could not run voids (1) rather than reporting 2."

**Evidence:** `scripts/crb-audit-clone.sh:23`, `scripts/crb-audit-clone.sh:26-32`, `scripts/crb-audit-clone.sh:60-67`, `scripts/crb-audit-clone.sh:90-97`, `test/crb-audit-clone.bats:120-140`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-author

---

## Claim 16: "Belt and braces on top of the container boundary — none of the commands below trigger hooks or a fsmonitor today, and these overrides mean that stays true if one is added later."

**Location:** `scripts/crb-audit-clone.sh:34-42`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the four git subcommands the script runs and the precedence of the `-c` overrides; does not establish that a future git version will not add a hook or fsmonitor trigger to one of them.

Every git invocation goes through the wrapper, with the overrides ahead of `-C`:

```bash
# scripts/crb-audit-clone.sh:40-42
git() { command git -c safe.directory="$CLONE" -c core.hooksPath=/dev/null \
                    -c core.fsmonitor= -c protocol.ext.allow=never \
                    -C "$CLONE" "$@"; }
```

The commands it then runs are `git remote` (`:48`), `git fsck --unreachable --no-reflogs --connectivity-only --no-progress` (`:60`), `git rev-list --all --not "$HEAD_SHA"` (`:73`), and `git merge-base --is-ancestor` (`:77`). None of these refreshes the index or performs a checkout/ref-transaction, which is what fsmonitor and the `post-checkout`/`reference-transaction` hooks respectively key off (paraphrased — no quote available because this is git's own trigger model, documented in `githooks(5)` and `git-config(1)` `core.fsmonitor`, not a fact resident in this repository — hence Medium confidence). Command-line `-c` outranks repository config, so a hostile `.git/config` cannot re-enable them. Check 5 uses `find`, not git (`:87`), so it is outside the wrapper and also outside the claim.

The one command that reads the *object store* rather than refs, `git fsck`, is exercised against a deliberately corrupted store by `test/crb-audit-clone.bats:122-131` and reports rather than executes anything (executed, `ok 18`).

**Evidence:** `scripts/crb-audit-clone.sh:34-42`, `scripts/crb-audit-clone.sh:48`, `scripts/crb-audit-clone.sh:60`, `scripts/crb-audit-clone.sh:73-77`, `scripts/crb-audit-clone.sh:87`, `test/crb-audit-clone.bats:120-131`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "Symlinks are never followed and never indexed, in either direction: a symlinked directory is the one way an `os.walk` could leave the clone." / "`os.walk(followlinks=False)`"

**Location:** `scripts/crb-materialize.py:268-272` and `scripts/crb-harvest-artifacts.py:22-25`, `:60`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers directory-symlink descent and file-symlink indexing/copying in both walkers; does not cover a hardlink to a file outside the clone, which neither walker can distinguish.

Both walkers pass `followlinks=False` and additionally prune symlinked directories and skip symlinked files:

```python
# scripts/crb-harvest-artifacts.py:60-73 (identical shape at scripts/crb-materialize.py:272-283)
for root, dirs, files in os.walk(clone, followlinks=False):
    dirs[:] = [d for d in dirs
               if d != ".git" and not (Path(root) / d).is_symlink()]
    ...
        if fp.is_symlink() or not fp.is_file():
            continue
```

`followlinks=False` is the mechanism the comment credits, and it is the operative one for escape: it is what stops descent into a symlinked directory (the `dirs[:]` symlink filter is belt-and-braces for the same case, since symlinked dirs are not themselves indexed). The escape case is exercised end-to-end — a symlink to `/etc/passwd` and a symlink to a directory outside the clone both yield `harvested 0 artifact(s)` and nothing under `$DEST` (`test/crb-harvest-artifacts.bats:115-126`, executed, `ok 25`), and the index side by `ok 7 artifact_index covers .md/.json, skips .git, and ignores symlinks`.

The paired comment at `scripts/crb-harvest-artifacts.py:61-63` — "Same exclusions as `artifact_index()` in crb-materialize.py, and they must stay the same" — is also accurate: the two `dirs[:]` expressions and the two file guards are textually identical.

**Evidence:** `scripts/crb-materialize.py:257-284`, `scripts/crb-harvest-artifacts.py:22-25`, `scripts/crb-harvest-artifacts.py:57-80`, `test/crb-harvest-artifacts.bats:113-126`, `test/crb-disposable-clone.bats:153-167`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "Clones are SHALLOW (--depth, default 50) ... Measured on the 5-PR pilot: 33-195 MB each (see clone_mb in the manifest)."

**Location:** `scripts/crb-materialize.py:18-20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the depth default and the quoted range against the tracked manifest; does not establish that a re-materialization today would reproduce those sizes.

Depth default:

```python
# scripts/crb-materialize.py:469
ap.add_argument("--depth", type=int, default=50, help="shallow clone depth (default 50)")
```

and the clone is made with it (`:387`, `f"--depth={depth}"`). The manifest's five `clone_mb` values are 33, 125, 127, 190, 195 — min 33, max 195, matching the stated range exactly (paraphrased — no quote available because the values are spread across a 5-record JSON object; read with `python3 -c` over `runs/review-arms/crb/instances.json`). This is the claim-shape the hallucination log flags (a measured value quoted from a checked-in artifact set); here the artifact set does contain it.

**Evidence:** `scripts/crb-materialize.py:18-20`, `scripts/crb-materialize.py:387`, `scripts/crb-materialize.py:469`, `runs/review-arms/crb/instances.json`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "So the host does not read a used `.git` at all." (module docstring, disposable-clone rationale)

**Location:** `scripts/crb-materialize.py:22-32` (restated at `runs/review-arms/crb-pipeline/run-host.sh:49-54` and `:406-411`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the automated per-cell path in `run-host.sh` — restore, review, harvest, audit; does not cover the operator-invoked `--snapshot` mode, which does run host git against whatever clone is on disk (Claim 20).

Restore is `rmtree` + `tar`, with no git anywhere in it:

```python
# scripts/crb-materialize.py:359-365
dst = DST_ROOT / slug
if dst.exists():
    shutil.rmtree(dst)
dst.mkdir(parents=True)
sh(["tar", "--extract", "--file", str(tar), "-C", str(dst)])
if not (dst / ".git").is_dir():
```

`--verify` reads the hash-pinned *baseline*, extracted to a tempdir, not the work clone:

```python
# scripts/crb-materialize.py:551-553
with tempfile.TemporaryDirectory(prefix=f"crb-verify-{slug}-") as tmp:
    sh(["tar", "--extract", "--file", str(tar), "-C", tmp])
    n_commits, stat = verify_containment(Path(tmp), slug, head)
```

Harvest reads no `.git` (Claim 12); the audit runs in a container (Claim 13). The only host `git` calls in the runner target `$ROOT` (the workspace repo) — `git archive`, `rev-parse` at `run-host.sh:94`, `:126-128` — never `$clone`. Pinned by `ok 35 the runner never runs host git against the work clone` (executed).

**Evidence:** `scripts/crb-materialize.py:22-32`, `scripts/crb-materialize.py:327-366`, `scripts/crb-materialize.py:534-555`, `runs/review-arms/crb-pipeline/run-host.sh:94`, `runs/review-arms/crb-pipeline/run-host.sh:126-128`, `test/crb-egress-config.bats:92-99`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "Runs on a clone this script just built from the fork, before any container has seen it, which is the only reason it is safe to run host `git` here."

**Location:** `scripts/crb-materialize.py:236-237` (`scrub_object_store` docstring)
**Type:** Architectural / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two call sites of `scrub_object_store`; does not claim the second call site is *wrong*, only that the docstring's statement of where the function runs is refuted by it.

There are two call sites, not one. The first matches the docstring (`materialize()`, `:416`, on a clone the function just cloned). The second does not:

```python
# scripts/crb-materialize.py:511-527 (the --snapshot CLI mode)
elif args.snapshot:
    dst = DST_ROOT / slug
    if not (dst / ".git").is_dir():
        raise RuntimeError(f"no clone at {dst}")
    ...
    # Clears materialize()'s own FETCH_HEAD and any dangling
    # origin/HEAD, so the baseline starts from the same state a
    # freshly materialized clone would.
    scrub_object_store(dst)
```

That path runs `git symbolic-ref -d`, `git reflog expire --all` and `git gc --prune=now` (`:242-245`) against an arbitrary pre-existing clone directory — precisely the class of host-git-against-foreign-`.git` the commit exists to eliminate. The runner actively routes operators there for leftover clones:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:415-417
echo "    A clone materialized before 2026-08-19 has no baseline yet. If no" >&2
echo "    container has ever run against it, build one once:" >&2
echo "      python3 scripts/crb-materialize.py --snapshot $id" >&2
```

The precondition is enforced only by prose — `snapshot_baseline`'s "ONLY EVER CALL THIS ON A CLONE NO CONTAINER HAS TOUCHED" (`:290`), the `--snapshot` help text (`:465-468`), and the runner's "If no container has ever run against it" caveat. Nothing in the code checks it. A reader acting on this docstring's stated mechanism ("the only reason it is safe") would conclude the function is unreachable from a container-written tree; it is reachable, by an operator following the runner's own instructions. The precise version: "Runs from `materialize()` on a freshly built clone, and from `--snapshot`, where the pristine precondition is the operator's to guarantee."

**Evidence:** `scripts/crb-materialize.py:225-246`, `scripts/crb-materialize.py:416`, `scripts/crb-materialize.py:287-296`, `scripts/crb-materialize.py:465-468`, `scripts/crb-materialize.py:511-530`, `runs/review-arms/crb-pipeline/run-host.sh:413-418`
**Legibility-target:** for-author

---

## Claim 21: "Load-bearing for the AUDIT ... materialize()'s own fetches write both, so unless they are cleared here EVERY baseline would carry them and EVERY cell would void — and the checks would mean nothing. Clearing them is what makes their later presence evidence."

**Location:** `scripts/crb-materialize.py:229-234` (restated at `:413-415`)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the causal link between the two scrub actions and the two audit checks they enable; does not establish that a real materialized clone is FETCH_HEAD-free (no clone exists here), only that the code clears both and that the audit checks fire on their presence.

The scrub clears exactly the two artefacts the audit keys on:

```python
# scripts/crb-materialize.py:244-246
sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
(dst / ".git" / "FETCH_HEAD").unlink(missing_ok=True)
```

and the audit voids on both:

```bash
# scripts/crb-audit-clone.sh:55, 60-62
[ ! -e "$CLONE/.git/FETCH_HEAD" ] || note "FETCH_HEAD present — something fetched into this clone"
fsck_out=$(git fsck --unreachable --no-reflogs --connectivity-only --no-progress 2>&1)
unreachable=$(printf '%s\n' "$fsck_out" | grep -c '^unreachable commit' || true)
[ "${unreachable:-0}" -eq 0 ] || note "$unreachable unreachable commit(s) ..."
```

`materialize()` does fetch twice before the scrub (`:387-389`, clone + `refs/pull/1/head`) and `resolve_base()` may fetch again (`:171`), so the "materialize()'s own fetches write both" premise holds. The audit suite's setup mirrors the scrub explicitly (`test/crb-audit-clone.bats:50-52`) and `ok 11 a pristine clone audits clean` passes, which is the non-vacuity the claim asserts; the mirror-image case is pinned by `ok 20 the unreachable-commit check is non-vacuous only because of --no-reflogs`.

**Evidence:** `scripts/crb-materialize.py:225-246`, `scripts/crb-materialize.py:387-391`, `scripts/crb-materialize.py:413-416`, `scripts/crb-audit-clone.sh:51-62`, `test/crb-audit-clone.bats:48-61`, `test/crb-audit-clone.bats:142-158`
**Execution provenance:** as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "materialize() calls it immediately after verify_containment(); the CLI mode refuses to overwrite an existing baseline without --force."

**Location:** `scripts/crb-materialize.py:293-295` (`snapshot_baseline` docstring)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering inside `materialize()` and the `--force` guard in the `--snapshot` CLI path; does not cover whether the guard is sufficient to prevent laundering a used clone (it is not — see Claim 20).

Ordering in `materialize()`: `verify_containment` at `:418`, `snapshot_baseline` at `:444`, with only manifest-record assembly between them:

```python
# scripts/crb-materialize.py:439-444
    # Snapshot LAST, and only after verify_containment has passed: ...
    rec.update(snapshot_baseline(dst, slug))
```

CLI guard:

```python
# scripts/crb-materialize.py:519-523
if (BASELINE_ROOT / f"{slug}.tar").exists() and not args.force:
    raise RuntimeError(
        "a baseline already exists. Re-snapshotting is only correct "
        "on a clone NO container has run against — pass --force if "
        "that is true, or re-materialize with --slug --force.")
```

**Evidence:** `scripts/crb-materialize.py:287-296`, `scripts/crb-materialize.py:416-444`, `scripts/crb-materialize.py:511-523`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "Tests: 37 new across four suites (disposable-clone, audit-clone, harvest-artifacts, egress-config)"

**Location:** commit message `197eec6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the four suite names; does not assess coverage adequacy.

The four files declare 9 + 10 + 9 + 9 = 37 `@test` blocks, all four files are added by this commit (`git show --stat 197eec6` lists them as new), and running all four yields `1..37`, 37 `ok`, 0 `not ok`, exit 0 (paraphrased — no quote available because the evidence is a 37-line TAP stream plus a `git show --stat` listing; both are captured, the former at the log path below).

**Evidence:** `test/crb-disposable-clone.bats`, `test/crb-audit-clone.bats`, `test/crb-harvest-artifacts.bats`, `test/crb-egress-config.bats`, `docs/reviews/execution-logs/code-fact-check-r1-bats.txt`
**Execution provenance:** `bats test/crb-disposable-clone.bats test/crb-audit-clone.bats test/crb-harvest-artifacts.bats test/crb-egress-config.bats` · cwd `/workspace` · exit 0 · 2026-08-19T23:02:47Z · output `docs/reviews/execution-logs/code-fact-check-r1-bats.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: "test/crb-containment-reset.bats removed with the code it pinned, its load-bearing void cases carried into crb-audit-clone."

**Location:** commit message `197eec6`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping from the removed file's VOID-asserting tests to counterparts in `test/crb-audit-clone.bats`; does not cover the removed file's non-void (reset/undo) cases, which the commit explicitly does not claim to have carried.

The removed file declared five VOID cases. Four map one-to-one (paraphrased — no quote available because the mapping is between two files' `@test` name lists, obtained with `git show 197eec6^:test/crb-containment-reset.bats | grep '^@test'` and `grep '^@test' test/crb-audit-clone.bats`):

| removed (`197eec6^:test/crb-containment-reset.bats`) | counterpart (`test/crb-audit-clone.bats`) |
|---|---|
| `a re-added remote still VOIDS the cell` (:145) | `a surviving remote VOIDS` (:71) |
| `a bare fetch by URL leaves FETCH_HEAD and VOIDS` (:202) | `a FETCH_HEAD trace VOIDS` (:79) |
| `r1's exact attack: fetch by URL, delete the ref, commit on top — VOIDS` (:186) | `a fetched-then-deleted ref VOIDS via the unreachable commit` (:89) |
| `a commit outside the reviewed ancestry still VOIDS the cell` (:153) | `a commit that does not descend from the head VOIDS` (:102) |
| `a tag pointing outside the reviewed ancestry still VOIDS the cell` (:385) | **no counterpart** |

The tag case has no direct successor. The underlying mechanism is still covered — `git rev-list --all` walks `refs/tags` as well as `refs/heads`:

```bash
# scripts/crb-audit-clone.sh:73
strays=$(git rev-list --all --not "$HEAD_SHA" 2>/dev/null)
```

and the surviving `does not descend from the head` case exercises the same branch via an orphan *branch* (`test/crb-audit-clone.bats:103`, `git -C "$CLONE" checkout -q --orphan foreign`). So the code path is pinned; the ref-type-specific regression case is not. The audit suite's own header enumerates five load-bearing cases and does not include the tag one (`test/crb-audit-clone.bats:10-20`) — i.e. the omission is a deliberate re-scoping, not an oversight, but "its load-bearing void cases carried into crb-audit-clone" reads as complete carry-over and is not. The precise version would say "four of five, plus a new nested-repository case; the tag variant is covered by mechanism rather than by its own case."

The first half of the claim is exact: `test/crb-containment-reset.bats` is deleted (396 lines, per `git show --stat 197eec6`) and the code it pinned (`reset_clone`, `fetch_traces`, `classify_strays`, `--reset`, `--heal`) is gone from the tree.

**Evidence:** `197eec6^:test/crb-containment-reset.bats:145`, `:153`, `:186`, `:202`, `:385`, `test/crb-audit-clone.bats:10-20`, `test/crb-audit-clone.bats:71-118`, `scripts/crb-audit-clone.sh:69-81`
**Legibility-target:** for-author

---

## Claims Requiring Attention

### Incorrect
- **Claim 20** (`scripts/crb-materialize.py:236-237`): `scrub_object_store`'s docstring says it "runs on a clone this script just built from the fork, before any container has seen it, which is the only reason it is safe to run host `git` here" — but the `--snapshot` CLI mode calls it at `:527` on any pre-existing clone directory, and `run-host.sh:415-417` tells operators to do exactly that on a leftover clone. Restate the docstring to name both call sites and mark the pristine precondition as operator-guaranteed, not code-guaranteed.
- **Claim 3b** (`docs/decisions/034:67`): "the harvest became **strictly** more complete" is refuted — the new harvest drops symlinked artifacts the old one copied with `cp --no-dereference`, and adds 5 MB / 50 MB / 500-file caps the old had none of. Drop "strictly" and name the two narrowings.

### Stale
- **Claim 5** (`docs/working/crb-direction1-setup.md:27`): `--all # all 50 (~6-7 GB)` predates the baseline tars; the same commit's `scripts/crb-materialize.py:38` and `docs/decisions/034:63` both say ~13 GB. Update the setup doc's figure.
- **Claim 11** (`runs/review-arms/crb-pipeline/run-host.sh:423-425`): "Artifacts are harvested and the tree reset below" — there is no reset below; the next cell's `--restore` at `:413` does it, as the commit's own comment at `:510-512` correctly states. Reword to point at the next cell.

### Mostly Accurate
- **Claim 1** (`docs/decisions/034:63`): pilot figure (670 MB) is exact; the `--all` pair is an extrapolation from a most-goldens-first 5-PR sample — label it a projection.
- **Claim 4** (`docs/decisions/034:69-70`): the pre-run *gate* is gone, but all five existing clones still need a one-shot operator `--snapshot` before the arm runs, which is the same shape as the `--heal` step R6's fix introduced.
- **Claim 8** (`runs/review-arms/crb-pipeline/docker/tinyproxy.conf:12-16`): `EGRESS_SUBNET` is an overridable default, not a pin; an override desyncs the `Allow` line (fails safe at preflight leg 1).
- **Claim 10** (`runs/review-arms/crb-pipeline/run-host.sh:194-196`): leg 2 accepts `000`, which is also produced by a dead proxy, a DNS failure, or a timeout — the legs are jointly, not individually, discriminating.
- **Claim 13** (`scripts/crb-audit-clone.sh:4-13`): the documented invocation omits `--entrypoint bash` and `-u node`; as written, `<image> bash /audit.sh ...` would run through the image's `ENTRYPOINT ["claude"]`.
- **Claim 14** (`scripts/crb-audit-clone.sh:19-21`): descendant strays are counted, not reported, and the count prints only on the clean path; non-descending strays name only the first.
- **Claim 15** (`scripts/crb-audit-clone.sh:23`): exit 2 covers usage errors only — an fsck that could not run exits 1 (deliberately, per `:63-64`), so the header legend's "2 = could not check" is misleading.
- **Claim 24** (commit message): four of the removed suite's five VOID cases have counterparts; the tag-outside-ancestry case does not (its mechanism is covered by the orphan-branch case).

### Unverifiable
- **Claim 9** (`runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-8`): "a running cell needs exactly ONE reachable host" is an executable guarantee about Claude Code's startup egress (telemetry, version checks, DNS on an `--internal` network). Blocker: docker is not installed here (probe log `docs/reviews/execution-logs/code-fact-check-r1-docker-probe.txt`). The repo already contains the instrument — `run-host.sh`'s in-network auth/skill preflight at `:235-242` — and it costs one short headless call before any paid cell.

---

## Goal-Alignment Note
- Answered: yes — 26 claims verdicted across the commit, report saved as specified
- Out of scope: everything docker-shaped stayed unexecuted per instruction (no docker in this environment) and is reported as Unverifiable rather than as a defect; sibling commits on `main..HEAD` were read for context only; `docs/working/crb-egress-and-disposable-clones-plan.md` carries only forward-looking plan text with no checkable behavioural claims not already covered by claims 1-24
- Escalate: Claim 20 is the one finding with a security shape rather than a documentation shape — `--snapshot` is a live host-git-against-arbitrary-`.git` path that the runner's own error message routes operators into, guarded only by prose. That is a code question for `security-reviewer`, not a comment fix, and it is the same class as R1/R2 the commit set out to close. Claim 9 (one reachable host) needs a docker host to settle and should gate the paid sweep.
