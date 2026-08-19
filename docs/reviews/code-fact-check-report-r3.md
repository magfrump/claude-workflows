# Code Fact-Check Report

**Repository:** `/workspace` (branch `feat/crb-direction1-harness`)
**Commit:** 197eec6
**Scope:** the single commit `197eec6` (`git show 197eec6`) — 16 files: `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md`, `docs/working/crb-direction1-setup.md`, `docs/working/crb-egress-and-disposable-clones-plan.md`, `runs/review-arms/crb-pipeline/docker/{Dockerfile.proxy,Dockerfile.review,egress-allowlist,tinyproxy.conf}`, `runs/review-arms/crb-pipeline/run-host.sh`, `scripts/{crb-materialize.py,crb-audit-clone.sh,crb-harvest-artifacts.py}`, `test/crb-{audit-clone,disposable-clone,egress-config,harvest-artifacts}.bats`, `test/crb-containment-reset.bats` (deleted), plus the commit message. The two >40%-churn files (`scripts/crb-materialize.py`, `runs/review-arms/crb-pipeline/run-host.sh`) are evaluated against the resulting code, not the diff. Sibling commits on the branch were consulted as context only.
**Checked:** 2026-08-19
**Total claims checked:** 34
**Summary:** 22 verified, 7 mostly accurate, 2 stale, 2 incorrect, 1 unverifiable

**Hallucination-pattern log:** `docs/reviews/hallucination-patterns.md` was read before checking. Two logged patterns, both of the class *"a specific measured value quoted from a checked-in artifact set that does not contain it"* (`STUB_MAX_LEN` corpus statistic; `total_golden` 11/13). Claims 1, 23 and 25 in this report are of exactly that class — quoted disk/size figures sourced from checked-in artifacts — and were each recomputed from the artifacts rather than accepted. None matched a logged pattern.

**Execution note.** Nothing docker-shaped could be executed (no docker in this environment, as the commit message and `docs/decisions/034` both state). Per the skill's mandatory-execution rule, executable guarantees that require docker or tinyproxy are capped at Unverifiable, with the blocker named. What *was* executed: the four new bats suites, a from-scratch reproduction of `materialize()`'s object-store state, and read-only inspection of the five existing pilot clones. Logs under `docs/reviews/execution-logs/`.

---

## Claim 1: "Disk roughly doubles: pilot ~670 MB → ~1.3 GB, `--all` ~6.5 → ~13 GB"

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pilot figure against the checked-in manifest and the clones on disk, and the `--all` figure as a linear extrapolation; does not establish that the 45 unmaterialized PRs have the same size distribution as the 5 pilot PRs.

The pilot base figure is exactly the sum of `clone_mb` in the checked-in manifest — 190 + 33 + 125 + 127 + 195 = 670:

```json
// runs/review-arms/crb/instances.json — clone_mb per slug
cal_com-PR11059 190 · discourse-graphite-PR4 33 · grafana-PR79265 125 · keycloak-PR36880 127 · sentry-greptile-PR5 195
```

Measured apparent size on disk today is 705 MB total (`docs/reviews/execution-logs/cfc-r3-disk-2026-08-19.txt`), consistent with "~670 MB" as a manifest-derived figure (`dir_mb()` sums file sizes and skips directory entries, which `du` counts).

The doubling follows from the baseline being an *uncompressed* tar of the same tree:

```python
# scripts/crb-materialize.py:302
sh(["tar", "--create", "--file", str(part), "-C", str(dst), "."])
```

so baseline_mb ≈ clone_mb and pilot total ≈ 1.34 GB. The `--all` figure is 670/5 × 50 = 6.7 GB base → ~13.4 GB with baselines; "~6.5 → ~13" rounds that (paraphrased — no quote available because the claim is arithmetic over the manifest values quoted above, not a snippet).

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`, `scripts/crb-materialize.py:298-324`, `runs/review-arms/crb/instances.json`, `docs/reviews/execution-logs/cfc-r3-disk-2026-08-19.txt`
Executed: `du -sm --apparent-size external/crb-eval/*`, cwd `/workspace`, exit 0, 2026-08-19T23:09:53Z.

---

## Claim 2: "R3 (nested clone) and A8 (a voided cell leaving a permanently dead clone) are closed structurally rather than by a flag or a message"

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:65-66`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether a nested repo and a voided cell's clone are removed by the new mechanism regardless of any flag; does not establish that a nested clone is *detected* before the wipe (it is, separately, by the audit) nor that the review it produced is discarded.

A nested repository no longer needs `git clean -ff` to be removed, because the whole tree is deleted:

```python
# scripts/crb-materialize.py:359-363
dst = DST_ROOT / slug
if dst.exists():
    shutil.rmtree(dst)
dst.mkdir(parents=True)
sh(["tar", "--extract", "--file", str(tar), "-C", str(dst)])
```

Pinned by test: *"restore destroys a nested clone of the answer key"* asserts `[ ! -d "$CLONE/vendor" ]` (`test/crb-disposable-clone.bats:110-118`), which passed.

A8: the voided clone is not repaired but is not left dead either — the next cell's restore recreates it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:510-512
# The clone is left as the container wrote it; the NEXT cell's --restore wipes
# it. Nothing on the host touches it in between, and a voided cell no longer
# leaves a permanently dead clone (2026-08-19 A8).
```

and the restore is unconditional at the top of each cell (`runs/review-arms/crb-pipeline/run-host.sh:413`).

**Evidence:** `scripts/crb-materialize.py:348-366`, `runs/review-arms/crb-pipeline/run-host.sh:406-418`, `runs/review-arms/crb-pipeline/run-host.sh:510-512`, `test/crb-disposable-clone.bats:110-118`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/crb-audit-clone.bats test/crb-disposable-clone.bats test/crb-harvest-artifacts.bats test/crb-egress-config.bats`, cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z, 37 ok / 0 not ok.

---

## Claim 3: "The harvest became strictly more complete: `git status --untracked-files=all` honours `.gitignore`, so a rubric written to an ignored path used to vanish."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:67-68`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the file sets the old and new harvests capture; does not establish anything about the artifacts' downstream use by the injector.

The `.gitignore` half is correct and is proven by execution (see Claim 21). The word **strictly** is what overstates it: the new harvest captures *less* than the old one in two cases the old had no equivalent of.

(a) Caps. The old loop copied every matching path with no ceiling; the new one stops:

```python
# scripts/crb-harvest-artifacts.py:115-119
if copied >= MAX_FILES or total + size > MAX_TOTAL_BYTES:
    print(f"  !! harvest cap reached ({copied} files, {total} bytes) — "
          f"remaining artifacts NOT captured", file=sys.stderr)
    skipped += 1
    break
```

(b) Symlinked artifacts. The old harvest copied them (as links); the new one skips them:

```python
# scripts/crb-harvest-artifacts.py:72-73
if fp.is_symlink() or not fp.is_file():
    continue
```

against the old:

```bash
# runs/review-arms/crb-pipeline/run-host.sh@197eec6^:380
cp --no-dereference "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
```

Both differences are deliberate hardening and both are reported rather than silent, so the practical conclusion (the new harvest sees the artifacts that matter, and the old one dropped some) holds; "strictly more complete" is the imprecision. A precise version: *"more complete on the case that mattered — gitignored paths — at the cost of refusing symlinks and capping total volume, both reported."*

**Evidence:** `scripts/crb-harvest-artifacts.py:39-46`, `scripts/crb-harvest-artifacts.py:66-80`, `scripts/crb-harvest-artifacts.py:107-125`, `runs/review-arms/crb-pipeline/run-host.sh@197eec6^:360-381`

---

## Claim 4: "`--reset` and `--heal` are gone; `--restore` and `--snapshot` replace them. R6 (no existing clone could pass the pre-run gate) dissolves with them."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:69-70`
**Type:** Architectural / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether R6's reported symptom (no clone that currently exists can run a cell; `ran=0` → exit 3) is reachable from the shipped code with the checked-in manifest and the five clones on disk; does not establish what happens after an operator runs `--snapshot` (that path does work).

The first sentence is correct — `--reset`/`--heal` are absent from the argument parser (`scripts/crb-materialize.py:451-471`) and from the runner, pinned by a test (`test/crb-egress-config.bats:106-107`, passed).

The R6 sentence is refuted. R6 was *"the harness as committed cannot run a single cell against any clone that currently exists… `run-host.sh` counts each as `skipped_bad` → `ran=0` → exit 3"* (`docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md:98`). The pre-run *gate* is indeed gone, but the precondition that replaced it reproduces the same symptom on the same five clones: the loop now requires a baseline tar, and none of the five has one (`external/crb-eval/.baselines/` does not exist):

```bash
# runs/review-arms/crb-pipeline/run-host.sh:366-369
[ -f "$CLONES/.baselines/$id.tar" ] || {
    echo "$id: no baseline — run scripts/crb-materialize.py --slug $id (or --snapshot $id" >&2
    echo "    if the clone already exists and no container has run against it)" >&2
    skipped_bad=$((skipped_bad+1)); continue; }
```

which feeds the identical terminal path:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:578-581
if [ "$ran" -eq 0 ] && [ "$skipped_bad" -gt 0 ]; then
  echo "NO CELL RAN and $skipped_bad instance(s) were unusable — not a clean sweep." >&2
  exit 3
fi
```

The remediation is also the same shape R6 was closed with: a one-shot, operator-run mode (`--snapshot`, previously `--heal`). So R6 did not dissolve; it was renamed. A reader acting on "dissolves" — running the sweep against the current clones expecting cells to execute — gets `exit 3` and zero cells. Precise version: *"R6's pre-run gate is gone; the equivalent precondition is now a missing baseline, remediated once per clone by `--snapshot`."*

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:69-70`, `runs/review-arms/crb-pipeline/run-host.sh:363-369`, `runs/review-arms/crb-pipeline/run-host.sh:574-581`, `scripts/crb-materialize.py:451-471`, `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md:98`, `docs/reviews/execution-logs/cfc-r3-pilot-clone-state-2026-08-19.txt`

---

## Claim 5: "`scripts/crb-materialize.py --all           # all 50 (~6-7 GB)`"

**Location:** `docs/working/crb-direction1-setup.md:27`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the disk figure quoted in the setup doc's Materialize section; does not re-examine the underlying measurement (Claim 1 does).

This commit added the baseline tars, which double the on-disk cost, and updated the figure in two other places but not here. The same command's cost is stated as roughly double in the script this line documents:

```python
# scripts/crb-materialize.py:38
  scripts/crb-materialize.py --all                      # all 50 (~13 GB w/ baselines)
```

and in the decision record:

```
# docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63
- Disk roughly doubles: pilot ~670 MB → ~1.3 GB, `--all` ~6.5 → ~13 GB.
```

The setup doc still reads `~6-7 GB`, the pre-baseline number. Fix: `~13 GB (clones + baselines)`.

**Evidence:** `docs/working/crb-direction1-setup.md:27`, `scripts/crb-materialize.py:38`, `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`

---

## Claim 6: "Fail closed at build time: … Assert both halves here so the image cannot be built in that state."

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:15-23`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether the assertion fires on the two failure modes the comment names (missing/mistyped `FilterDefaultDeny`, empty or fully-commented filter file); does not establish that the assertion covers other ways the filter can misbehave (notably `FilterURLs` — see Claim 10 — which the assertion does not check and does not claim to).

The two named halves are each asserted, and a failing `grep` fails the `RUN` because the three are `&&`-chained:

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:21-23
RUN grep -qE '^[[:space:]]*FilterDefaultDeny[[:space:]]+Yes' /etc/tinyproxy/tinyproxy.conf \
 && grep -qE '^[[:space:]]*Filter[[:space:]]+"/etc/tinyproxy/filter"' /etc/tinyproxy/tinyproxy.conf \
 && grep -qE '^[^#[:space:]]' /etc/tinyproxy/filter
```

The first pattern is case-sensitive and anchored, so a mistyped directive name does not match and the build fails — which is the "mistyped `FilterDefaultDeny`" case the comment names. The third pattern requires at least one line whose first character is neither `#` nor whitespace, which is the "empty or commented-out filter file" case. Both files as committed satisfy all three (`runs/review-arms/crb-pipeline/docker/tinyproxy.conf:25,29`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:9`), and the same three patterns are independently pinned by `test/crb-egress-config.bats:36-43` (passed).

**Evidence:** `runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:15-23`, `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:22-29`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:9`, `test/crb-egress-config.bats:36-43`

---

## Claim 7: "Baking the CLI means a running cell needs exactly ONE reachable host, `api.anthropic.com`"

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-8` (restated at `runs/review-arms/crb-pipeline/run-host.sh:140-143`, `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:44-46`, `docs/working/crb-direction1-setup.md:65-68`)
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what removing the per-cell `npx` install does to the required host set, and what this repository's own prior egress work records about Claude Code's host set; does not establish the runtime behaviour of CLI version 2.1.232 behind this proxy — that requires docker and is what the preflight is for.

The mechanism is right: the install moves to build time with normal network, so `registry.npmjs.org` leaves the per-cell path.

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.review:18-19
RUN npm install -g "@anthropic-ai/claude-code@${CC_VERSION}" \
 && npm cache clean --force
```

pinned negatively by `test/crb-egress-config.bats:56-63` (no `npx -y @anthropic-ai/claude-code` in the runner; passed).

"Exactly one" overstates the conclusion, on this repository's own evidence. The base egress profile used by the project's other Claude Code containment work lists six hosts as the minimum:

```
# devcontainer-config/egress/base.txt:6-14
# Claude Code itself: API, OAuth login, telemetry.
api.anthropic.com
claude.ai
console.anthropic.com
sentry.io
statsig.com
…
registry.npmjs.org
```

with only one of them marked as required:

```bash
# devcontainer-config/init-firewall.sh:139-146
# A dead domain must not brick session start (statsig.anthropic.com went
# NXDOMAIN in 2026-07 and did exactly that). Failing closed is safe here —
# the domain just stays unreachable — except api.anthropic.com, without
# which CC cannot run at all.
```

So "one host is *required*" is supported by prior in-repo evidence; "needs exactly one reachable host" reads as "reaches exactly one", and the cell will also attempt telemetry/error-reporting hosts that the allowlist refuses. Nothing in `Dockerfile.review` or `run-host.sh` sets `DISABLE_AUTOUPDATER`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, or equivalent (paraphrased — no quote available because the claim covers the absence of code: grep for those names across `/workspace` returns hits only in `devcontainer-config/` and an archived working doc, none in the files under review). Precise version: *"a running cell **requires** exactly one reachable host; non-essential traffic to the other Claude Code endpoints is refused by the proxy."* The preflight's live headless invocation (`runs/review-arms/crb-pipeline/run-host.sh:235-242`) is the right place this gets settled at $0.

**Evidence:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:1-19`, `runs/review-arms/crb-pipeline/run-host.sh:139-150`, `runs/review-arms/crb-pipeline/run-host.sh:225-263`, `devcontainer-config/egress/base.txt:6-14`, `devcontainer-config/init-firewall.sh:134-148`, `test/crb-egress-config.bats:56-63`

---

## Claim 8: "The proxy is reachable only from the internal `crb-inner` network, whose subnet run-host.sh pins so this line can be exact."

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:12-16`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the correspondence between the `Allow` line and the subnet the runner creates, including the override path; does not establish tinyproxy's runtime enforcement of `Allow` (docker/tinyproxy unavailable).

The correspondence holds for the default and is test-enforced:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:99
EGRESS_SUBNET="${EGRESS_SUBNET:-172.31.250.0/24}"
```

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:16
Allow 172.31.250.0/24
```

```bash
# test/crb-egress-config.bats:52-53
subnet=$(grep -oE '^[[:space:]]*Allow[[:space:]]+[0-9./]+' "$DOCKER_DIR/tinyproxy.conf" | awk '{print $2}')
grep -q "EGRESS_SUBNET=\"\${EGRESS_SUBNET:-$subnet}\"" "$RUNNER"
```

(passed). The imprecision: "run-host.sh pins" describes a *default*, not a pin — `EGRESS_SUBNET` is environment-overridable, and the runner's own comment invites overriding it (`runs/review-arms/crb-pipeline/run-host.sh:96-98`, "Override only if it collides with something already on the machine"), at which point the baked `Allow` line no longer covers the network. The failure is safe rather than silent — the proxy would deny the cell network, and preflight leg 1 exits 5 at $0 (`runs/review-arms/crb-pipeline/run-host.sh:201-204`) — and the bats test would not catch it, since it compares the file default only. Precise version: *"…whose subnet run-host.sh defaults to this value; overriding `EGRESS_SUBNET` without rebuilding the proxy image fails the preflight."*

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:12-16`, `runs/review-arms/crb-pipeline/run-host.sh:96-99`, `runs/review-arms/crb-pipeline/run-host.sh:198-205`, `test/crb-egress-config.bats:45-54`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/…` (four suites), cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 9a: "CONNECT to 443 only: … every other port [is] refused, so the tunnel cannot be repointed at an arbitrary service."

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the CONNECT-port half of the comment only; the plain-HTTP half is Claim 9b.

The directive is present exactly as described:

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:20
ConnectPort 443
```

and is pinned by `test/crb-egress-config.bats:46-47` (passed). Whether tinyproxy then refuses CONNECT to every other port is a property of the third-party daemon, and the blocker to establishing it is **execution: neither docker nor tinyproxy is installed in this environment** (`which tinyproxy` → not found; `/usr/share/doc/tinyproxy` absent), so the claim cannot be exercised. To verify it, add a fourth preflight leg attempting `CONNECT api.anthropic.com:8443` (or any non-443 port) through the proxy and asserting refusal — the same shape as the existing three legs, at $0.

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20`, `test/crb-egress-config.bats:45-54`, `runs/review-arms/crb-pipeline/run-host.sh:197-223`

---

## Claim 9b: "plain-HTTP proxying … [is] refused" [by `ConnectPort 443`]

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the stated mechanism (that `ConnectPort` governs plain-HTTP proxying); does not establish what a plain-HTTP request through this proxy actually returns — that needs execution, and the practical containment conclusion is separately carried by the `Filter` (see below).

The comment attributes the refusal of plain-HTTP proxying to `ConnectPort`:

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20
# CONNECT to 443 only: plain-HTTP proxying and every other port are refused, so
# the tunnel cannot be repointed at an arbitrary service.
ConnectPort 443
```

`ConnectPort` scopes the ports permitted for the **CONNECT method**; it does not govern ordinary proxied `GET http://host/…` requests, which take a different path through tinyproxy entirely. The runner exports `HTTP_PROXY`/`http_proxy` alongside the HTTPS variants (`runs/review-arms/crb-pipeline/run-host.sh:185-186`, `:435-436`), so plain-HTTP proxying is a live path for a cell, and nothing in this config file disables it.

The practical conclusion still holds, but by a different mechanism than the one stated: a plain-HTTP request is subject to the same host filter, which allows one host —

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:25-29
Filter "/etc/tinyproxy/filter"
FilterURLs Off
FilterExtended On
FilterCaseSensitive Off
FilterDefaultDeny Yes
```

— so `http://github.com/` is refused by the *filter*, not by `ConnectPort`. Per the compound-claim rule, a refuted mechanism keeps its verdict even when the conclusion holds: a reader who removes or widens `Filter` while trusting `ConnectPort` to block plain HTTP would be wrong. Precise version: *"`ConnectPort 443` limits the CONNECT method to 443; plain-HTTP proxying is left to the host filter, which allows the same single host."* The preflight's negative leg (leg 2) tests `https://github.com/` only, so it would not detect this either (`runs/review-arms/crb-pipeline/run-host.sh:208`).

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-29`, `runs/review-arms/crb-pipeline/run-host.sh:183-188`, `runs/review-arms/crb-pipeline/run-host.sh:206-214`, `runs/review-arms/crb-pipeline/run-host.sh:432-436`

---

## Claim 10: "`FilterURLs Off` => the filter matches the HOST, which for a CONNECT request is the tunnel target. `FilterDefaultDeny` inverts the usual sense: entries are what is ALLOWED, everything else is refused."

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:22-24`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the documented semantics of the three filter directives and the shape of the allowlist file they consume; does not establish runtime filtering behaviour (docker/tinyproxy unavailable — that is preflight leg 2's job).

Both directives are present and consistent with the allowlist file's own header, which is written as host regexes rather than URL regexes:

```
# runs/review-arms/crb-pipeline/docker/egress-allowlist:1-2,9
# Hosts a review cell may reach. Anchored regexes, matched against the CONNECT
# target host (FilterExtended On, FilterURLs Off).
^api\.anthropic\.com$
```

`FilterExtended On` selects POSIX extended regular expressions, under which `^…$` anchors the whole host, so the entry cannot match `api.anthropic.com.evil.example`. Exactly one non-comment line exists, asserted by test:

```bash
# test/crb-egress-config.bats:26-29
run grep -c '^[^#]' "$DOCKER_DIR/egress-allowlist"
[ "$output" = "1" ]
run grep '^[^#]' "$DOCKER_DIR/egress-allowlist"
[ "$output" = '^api\.anthropic\.com$' ]
```

(passed). Confidence is Medium rather than High because the directive semantics are third-party documentation, not code in this repository.

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:22-29`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:1-9`, `test/crb-egress-config.bats:25-43`

---

## Claim 11: "Checked after every cell, so the worst overshoot is SWEEP_BUDGET+BUDGET."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:80-82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the placement of the gate relative to the cell body and the ledger it sums; does not establish that `--max-budget-usd` is itself a hard ceiling on one cell's spend (that is a CLI property, not this code's).

The gate is the last statement in the loop body, after the attempt is ledgered:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:544
python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
```

and it sums `attempts.jsonl` across all cells, falling back to `result.json` for pre-ledger cells (`runs/review-arms/crb-pipeline/run-host.sh:548-566`), tripping at `total >= cap`. Since the check runs only between cells, the running total can exceed the cap by at most the cost of the cell in flight, which `--max-budget-usd "$BUDGET"` caps (`runs/review-arms/crb-pipeline/run-host.sh:444`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:80-90`, `runs/review-arms/crb-pipeline/run-host.sh:526-569`

---

## Claim 12: "each leg is separate because they fail for different reasons — a single test passing for the wrong reason is how this harness has gone wrong before."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:190-196`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the three legs have distinct failure causes and that each exits 5; does not establish that the legs pass at runtime (docker unavailable), nor that the three are exhaustive — Claim 9b names a fourth path (plain HTTP) no leg exercises.

The three legs test the proxy tunnel, the filter, and the network's internality, and each has its own exit:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:201-223  (abridged to the three predicates)
api_code=$(in_cell_net 'curl … https://api.anthropic.com/v1/models || echo 000')
[ "$api_code" != "000" ] || { …; exit 5; }
gh_code=$(in_cell_net 'curl … https://github.com/ || echo 000')
case "$gh_code" in 403|000) … ;; *) …; exit 5 ;; esac
direct=$(docker run --rm --network "$EGRESS_NET" --entrypoint bash "$REVIEW_IMAGE" -c 'curl … https://github.com/ || echo 000')
[ "$direct" = "000" ] || { …; exit 5; }
```

Leg 1 fails if the proxy or the tunnel is broken; leg 2 fails if the filter is not filtering; leg 3 fails if the network is not `--internal` (leg 3 removes the proxy env, so it tests routing rather than the proxy). Leg 2's acceptance of `000` (which is also leg 3's pass condition) is not a hole, because a dead proxy is caught by leg 1 first, which runs before it. The presence of all three legs and `exit 5` on each is pinned by `test/crb-egress-config.bats:110-118` (passed).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:190-223`, `runs/review-arms/crb-pipeline/run-host.sh:180-188`, `test/crb-egress-config.bats:110-118`

---

## Claim 13: "Artifacts are harvested and the tree reset below, so re-runs start from the same state."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:423-425`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the "reset below" half of the sentence against the resulting loop body; does not dispute the conclusion, which the relocated restore still delivers.

The comment survived the file's restructuring. Nothing below it in the loop body resets the tree — the reset moved to the *top* of the next iteration:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:413
  python3 "$ROOT/scripts/crb-materialize.py" --restore "$id" || {
```

and the code that now occupies the position "below" says so explicitly:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:510-511
  # The clone is left as the container wrote it; the NEXT cell's --restore wipes
  # it. Nothing on the host touches it in between…
```

Fix: *"Artifacts are harvested below and the tree is wiped by the next cell's `--restore`, so re-runs start from the same state."* (The stray bare `#` at `runs/review-arms/crb-pipeline/run-host.sh:426` is what remains of the removed sentence.)

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:406-418`, `runs/review-arms/crb-pipeline/run-host.sh:423-426`, `runs/review-arms/crb-pipeline/run-host.sh:510-512`

---

## Claim 14: "Nothing below reads `.git`."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:472-477`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers everything the host runs after the review container exits within the cell body; does not cover the audit, which reads `.git` deliberately but inside a container (Claim 15).

The three host steps after the container exits are the transcript parse (reads `$dest/transcript.jsonl` only, `runs/review-arms/crb-pipeline/run-host.sh:453-471`), the harvest, and a manifest read for the head sha:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:490-492
  head_sha=$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))[sys.argv[2]]["head"])' "$MANIFEST" "$id")
```

— the pinned head comes from the tracked manifest, not from the clone. The harvest walks the tree and excludes `.git` at every depth before descending:

```python
# scripts/crb-harvest-artifacts.py:64-65
dirs[:] = [d for d in dirs
           if d != ".git" and not (Path(root) / d).is_symlink()]
```

Pinned by two passing tests: *"repository internals are never harvested"* (`test/crb-harvest-artifacts.bats:102-113`) and the runner-level grep *"the runner never runs host git against the work clone"* (`test/crb-egress-config.bats:94-99`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:451-492`, `scripts/crb-harvest-artifacts.py:57-80`, `test/crb-harvest-artifacts.bats:102-113`, `test/crb-egress-config.bats:94-99`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/…` (four suites), cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 15: "Post-run audit, INSIDE a throwaway container … `--network none`, no API key."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:482-489`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the audit's invocation flags and the disposal of its container; does not establish that the audit's *checks* are complete (the same comment disclaims that, and Claim 20 covers one of them).

```bash
# runs/review-arms/crb-pipeline/run-host.sh:493-496
  if ! docker run --rm --network none -u node \
        -v "$clone":/repo \
        -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha"; then
```

`--rm` disposes it, `--network none` is present, and `ANTHROPIC_API_KEY` is not passed. Independently pinned by a test that parses the runner and asserts both properties on the audit's `docker run` line (`test/crb-egress-config.bats:79-90`, passed). The comment's characterisation of the audit as *"EVIDENCE, not the control"* matches the script's own closing line (`scripts/crb-audit-clone.sh:96`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:482-509`, `test/crb-egress-config.bats:79-90`, `scripts/crb-audit-clone.sh:95-96`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/…` (four suites), cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 16: "a voided cell no longer leaves a permanently dead clone (2026-08-19 A8)"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:510-512`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the clone's fate after a void; does not cover the cell's *result*, which is deliberately marked failed and excluded downstream.

The void path writes a marker and rewrites `result.json` but performs no repair and no deletion of the clone:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:497-508
    echo "$id: POST-RUN containment audit FAILED — voiding this cell" >&2
    : > "$dest/CONTAINMENT_FAILED"
    …
d["is_error"] = True
d["subtype"] = "containment_failed"
```

The next cell restores unconditionally, with no gate that a previously-voided clone could fail (`runs/review-arms/crb-pipeline/run-host.sh:413`); `restore_clone()` deletes and re-extracts regardless of the tree's state (`scripts/crb-materialize.py:359-363`). Downstream, the marker is what excludes the cell, not the clone's condition (`scripts/crb-pipeline-to-benchmark.py:242-243`, `scripts/crb-cell-status.py:74-75`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:493-512`, `scripts/crb-materialize.py:348-366`, `scripts/crb-pipeline-to-benchmark.py:242-243`, `scripts/crb-cell-status.py:74-75`

---

## Claim 17a: "RUNS INSIDE A THROWAWAY CONTAINER, never on the host."

**Location:** `scripts/crb-audit-clone.sh:4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every invocation of this script in the repository; does not prevent an operator from running it by hand on the host (nothing enforces the claim in code — it is a header statement, and the only in-repo caller honours it).

The only invocation is the containerised one quoted in Claim 15. Grepping the repository for other callers finds none outside tests (paraphrased — no quote available because the claim covers the absence of code: `crb-audit-clone.sh` appears in `runs/review-arms/crb-pipeline/run-host.sh:495`, `test/crb-audit-clone.bats:31`, and documentation only). The bats suite drives it directly on the host against fixture repos, which the file's own header anticipates:

```bash
# test/crb-audit-clone.bats:25-27
# The script runs inside a container in production. Nothing in it is
# docker-specific, so these tests drive it directly against fixture repos.
```

**Evidence:** `scripts/crb-audit-clone.sh:1-13`, `runs/review-arms/crb-pipeline/run-host.sh:493-496`, `test/crb-audit-clone.bats:25-31`, `test/crb-egress-config.bats:79-90`
Executed: `bats test/…` (four suites), cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z, log `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`.

---

## Claim 17b: "run-host.sh invokes it as: `docker run --rm --network none -v "$clone":/repo -v .../crb-audit-clone.sh:/audit.sh:ro <image> bash /audit.sh /repo <head-sha>`"

**Location:** `scripts/crb-audit-clone.sh:10-13`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the fidelity of the quoted command line to the real invocation; does not affect the surrounding claim about containerisation (Claim 17a).

The quoted line, run verbatim, would not execute the audit. The review image sets `ENTRYPOINT ["claude"]`:

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.review:28
ENTRYPOINT ["claude"]
```

so `<image> bash /audit.sh /repo <sha>` becomes `claude bash /audit.sh …`. The real call overrides the entrypoint and runs as `node`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:493-496
  if ! docker run --rm --network none -u node \
        -v "$clone":/repo \
        -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha"; then
```

Precise version: add `-u node` and `--entrypoint bash` before `<image>` and drop the standalone `bash`.

**Evidence:** `scripts/crb-audit-clone.sh:10-13`, `runs/review-arms/crb-pipeline/docker/Dockerfile.review:26-28`, `runs/review-arms/crb-pipeline/run-host.sh:493-496`

---

## Claim 18: "Exit: 0 = nothing detected · 1 = VOID (contamination) · 2 = could not check."

**Location:** `scripts/crb-audit-clone.sh:23`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the mapping between the three exit codes and the conditions that produce them; does not dispute the runner's handling, which treats any non-zero as a void and is the safe reading.

Exit 2 is reached only by the three pre-flight guards — wrong argument count, no `.git`, non-hex sha (`scripts/crb-audit-clone.sh:26-32`). The genuinely "could not check" case at runtime — `git fsck` itself erroring — exits **1**, not 2:

```bash
# scripts/crb-audit-clone.sh:63-67
# fsck's own errors must not be swallowed: a check that could not run is the
# failure mode this file exists to avoid.
if printf '%s\n' "$fsck_out" | grep -q '^error:'; then
  note "git fsck errored (…) — cannot certify containment"
fi
```

because `note` appends to `traces`, and any non-empty `traces` exits 1 (`scripts/crb-audit-clone.sh:90-94`). This is confirmed by execution: the test *"a corrupt object store reports 'cannot certify' rather than passing"* asserts `[ "$status" -eq 1 ]` (`test/crb-audit-clone.bats:122-131`, passed). Failing closed is the right behaviour; the header's legend is what is imprecise. Precise version: *"2 = the audit could not start (bad arguments, no `.git`); a check that runs but cannot certify (fsck errors) is reported as a void."*

**Evidence:** `scripts/crb-audit-clone.sh:23`, `scripts/crb-audit-clone.sh:26-32`, `scripts/crb-audit-clone.sh:60-67`, `scripts/crb-audit-clone.sh:90-96`, `test/crb-audit-clone.bats:120-140`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/…` (four suites), cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 19: "Belt and braces on top of the container boundary — none of the commands below trigger hooks or a fsmonitor today, and these overrides mean that stays true if one is added later."

**Location:** `scripts/crb-audit-clone.sh:34-42`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the git commands this script issues and the precedence of its `-c` overrides; does not establish behaviour for git versions other than the one in the review image, and does not cover the non-git `find` at `scripts/crb-audit-clone.sh:87`.

The wrapper applies the overrides to every git call in the file:

```bash
# scripts/crb-audit-clone.sh:40-42
git() { command git -c safe.directory="$CLONE" -c core.hooksPath=/dev/null \
                    -c core.fsmonitor= -c protocol.ext.allow=never \
                    -C "$CLONE" "$@"; }
```

`-c` is command-line configuration, which takes precedence over the repository's own `.git/config`, so a hostile `core.hooksPath` or `core.fsmonitor` in the clone is overridden rather than merged.

The commands actually issued through it are `remote` (`:48`), `fsck` (`:60`), `rev-list` (`:73`) and `merge-base --is-ancestor` (`:77`). None of these refreshes the index or checks out a tree, which is what invokes a fsmonitor; none of them is a checkout, commit, merge, push or receive, which is what runs hooks. The two commands the 2026-08-19 review executed out of — `git status` (fsmonitor) and `git checkout --force` / `clean` (hooks, `core.worktree`) — are absent (paraphrased — no quote available because the claim covers the absence of code: the file contains no `status`, `checkout`, `clean`, `gc`, `reset` or `fetch` invocation).

**Evidence:** `scripts/crb-audit-clone.sh:34-42`, `scripts/crb-audit-clone.sh:47-88`, `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md:93`

---

## Claim 20: "`--no-reflogs` is load-bearing: git fsck counts reflog entries as reachability roots, so without it a fetched commit whose ref was deleted still reads as reachable and this check is inert."

**Location:** `scripts/crb-audit-clone.sh:57-59` (restated at `docs/working/crb-direction1-setup.md:166-169`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the flag's effect on the unreachable-commit check under git 2.39.5; does not establish that the check catches every non-git retrieval route (it does not, and the file says so).

The flag is present in the audited command:

```bash
# scripts/crb-audit-clone.sh:60
fsck_out=$(git fsck --unreachable --no-reflogs --connectivity-only --no-progress 2>&1)
```

and non-vacuity is asserted by a test that runs both forms against the same fixture and requires the without-flag form to see nothing and the with-flag form to see the commit:

```bash
# test/crb-audit-clone.bats:150-155
run git -C "$CLONE" fsck --unreachable --connectivity-only --no-progress
[[ "$output" != *"unreachable commit"* ]]
run git -C "$CLONE" fsck --unreachable --no-reflogs --connectivity-only --no-progress
[[ "$output" == *"unreachable commit"* ]]
```

That test passed in this session's run (test 28 of 37, `ok the unreachable-commit check is non-vacuous only because of --no-reflogs`).

**Evidence:** `scripts/crb-audit-clone.sh:57-62`, `test/crb-audit-clone.bats:142-158`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/crb-audit-clone.bats test/crb-disposable-clone.bats test/crb-harvest-artifacts.bats test/crb-egress-config.bats`, cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 21: "`--untracked-files=all` still honours `.gitignore`, so a rubric written to a path the upstream repo ignores was invisible."

**Location:** `scripts/crb-harvest-artifacts.py:11-14` (restated at `runs/review-arms/crb-pipeline/run-host.sh:475-477`, `scripts/crb-materialize.py:264-266`, `docs/decisions/034-…:67-68`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the git behaviour and the new harvest's coverage of the ignored path; does not establish the sub-claim *"Several benchmark repos ignore `docs/`-adjacent paths"*, which is unverifiable here — the fork clones' `.gitignore` files are the only evidence and only 5 of 50 forks are materialized (none of the five ignores `docs/reviews/`).

The test carries its own negative control, so the git behaviour is established by execution rather than asserted:

```bash
# test/crb-harvest-artifacts.bats:88-101 (abridged)
echo 'docs/reviews/' > "$CLONE/.gitignore"
…
echo '# rubric' > "$CLONE/docs/reviews/rubric.md"
run git -C "$CLONE" status --porcelain --untracked-files=all
[[ "$output" != *"rubric.md"* ]]
harvest
[ "$status" -eq 0 ]
[ -f "$DEST/docs/reviews/rubric.md" ]
```

Both halves passed: git did not report the file, and the new harvest captured it. The new harvest's coverage comes from walking rather than asking git (`scripts/crb-harvest-artifacts.py:60-80`).

**Evidence:** `scripts/crb-harvest-artifacts.py:1-30`, `scripts/crb-harvest-artifacts.py:57-80`, `test/crb-harvest-artifacts.bats:82-101`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/…` (four suites), cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 22: "symlinks are never followed or copied, and per-file and total size caps stop a hostile or runaway repo from filling the host disk"

**Location:** `scripts/crb-harvest-artifacts.py:22-25`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers symlink handling and the three caps in `crb-harvest-artifacts.py`; does not establish that the caps are correctly sized for real pipeline output, and does not cover hardlinks (which cannot escape a directory tree in the relevant sense).

Escape is blocked in two independent places. `os.walk` is called with `followlinks=False`, so a symlinked directory is never descended into, and symlinked directories are additionally pruned from `dirs`:

```python
# scripts/crb-harvest-artifacts.py:60-65
for root, dirs, files in os.walk(clone, followlinks=False):
    dirs[:] = [d for d in dirs
               if d != ".git" and not (Path(root) / d).is_symlink()]
```

and a symlinked *file* is neither hashed nor copied:

```python
# scripts/crb-harvest-artifacts.py:70-73
# A symlink is not an artifact, and copying one preserves a pointer
# into the host filesystem that a later reader would follow.
if fp.is_symlink() or not fp.is_file():
    continue
```

Exercised by *"a symlinked artifact is not harvested and not followed"* (`test/crb-harvest-artifacts.bats:115-127`), which plants both a symlinked file (`/etc/passwd`) and a symlink to a directory outside the clone and asserts `harvested 0 artifact(s)`; it passed. Caps: `MAX_FILE_BYTES`, `MAX_TOTAL_BYTES`, `MAX_FILES` at `scripts/crb-harvest-artifacts.py:44-46`, enforced at `:110-119`, with the over-size case exercised by `test/crb-harvest-artifacts.bats:128-140` (passed).

**Evidence:** `scripts/crb-harvest-artifacts.py:22-25`, `scripts/crb-harvest-artifacts.py:39-46`, `scripts/crb-harvest-artifacts.py:57-125`, `test/crb-harvest-artifacts.bats:115-140`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/…` (four suites), cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 23: "Clones are SHALLOW (--depth, default 50) … Measured on the 5-PR pilot: 33-195 MB each (see clone_mb in the manifest)."

**Location:** `scripts/crb-materialize.py:18-20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the depth default and the quoted size range against the checked-in manifest and the clones on disk; does not establish the range for the 45 unmaterialized PRs.

The default is 50:

```python
# scripts/crb-materialize.py:469
ap.add_argument("--depth", type=int, default=50, help="shallow clone depth (default 50)")
```

and `clone_mb` in the manifest ranges 33 (discourse-graphite-PR4) to 195 (sentry-greptile-PR5), matching the quoted bounds exactly. Measured apparent sizes today are 32–205 MB (`docs/reviews/execution-logs/cfc-r3-disk-2026-08-19.txt`), consistent with the manifest figures given that `dir_mb()` omits directory entries (`scripts/crb-materialize.py:180-189`).

**Evidence:** `scripts/crb-materialize.py:18-20`, `scripts/crb-materialize.py:180-189`, `scripts/crb-materialize.py:469`, `runs/review-arms/crb/instances.json`, `docs/reviews/execution-logs/cfc-r3-disk-2026-08-19.txt`
Executed: `du -sm --apparent-size external/crb-eval/*`, cwd `/workspace`, exit 0, 2026-08-19T23:09:53Z.

---

## Claim 24: "So the host does not read a used `.git` at all."

**Location:** `scripts/crb-materialize.py:30-32` (restated at `docs/decisions/034-…:34-40` "no host `git` remains anywhere in the cell path", `docs/working/crb-direction1-setup.md:126-127`)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers every host-side git invocation reachable from this script and the runner; does not assess whether the residual path is exploitable in practice (no cell has yet run — `runs/review-arms/crb-pipeline/` contains no cell directories, so no clone on disk is container-written today).

For the **cell path** the claim holds exactly, and is test-pinned: the runner issues no git against the clone (`test/crb-egress-config.bats:94-99`, passed), the restore is `rmtree` + `tar --extract` with no git (`scripts/crb-materialize.py:359-366`), `--verify` inspects a temp extract of the hash-pinned baseline rather than the work clone (`scripts/crb-materialize.py:534-555`), and the audit runs in a container.

The residual is `--snapshot`, which runs host git against whatever tree sits at `DST_ROOT/slug`:

```python
# scripts/crb-materialize.py:524-530
                    # Clears materialize()'s own FETCH_HEAD and any dangling
                    # origin/HEAD, so the baseline starts from the same state a
                    # freshly materialized clone would.
                    scrub_object_store(dst)
                    n_commits, stat = verify_containment(dst, slug, head)
```

`scrub_object_store` issues `git symbolic-ref -d`, `git reflog expire` and `git gc` (`scripts/crb-materialize.py:242-246`) and `verify_containment` issues `git rev-parse`, `git rev-list`, `git remote` and `git diff` (`scripts/crb-materialize.py:208-219`) — all on the host. The only code-level guard is a refusal to overwrite an **existing** baseline:

```python
# scripts/crb-materialize.py:519-523
                    if (BASELINE_ROOT / f"{slug}.tar").exists() and not args.force:
                        raise RuntimeError(
                            "a baseline already exists. Re-snapshotting is only correct "
                            "on a clone NO container has run against — pass --force if "
                            "that is true, or re-materialize with --slug --force.")
```

which does not fire for a clone that has no baseline yet — precisely the five pilot clones, and precisely the case `run-host.sh` directs the operator to (`runs/review-arms/crb-pipeline/run-host.sh:415-417`). The invariant on that path is documented (`scripts/crb-materialize.py:290-296`, "ONLY EVER CALL THIS ON A CLONE NO CONTAINER HAS TOUCHED") rather than enforced. Precise version: *"no host `git` runs against a used `.git` in the cell path; `--snapshot` is the one host-git entry point, and its precondition — a clone no container has touched — is the operator's to honour."*

**Evidence:** `scripts/crb-materialize.py:22-32`, `scripts/crb-materialize.py:192-246`, `scripts/crb-materialize.py:287-296`, `scripts/crb-materialize.py:509-555`, `runs/review-arms/crb-pipeline/run-host.sh:413-418`, `test/crb-egress-config.bats:94-99`, `docs/reviews/execution-logs/cfc-r3-pilot-clone-state-2026-08-19.txt`

---

## Claim 25: "`scripts/crb-materialize.py --all                      # all 50 (~13 GB w/ baselines)`"

**Location:** `scripts/crb-materialize.py:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the arithmetic behind the figure given the pilot measurements; does not establish that the 45 unmaterialized PRs match the pilot's mean size, which is the source of the Medium confidence.

Extrapolating the measured pilot (670 MB for 5 clones, doubled by the uncompressed baseline tars — see Claim 1) to 50 PRs gives 6.7 GB × 2 = 13.4 GB, which "~13 GB w/ baselines" states correctly. This is the figure `docs/working/crb-direction1-setup.md:27` was not updated to match (Claim 5).

**Evidence:** `scripts/crb-materialize.py:38`, `scripts/crb-materialize.py:298-324`, `runs/review-arms/crb/instances.json`, `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`

---

## Claim 26: "Each record carries: url, source_repo, pr_title, fork, fork_url, head, base, commits, n_goldens, files_changed, insertions, deletions, clone_mb, depth, baseline_tar, baseline_sha256, baseline_mb, baseline_files_indexed."

**Location:** `scripts/crb-materialize.py:44-50`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fields a record written by `materialize()` carries; does not establish that the checked-in `instances.json` (written before this commit) already has the four baseline fields — it does not, which is expected and is what `--snapshot` adds.

The record is assembled from exactly these keys, in two steps:

```python
# scripts/crb-materialize.py:432-444 (abridged)
    rec = {
        "url": url, "source_repo": …, "pr_title": …,
        "fork": fork, "fork_url": remote, "head": head, "base": base,
        "commits": n_commits, "n_goldens": …,
        "files_changed": files, "insertions": ins, "deletions": dels,
        "clone_mb": mb, "depth": depth,
    }
    rec.update(snapshot_baseline(dst, slug))
```

and `snapshot_baseline` returns exactly the four baseline keys (`scripts/crb-materialize.py:312-324`). No listed key is absent and no unlisted key is present.

**Evidence:** `scripts/crb-materialize.py:44-50`, `scripts/crb-materialize.py:312-324`, `scripts/crb-materialize.py:432-445`

---

## Claim 27: "materialize()'s own fetches write both [FETCH_HEAD and unreachable commits], so unless they are cleared here EVERY baseline would carry them and EVERY cell would void — and the checks would mean nothing. Clearing them is what makes their later presence evidence."

**Location:** `scripts/crb-materialize.py:226-237` (`scrub_object_store` docstring; restated at `scripts/crb-materialize.py:413-415`)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that materialize()'s clone/fetch/ref-prune sequence leaves both artefacts and that the scrub clears both, reproduced against a local fixture fork; does not establish the count of unreachable commits for any particular benchmark fork (it depends on how far the fork's default branch has advanced past the merge-base).

Reproduced from scratch. A bare "fork" with a default branch two commits deep plus `refs/pull/1/head`, put through exactly the steps at `scripts/crb-materialize.py:387-412` (clone `--no-checkout --depth=50`, fetch the PR head, checkout, `branch -f main <merge-base>`, `remote remove origin`, prune all other refs), then measured before and after the scrub:

```
# docs/reviews/execution-logs/cfc-r3-scrub-reproduction-2026-08-19.txt
=== BEFORE scrub_object_store
FETCH_HEAD: present
unreachable commits: 1
=== AFTER scrub_object_store (reflog expire --expire=now --all; gc --quiet --prune=now; unlink FETCH_HEAD)
FETCH_HEAD: absent
unreachable commits: 0
```

Both are exactly the two conditions the audit voids on (`scripts/crb-audit-clone.sh:55`, `:60-62`), so without the scrub every cell would void — the docstring's claim, confirmed. The claim is further corroborated on real data: all five existing pilot clones, materialized before the ordering fix, still carry `FETCH_HEAD` (`docs/reviews/execution-logs/cfc-r3-pilot-clone-state-2026-08-19.txt`), which is why `--snapshot` calls the scrub before baselining them (`scripts/crb-materialize.py:524-527`).

The scrub itself is:

```python
# scripts/crb-materialize.py:242-246
    subprocess.run(["git", "symbolic-ref", "-d", "refs/remotes/origin/HEAD"],
                   cwd=dst, capture_output=True, text=True)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
    (dst / ".git" / "FETCH_HEAD").unlink(missing_ok=True)
```

**Evidence:** `scripts/crb-materialize.py:225-246`, `scripts/crb-materialize.py:387-416`, `scripts/crb-audit-clone.sh:51-62`, `docs/reviews/execution-logs/cfc-r3-scrub-reproduction-2026-08-19.txt`, `docs/reviews/execution-logs/cfc-r3-pilot-clone-state-2026-08-19.txt`
Executed: `bash scratchpad/repro.sh` (fixture fork + materialize steps + scrub), cwd `/workspace`, exit 1 (from `set -e` on the final `grep -c` matching zero lines — i.e. the expected zero unreachable commits; all steps completed, see the log's trailing note), 2026-08-19T23:09:32Z.

---

## Claim 28: "Symlinks are never followed and never indexed, in either direction: a symlinked directory is the one way an os.walk could leave the clone."

**Location:** `scripts/crb-materialize.py:268-270` (`artifact_index` docstring)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `artifact_index`'s own walk; does not cover `dir_mb()` at `scripts/crb-materialize.py:180-189`, which walks with the default `followlinks=False` but does not filter symlinked entries — it only sums sizes, so no escape follows from that.

Same two-layer construction as the harvest (Claim 22), and the two walks are deliberately identical so the baseline and the diff agree:

```python
# scripts/crb-materialize.py:272-283
    for root, dirs, files in os.walk(dst, followlinks=False):
        dirs[:] = [d for d in dirs
                   if d != ".git" and not (Path(root) / d).is_symlink()]
        for name in files:
            if not name.endswith(ARTIFACT_SUFFIXES):
                continue
            fp = Path(root) / name
            if fp.is_symlink() or not fp.is_file():
                continue
            index[str(fp.relative_to(dst))] = sha256_file(fp)
```

`followlinks=False` is what stops descent through a symlinked directory (the `dirs[:]` filter is the belt to that braces, and also keeps the entry out of the walk's own bookkeeping). Exercised by *"artifact_index covers .md/.json, skips .git, and ignores symlinks"* (`test/crb-disposable-clone.bats:153-164`), which plants `ln -s /etc/passwd evil.md` and asserts it is absent from the index; it passed.

**Evidence:** `scripts/crb-materialize.py:257-284`, `test/crb-disposable-clone.bats:153-164`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/…` (four suites), cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 29: "materialize() calls it immediately after verify_containment(); the CLI mode refuses to overwrite an existing baseline without --force for the same reason."

**Location:** `scripts/crb-materialize.py:293-296` (`snapshot_baseline` docstring)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the call ordering in `materialize()` and the CLI's overwrite refusal; does not establish that the refusal is sufficient to enforce the docstring's stated precondition on a *first* snapshot — Claim 24 covers that gap.

Ordering in `materialize()`: `verify_containment` at `scripts/crb-materialize.py:418`, then the record is built, then

```python
# scripts/crb-materialize.py:444
    rec.update(snapshot_baseline(dst, slug))
```

with the comment at `:439-443` giving the same reason. The CLI refusal is quoted in Claim 24 (`scripts/crb-materialize.py:519-523`), and the `--snapshot` path also re-runs `verify_containment` before snapshotting (`scripts/crb-materialize.py:528`). The baseline is published atomically via a `.part` rename (`scripts/crb-materialize.py:299-305`), so a partially written tar is never restorable — pinned negatively by *"a tampered baseline refuses to restore"* (`test/crb-disposable-clone.bats:132-139`, passed).

**Evidence:** `scripts/crb-materialize.py:287-324`, `scripts/crb-materialize.py:418-445`, `scripts/crb-materialize.py:511-533`, `test/crb-disposable-clone.bats:132-151`

---

## Claim 30: "This replaced reset_clone(), which repaired the clone in place with `checkout --force` / `reset --hard` / `clean -qffdx` / `gc` / `fsck` — all of them HOST git commands…"

**Location:** `scripts/crb-materialize.py:329-339` (`restore_clone` docstring)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the accuracy of the enumeration against the deleted `reset_clone()`; does not re-verify the reviewer's five execution paths, which are taken from the 2026-08-19 rubric.

Every command named appears in the deleted function or the helpers it called, at the parent commit:

```python
# scripts/crb-materialize.py@197eec6^:348-362 (abridged)
    sh(["git", "checkout", "--force", "--quiet", "-B", "review", head], cwd=dst)
    sh(["git", "reset", "--hard", "--quiet", head], cwd=dst)
    …
    sh(["git", "clean", "-qffdx"], cwd=dst)
```

with `gc` in `scrub_object_store` (`scripts/crb-materialize.py@197eec6^:311`) and `fsck` in `fetch_traces` (`scripts/crb-materialize.py@197eec6^:246`), both called from the same reset path. `reset_clone`, `fetch_traces` and `classify_strays` are absent from the current file (paraphrased — no quote available because the claim covers the absence of code: grep for those three names across `scripts/` and `runs/` returns no hits). The five execution paths and the `core.worktree` redirect match the rubric's R1/R2 rows verbatim (`docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md:93-94`).

**Evidence:** `scripts/crb-materialize.py:327-346`, `scripts/crb-materialize.py@197eec6^:246,311,340-366`, `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md:93-94`

---

## Claim 31: "Tests: 37 new across four suites (disposable-clone, audit-clone, harvest-artifacts, egress-config)"

**Location:** commit `197eec6` message, body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count and the suite names, and that all 37 pass in this environment; does not assess the tests' strength or coverage.

Counts per suite: `crb-disposable-clone.bats` 9, `crb-audit-clone.bats` 10, `crb-harvest-artifacts.bats` 9, `crb-egress-config.bats` 9 — total 37, matching the claim, and all four files are additions in this commit (`git show --stat 197eec6`). Executed:

```
# docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt (summary)
ok lines: 37   not ok lines: 0
```

**Evidence:** `test/crb-disposable-clone.bats`, `test/crb-audit-clone.bats`, `test/crb-harvest-artifacts.bats`, `test/crb-egress-config.bats`, `docs/reviews/execution-logs/cfc-r3-bats-2026-08-19.txt`
Executed: `bats test/crb-audit-clone.bats test/crb-disposable-clone.bats test/crb-harvest-artifacts.bats test/crb-egress-config.bats`, cwd `/workspace`, exit 0, 2026-08-19T23:07:02Z.

---

## Claim 32: "test/crb-containment-reset.bats removed with the code it pinned, its load-bearing void cases carried into crb-audit-clone."

**Location:** commit `197eec6` message, body (restated at `test/crb-audit-clone.bats:9-23`)
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the case-by-case correspondence between the deleted suite's void cases and the new audit suite; does not assess whether the uncarried cases *should* have been carried, only that the claim's "carried" is not exhaustive.

The removal is correct — `reset_clone`, `fetch_traces` and `classify_strays` are gone (Claim 30), so the suite that pinned them had nothing left to pin. Four of the deleted suite's void cases have direct counterparts:

| deleted (`test/crb-containment-reset.bats@197eec6^`) | counterpart (`test/crb-audit-clone.bats`) |
|---|---|
| `:145` a re-added remote still VOIDS the cell | `:71` a surviving remote VOIDS |
| `:153` a commit outside the reviewed ancestry still VOIDS | `:102` a commit that does not descend from the head VOIDS |
| `:186` r1's exact attack: fetch by URL, delete the ref, commit on top | `:89` a fetched-then-deleted ref VOIDS via the unreachable commit |
| `:202` a bare fetch by URL leaves FETCH_HEAD and VOIDS | `:79` a FETCH_HEAD trace VOIDS |

Three cases from the deleted suite have **no counterpart in any of the four new suites** (paraphrased — no quote available because the claim covers the absence of tests: the four new `.bats` files contain no test creating a tag, no shallow-clone fixture, and no test asserting a benign sequence stays clean across two cells):

- `:385` *"a tag pointing outside the reviewed ancestry still VOIDS the cell"* — the behaviour survives (`git rev-list --all` at `scripts/crb-audit-clone.sh:73` walks `refs/tags`), but nothing pins that a tag, specifically, reaches the check. A ref type is exactly the kind of thing a later narrowing (`--branches` instead of `--all`) would silently drop.
- `:239` *"scrub_object_store is load-bearing — benign sequence VOIDS without it"* — the property this report verifies by hand in Claim 27 is now unpinned; nothing fails if `scrub_object_store` is deleted from `materialize()`.
- `:284` *"fetch-trace detection is quiet on a SHALLOW clone"* — the false-positive control. `test/crb-audit-clone.bats`'s pristine fixture is a locally-created, non-shallow repo (`test/crb-audit-clone.bats:34-53`), so nothing establishes that a real `--depth=50` clone audits clean.

Precise version: *"…its five load-bearing void cases carried into crb-audit-clone; the tag variant, the scrub non-vacuity case and the shallow-clone false-positive control were not carried."*

**Evidence:** `test/crb-audit-clone.bats:9-23`, `test/crb-audit-clone.bats:34-158`, `test/crb-containment-reset.bats@197eec6^:145,153,186,202,239,284,385`, `scripts/crb-audit-clone.sh:69-81`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:69-70`): "R6 … dissolves with them" is refuted — with the five existing clones and no baselines, `run-host.sh` still skips every instance (`skipped_bad`) and exits 3 having run nothing, which is R6's reported symptom verbatim; the remediation is still a one-shot operator command, renamed `--heal` → `--snapshot`. Restate as "R6's pre-run gate is gone; the equivalent precondition is a missing baseline, remediated once per clone by `--snapshot`."
- **Claim 9b** (`runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20`): `ConnectPort 443` is credited with refusing plain-HTTP proxying; `ConnectPort` scopes the CONNECT method only. Plain HTTP is refused by the `Filter`, not by `ConnectPort`, and `HTTP_PROXY`/`http_proxy` are exported to every cell. Restate the mechanism, and consider a fourth preflight leg covering `http://github.com/` and a non-443 `CONNECT` — both $0.

### Stale
- **Claim 5** (`docs/working/crb-direction1-setup.md:27`): `--all` still quoted at `~6-7 GB`, the pre-baseline figure; this commit's own docstring and decision record say `~13 GB`.
- **Claim 13** (`runs/review-arms/crb-pipeline/run-host.sh:423-425`): "the tree reset below" — no reset exists below; the wipe moved to the next cell's `--restore` at the top of the loop. Also leaves a stray bare `#` at `:426`.

### Mostly Accurate
- **Claim 3** (`docs/decisions/034-…:67-68`): "strictly more complete" — the new harvest also refuses symlinked artifacts and caps files/bytes, so it can capture less than the old one; both are reported, not silent.
- **Claim 7** (`runs/review-arms/crb-pipeline/docker/Dockerfile.review:6-8`): "needs exactly ONE reachable host" — one host is *required*; this repo's own base egress profile lists five more that Claude Code contacts (claude.ai, console.anthropic.com, sentry.io, statsig.com, registry.npmjs.org), and nothing disables the autoupdater or non-essential traffic. Say "requires" rather than "needs", or set the disabling env vars.
- **Claim 8** (`runs/review-arms/crb-pipeline/docker/tinyproxy.conf:12-16`): `EGRESS_SUBNET` is a default, not a pin; overriding it desynchronises the baked `Allow` line (fails closed at preflight leg 1, and the bats test compares the default only).
- **Claim 17b** (`scripts/crb-audit-clone.sh:10-13`): the quoted `docker run` line omits `-u node` and `--entrypoint bash`; run verbatim it would invoke `claude bash /audit.sh …` because the image's ENTRYPOINT is `claude`.
- **Claim 18** (`scripts/crb-audit-clone.sh:23`): the exit legend maps "could not check" to 2, but an fsck error — the archetypal could-not-check — exits 1 by design (fail closed). Reword the legend.
- **Claim 24** (`scripts/crb-materialize.py:30-32`): "the host does not read a used `.git` at all" holds for the cell path but not for `--snapshot`, which runs `symbolic-ref`/`reflog expire`/`gc`/`rev-list`/`diff` on the host against whatever tree is at `DST_ROOT/slug`; its precondition is documented, and enforced only when a baseline already exists.
- **Claim 32** (commit message): three cases from the deleted suite have no counterpart — the tag-outside-ancestry void, the `scrub_object_store` non-vacuity case, and the shallow-clone false-positive control.

### Unverifiable
- **Claim 9a** (`runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20`): whether tinyproxy refuses CONNECT to non-443 ports cannot be established here — neither docker nor tinyproxy is installed (`which tinyproxy` → not found). A fourth preflight leg attempting `CONNECT api.anthropic.com:8443` would settle it at $0.

---

## Goal-Alignment Note
- Answered: yes — 34 claims verdicted against commit `197eec6`, with the docker-shaped absence treated as a known constraint rather than a defect.
- Out of scope: code quality, security judgement, and test-design critique (sibling critics own those); the sweep's own dollar estimates and benchmark-injection logic, which this commit does not touch; sibling commits on the branch, consulted as context only.
- Escalate: (1) Claim 4 — the decision record states R6 dissolved, but the shipped harness still exits 3 with zero cells against the five clones that exist; someone must run `--snapshot` on each before the sweep, and the doc should say so. (2) Claim 9b + 9a — the egress preflight has no plain-HTTP leg and no non-443 CONNECT leg; both are $0 additions and both cover paths the tinyproxy comment currently mis-attributes. (3) Claim 7 — whether a cell functions with a single reachable host is the one remaining unverified assumption gating paid spend; the preflight is the right place, and it is already wired.
