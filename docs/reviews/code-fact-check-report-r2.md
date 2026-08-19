# Code Fact-Check Report

**Repository:** /workspace (`feat/crb-direction1-harness`)
**Commit:** 197eec6
**Scope:** Single commit `197eec6` (`feat(crb): egress allowlist + disposable clones`) — 16 files: `docs/decisions/034-*.md`, `docs/working/crb-direction1-setup.md`, `runs/review-arms/crb-pipeline/docker/*`, `runs/review-arms/crb-pipeline/run-host.sh`, `scripts/crb-materialize.py`, `scripts/crb-audit-clone.sh`, `scripts/crb-harvest-artifacts.py`, `test/crb-{audit-clone,disposable-clone,egress-config,harvest-artifacts}.bats`, plus the commit message. Sibling commits on the branch were read for context only.
**Checked:** 2026-08-19
**Total claims checked:** 26 (25 numbered; Claim 11 split into 11a/11b on verdict divergence)
**Summary:** 16 verified, 6 mostly accurate, 2 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read before checking. Two logged patterns are both of the form *"a specific measured value quoted from a checked-in artifact set that does not contain it."* Claim 1 and Claim 21 are the two claims in this diff of that shape (disk figures quoted from the manifest; a `.gitignore` collision quoted from the benchmark clones) and are called out against the pattern in their verdict blocks.

---

## Claim 1: "Disk roughly doubles: pilot ~670 MB → ~1.3 GB, `--all` ~6.5 → ~13 GB."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the arithmetic of the pilot and extrapolated `--all` figures against the checked-in manifest; does not establish the tar-vs-tree size ratio empirically (no baseline tar exists in this environment) nor that the 5 pilot PRs are size-representative of all 50.

The manifest's five `clone_mb` values sum to exactly 670:

```
cal_com-PR11059 190 / discourse-graphite-PR4 33 / grafana-PR79265 125
keycloak-PR36880 127 / sentry-greptile-PR5 195      # runs/review-arms/crb/instances.json
```
(command: `jq -r 'to_entries[]|"\(.key) \(.value.clone_mb)"' runs/review-arms/crb/instances.json`, cwd `/workspace`, exit 0, 2026-08-19T23:03Z; captured at `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt` is the bats log — the jq output is reproduced inline above because it is three lines.)

The doubling follows from `snapshot_baseline` writing an **uncompressed** tar of the same tree (`scripts/crb-materialize.py:302`):

```py
# scripts/crb-materialize.py:302
sh(["tar", "--create", "--file", str(part), "-C", str(dst), "."])
```

670 MB × 2 ≈ 1.3 GB, and 670/5 × 50 = 6.7 GB ≈ "~6.5" → ~13 GB. Compared against the logged hallucination pattern *"a specific measured value quoted from a checked-in artifact set that does not contain it"*: this one **does** occur in the cited artifact set — no match.

**Evidence:** `runs/review-arms/crb/instances.json`, `scripts/crb-materialize.py:297-311`, `scripts/crb-materialize.py:441-443`

---

## Claim 2: "R3 (nested clone) and A8 (a voided cell leaving a permanently dead clone) are closed structurally rather than by a flag or a message."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:65-66`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that a nested repo and a voided cell's clone are destroyed by the next cell's restore, and that the audit reports a nested repo; does not establish that a nested repo created *during* a cell is prevented (it is not — it is destroyed afterwards and reported).

Every cell begins with a wipe-and-extract, not a repair:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:413
python3 "$ROOT/scripts/crb-materialize.py" --restore "$id" || {
```
```py
# scripts/crb-materialize.py:359-363
dst = DST_ROOT / slug
if dst.exists():
    shutil.rmtree(dst)
dst.mkdir(parents=True)
sh(["tar", "--extract", "--file", str(tar), "-C", str(dst)])
```

Two bats cases execute exactly the R3 and A8 shapes and pass: `restore destroys a nested clone of the answer key` and `restore erases a re-added remote and a deleted main` (`test/crb-disposable-clone.bats`), plus `a nested repository VOIDS` (`test/crb-audit-clone.bats:112-118`). A8's "no remediation message" half is also addressed: the void path no longer leaves the clone in the pre-run gate's way, and the runner says so at `run-host.sh:510-512` — `# The clone is left as the container wrote it; the NEXT cell's --restore wipes it.` Command: `bats test/crb-audit-clone.bats test/crb-disposable-clone.bats test/crb-egress-config.bats test/crb-harvest-artifacts.bats`, cwd `/workspace`, exit 0, 2026-08-19T23:03Z.

**Evidence:** `scripts/crb-materialize.py:327-366`, `runs/review-arms/crb-pipeline/run-host.sh:406-418`, `runs/review-arms/crb-pipeline/run-host.sh:510-512`, `test/crb-disposable-clone.bats`, `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt`

---

## Claim 3: "The harvest became strictly more complete: `git status --untracked-files=all` honours `.gitignore`, so a rubric written to an ignored path used to vanish."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:67-68` (same claim at `scripts/crb-materialize.py:263-266`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the artifact set the two harvests can each produce for `.md`/`.json` files; does not establish behaviour for other extensions (both harvests filter to `.md`/`.json`, so neither is broader there).

The `.gitignore` half is right and is proven by execution — see Claim 20. But "**strictly** more complete" is a set-inclusion claim, and the new harvest drops two categories the old loop copied:

```py
# scripts/crb-harvest-artifacts.py:110-119
if size > MAX_FILE_BYTES:
    ...
    skipped += 1
    continue
if copied >= MAX_FILES or total + size > MAX_TOTAL_BYTES:
    ...
    break
```
```py
# scripts/crb-harvest-artifacts.py:72-73
if fp.is_symlink() or not fp.is_file():
    continue
```

The old loop had no caps and copied symlinks rather than skipping them:

```bash
# git show 197eec6^:runs/review-arms/crb-pipeline/run-host.sh — harvest loop
cp --no-dereference "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
```
(paraphrased — no quote available with a `path:line` because the source is a deleted revision of the file, addressable only as `197eec6^:runs/review-arms/crb-pipeline/run-host.sh`; the quoted line is verbatim from that blob.)

Precise version: *"more complete on the case that mattered — `.gitignore`d artifacts — at the cost of a 5 MB/file, 50 MB, 500-file cap and skipped symlinks, all of which are reported rather than silent."*

**Evidence:** `scripts/crb-harvest-artifacts.py:39-46`, `scripts/crb-harvest-artifacts.py:60-80`, `scripts/crb-harvest-artifacts.py:105-127`, `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:67-68`

---

## Claim 4: "`--reset` and `--heal` are gone; `--restore` and `--snapshot` replace them. R6 (no existing clone could pass the pre-run gate) dissolves with them."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:69-70`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the removal of the two CLI modes, the absence of any pre-run containment gate in the cell loop, and the `--snapshot` remediation path for pre-2026-08-19 clones; does not establish that an existing pilot clone actually snapshots successfully (no clone here has a baseline, and `--snapshot` requires a container-untouched clone).

The argparse group now offers only the new modes:

```py
# scripts/crb-materialize.py:461-468
g.add_argument("--restore", nargs="+", metavar="SLUG", ...)
g.add_argument("--snapshot", nargs="+", metavar="SLUG", ...)
```

The cell loop's only precondition is a baseline tar, not a containment check:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:366-369
[ -f "$CLONES/.baselines/$id.tar" ] || {
    echo "$id: no baseline — run scripts/crb-materialize.py --slug $id (or --snapshot $id" >&2
```

R6's specific mechanism (leftover `FETCH_HEAD` + dangling `refs/remotes/origin/HEAD` raising before the healer ran) is also ordered correctly in the surviving `--snapshot` path — scrub runs *before* verify:

```py
# scripts/crb-materialize.py:527-528
scrub_object_store(dst)
n_commits, stat = verify_containment(dst, slug, head)
```

Pinned by the passing bats case `the runner restores from the baseline before every cell`, which greps that `--reset`/`--heal` are absent from the runner (executed 2026-08-19T23:03Z, exit 0).

**Evidence:** `scripts/crb-materialize.py:451-471`, `scripts/crb-materialize.py:512-533`, `runs/review-arms/crb-pipeline/run-host.sh:361-418`, `test/crb-egress-config.bats:101-108`, `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt`

---

## Claim 5: "`scripts/crb-materialize.py --all           # all 50 (~6-7 GB)`"

**Location:** `docs/working/crb-direction1-setup.md:27`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the `--all` disk figure in the setup doc's quick-reference block; does not affect the doc's later prose, which was updated.

This commit added baselines that double the on-disk cost, and updated the figure in two of the three places it appears — but not here. The setup doc still reads:

```
scripts/crb-materialize.py --all           # all 50 (~6-7 GB)
```
(`docs/working/crb-direction1-setup.md:27`)

while the same commit's own module docstring and decision record say otherwise:

```py
# scripts/crb-materialize.py:38
  scripts/crb-materialize.py --all                      # all 50 (~13 GB w/ baselines)
```

What the code now does: `--all` materializes 50 clones **and** 50 uncompressed baseline tars, i.e. ~13 GB. The setup doc's number describes the pre-197eec6 harness.

**Evidence:** `docs/working/crb-direction1-setup.md:27`, `scripts/crb-materialize.py:38`, `scripts/crb-materialize.py:441-443`, `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`

---

## Claim 6: "Fail closed at build time … Assert both halves here so the image cannot be built in that state."

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:15-23`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the three greps pass on the files as committed and that they detect the two states the comment names (mistyped `FilterDefaultDeny`; empty/all-comment filter file); does not establish that the filter's regex actually matches `api.anthropic.com` (nothing at build time asserts that — the preflight's positive leg is what would catch it).

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:21-23
RUN grep -qE '^[[:space:]]*FilterDefaultDeny[[:space:]]+Yes' /etc/tinyproxy/tinyproxy.conf \
 && grep -qE '^[[:space:]]*Filter[[:space:]]+"/etc/tinyproxy/filter"' /etc/tinyproxy/tinyproxy.conf \
 && grep -qE '^[^#[:space:]]' /etc/tinyproxy/filter
```

The comment's named failure — *"a filter that silently matched nothing while `FilterDefaultDeny` was mistyped would allow everything"* — is caught by the first grep, and the "empty or commented-out filter file" half by the third. Both halves of the conjunction the comment claims are therefore present. Executed against the committed files (docker itself is unavailable; the `RUN` body is a pure shell conjunction over two files that are `COPY`ed verbatim, so running it directly is equivalent): command `grep -qE ... && grep -qE ... && grep -qE ...`, cwd `/workspace/runs/review-arms/crb-pipeline/docker`, exit 0, 2026-08-19T23:06Z.

**Evidence:** `runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:12-23`, `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:25-29`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:9`, `docs/reviews/execution-logs/crb-r2-proxy-buildassert-197eec6.txt`

---

## Claim 7: "Baking the CLI means a running cell needs exactly ONE reachable host, `api.anthropic.com`."

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:3-8` (repeated at `runs/review-arms/crb-pipeline/run-host.sh:140-143`, `docs/decisions/034-…:44-46`)
**Type:** Behavioral / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what the image and runner statically arrange; does not establish what hostnames the Claude Code CLI actually opens at runtime — that requires running the image, which this environment cannot do.

**Blocker: execution required, docker unavailable.** `which docker` → not found (cwd `/workspace`, 2026-08-19T23:03Z). This is an executable guarantee about a running process's network fan-out, so per the mandatory-execution rule static reading caps it at Unverifiable. The commit message and `docs/decisions/034:71-74` both state this is deliberate and that the preflight settles it on the host at $0.

Two static observations the author may want the preflight to watch for, neither of which refutes the claim:

- The install is baked, so `registry.npmjs.org` is not needed *per cell*:
  ```dockerfile
  # runs/review-arms/crb-pipeline/docker/Dockerfile.review:18-19
  RUN npm install -g "@anthropic-ai/claude-code@${CC_VERSION}" \
   && npm cache clean --force
  ```
- Nothing in the image or the runner sets `DISABLE_AUTOUPDATER`/`DISABLE_TELEMETRY` (paraphrased — no quote available because the claim covers the absence of code: `grep -rn 'AUTOUPDAT|autoupdat' runs/review-arms/crb-pipeline/` returned no matches). A background updater or telemetry call to a second host would fail rather than break the cell, so "needs" can still hold while "contacts" does not.

The cell also depends on docker's embedded DNS resolving `crb-egress-proxy` on an `--internal` network — named as an open assumption in the commit message, not asserted as fact.

**Evidence:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:1-28`, `runs/review-arms/crb-pipeline/run-host.sh:139-150`, `runs/review-arms/crb-pipeline/run-host.sh:428-444`

---

## Claim 8: "Built once by run-host.sh with normal network, before the restricted network is created. The CLI version is still pinned, so the arm is comparable to E5/E7 which pin the same way."

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:10-12`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers build ordering within `run-host.sh` and the version-pin comparison with the E5/E7 runners; does not establish that the default docker build network is unrestricted on the operator's machine.

Both builds precede `setup_egress`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:145-148
docker build --quiet --build-arg CC_VERSION="$CC_VERSION" \
  -f "$DOCKER_DIR/Dockerfile.review" -t "$REVIEW_IMAGE" "$DOCKER_DIR" >/dev/null
docker build --quiet -f "$DOCKER_DIR/Dockerfile.proxy" -t "$PROXY_IMAGE" \
  "$DOCKER_DIR" >/dev/null
```
```bash
# runs/review-arms/crb-pipeline/run-host.sh:171-172
echo "=== egress allowlist"
setup_egress
```

The pin matches the sibling arms exactly:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:73
CC_VERSION="${CC_VERSION:-2.1.232}"   # pin for reproducibility; bump deliberately
```
```bash
# runs/review-arms/e7-fable-3x/run-host.sh:46
CC_VERSION="2.1.232"   # pin for reproducibility; bump deliberately
```
`runs/review-arms/e5-cc-builtin/run-host.sh:23` carries the identical line.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:73`, `:139-178`, `runs/review-arms/e5-cc-builtin/run-host.sh:23`, `runs/review-arms/e7-fable-3x/run-host.sh:46`

---

## Claim 9: "EXACTLY ONE ENTRY IS INTENDED. … test/crb-egress-config.bats pins the count, so adding a host is a deliberate, reviewed act."

**Location:** `runs/review-arms/crb-pipeline/docker/egress-allowlist:1-8`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the file holds one anchored entry and that a test asserts both the count and the literal; does not establish that tinyproxy interprets the regex as intended at runtime.

```
# runs/review-arms/crb-pipeline/docker/egress-allowlist:9
^api\.anthropic\.com$
```
```bash
# test/crb-egress-config.bats:25-30
run grep -c '^[^#]' "$DOCKER_DIR/egress-allowlist"
[ "$output" = "1" ]
run grep '^[^#]' "$DOCKER_DIR/egress-allowlist"
[ "$output" = '^api\.anthropic\.com$' ]
```

The case passes: `ok 20 the allowlist names exactly one host, anchored` (command `bats test/crb-*.bats` as in Claim 2, exit 0, 2026-08-19T23:03Z).

**Evidence:** `runs/review-arms/crb-pipeline/docker/egress-allowlist:1-9`, `test/crb-egress-config.bats:25-30`, `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt`

---

## Claim 10: "The proxy is reachable only from the internal `crb-inner` network, whose subnet run-host.sh pins so this line can be exact."

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:12-16`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement between the `Allow` CIDR and the runner's default `EGRESS_SUBNET`, and the existence of a test enforcing that agreement; does not establish tinyproxy's runtime ACL behaviour, nor what happens if an operator overrides `EGRESS_SUBNET` (the `Allow` line would then no longer cover the network, and no test catches that).

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:16
Allow 172.31.250.0/24
```
```bash
# runs/review-arms/crb-pipeline/run-host.sh:99
EGRESS_SUBNET="${EGRESS_SUBNET:-172.31.250.0/24}"
```
```bash
# runs/review-arms/crb-pipeline/run-host.sh:159
docker network create --internal --subnet "$EGRESS_SUBNET" "$EGRESS_NET" >/dev/null
```

The agreement is machine-checked rather than eyeballed — `test/crb-egress-config.bats:52-53` extracts the CIDR from the conf and greps the runner for the matching default; the case passes (`ok 22`, executed 2026-08-19T23:03Z).

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:12-16`, `runs/review-arms/crb-pipeline/run-host.sh:96-99`, `:156-166`, `test/crb-egress-config.bats:45-54`

---

## Claim 11a: "CONNECT to 443 only: … every other port [is] refused, so the tunnel cannot be repointed at an arbitrary service."

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the CONNECT-port restriction only; the same sentence's plain-HTTP assertion is verdicted separately as Claim 11b.

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:20
ConnectPort 443
```
tinyproxy's `ConnectPort` allowlists the ports the CONNECT method may target; with one entry present, CONNECT to any other port is refused. The half of the comment about CONNECT is therefore accurate, and it is pinned by `test/crb-egress-config.bats:46` (`ok 22`, executed 2026-08-19T23:03Z).

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20`, `test/crb-egress-config.bats:45-54`

---

## Claim 11b: "plain-HTTP proxying … [is] refused"

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-19`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether any directive in this file disables non-CONNECT (plain-HTTP) proxying; does not establish that an allowed plain-HTTP request would be *useful* to an attacker — the filter still constrains which host it may reach.

`ConnectPort` governs the CONNECT method only. A plain `GET http://host/…` through the proxy is an ordinary forward-proxy request and never goes through CONNECT, so `ConnectPort` does not refuse it. Nothing else in the file disables it — there is no `DisableHTTP`-style directive present (paraphrased — no quote available because the claim covers the absence of a directive; the full 31-line file is quoted piecewise in Claims 10, 11a and 12, and contains only `User`, `Group`, `Port`, `Listen`, `Timeout`, `LogLevel`, `LogFile`, `MaxClients`, `StartServers`, `Allow`, `ConnectPort`, `Filter`, `FilterURLs`, `FilterExtended`, `FilterCaseSensitive`, `FilterDefaultDeny`, `DisableViaHeader`).

What the code actually does: plain-HTTP proxying is **permitted**, and is constrained only by the same `Filter`/`FilterDefaultDeny` allowlist — so `http://api.anthropic.com/…` would be proxied on port 80, and any other host refused by the filter rather than by `ConnectPort`. A reader acting on this comment — e.g. concluding that removing the filter would still leave plain HTTP blocked, or that the port restriction is the load-bearing control — is misled. Precise version: *"CONNECT is restricted to 443; plain-HTTP proxying is still served, and the filter is what constrains it."*

The claim is not covered by a test: `test/crb-egress-config.bats:45-54` asserts only that the `ConnectPort 443` line exists, and the runner's preflight (`run-host.sh:197-223`) exercises HTTPS only.

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:1-31`, `test/crb-egress-config.bats:45-54`, `runs/review-arms/crb-pipeline/run-host.sh:197-223`

---

## Claim 12: "FilterURLs Off => the filter matches the HOST, which for a CONNECT request is the tunnel target. FilterDefaultDeny inverts the usual sense: entries are what is ALLOWED, everything else is refused."

**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:22-24`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the documented semantics of the three directives as configured; does not establish runtime behaviour (no docker here — the runner's preflight leg 2 is what would demonstrate it).

The three directives are all present and mutually consistent:

```
# runs/review-arms/crb-pipeline/docker/tinyproxy.conf:25-29
Filter "/etc/tinyproxy/filter"
FilterURLs Off
FilterExtended On
FilterCaseSensitive Off
FilterDefaultDeny Yes
```

`FilterURLs Off` selects host-based rather than URL-based matching, and `FilterDefaultDeny Yes` inverts the filter file into an allowlist — which is exactly how `egress-allowlist` is written and commented (`runs/review-arms/crb-pipeline/docker/egress-allowlist:1-2`: `# Hosts a review cell may reach. Anchored regexes, matched against the CONNECT target host (FilterExtended On, FilterURLs Off).`). `FilterExtended On` makes `^api\.anthropic\.com$` an ERE, so the anchors bind. Confidence is Medium rather than High because the verdict rests on tinyproxy's documented directive semantics, not on an observed run.

**Evidence:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:22-29`, `runs/review-arms/crb-pipeline/docker/egress-allowlist:1-9`, `test/crb-egress-config.bats:36-43`

---

## Claim 13: "each leg is separate because they fail for different reasons — a single test passing for the wrong reason is how this harness has gone wrong before."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:193-196` (same claim at `docs/working/crb-direction1-setup.md`, "Three legs because each fails for a different reason")
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the discriminating power of the three legs as written; does not establish their runtime outcomes (docker unavailable) nor whether tinyproxy returns 403 rather than closing the connection on a filtered CONNECT.

The three legs do test three different properties — tunnel reachability, filter enforcement, and network isolation:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:201-204
api_code=$(in_cell_net 'curl -s -o /dev/null -w "%{http_code}" --max-time 25 https://api.anthropic.com/v1/models || echo 000')
[ "$api_code" != "000" ] || {
  echo "  FAIL: api.anthropic.com unreachable through the proxy — every cell would fail" >&2
  exit 5; }
```
```bash
# runs/review-arms/crb-pipeline/run-host.sh:209-214
case "$gh_code" in
  403|000) echo "  ok  github.com refused through the proxy (HTTP $gh_code)" ;;
  *) echo "  FAIL: github.com returned HTTP $gh_code through the proxy — the allowlist is NOT filtering." >&2
```
```bash
# runs/review-arms/crb-pipeline/run-host.sh:218-222
direct=$(docker run --rm --network "$EGRESS_NET" --entrypoint bash "$REVIEW_IMAGE" \
  -c 'curl -s -o /dev/null -w "%{http_code}" --max-time 20 https://github.com/ || echo 000')
[ "$direct" = "000" ] || {
```

What to tighten: leg 2 accepts `000`, which is curl's "no HTTP response at all" — produced by a filtered CONNECT, but equally by a dead proxy, a DNS failure, or a timeout. Leg 2 therefore does **not** isolate "the filter works" on its own; it does so only in conjunction with leg 1 (which would have failed first on a dead proxy). Precise version: *"three legs, each failing for a different reason, with leg 2's negative result only meaningful given leg 1's positive."*

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:190-223`, `test/crb-egress-config.bats:110-119`

---

## Claim 14: "Artifacts are harvested and the tree reset below, so re-runs start from the same state."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:423-425`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the phrase "the tree reset below" in this comment block; does not affect the harvest half of the same sentence, which is accurate.

This is a survivor of the design this commit replaced. There is no reset below it any more:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:423-425
  # The clone is mounted read-write on purpose: the code-review skill writes its
  # rubric to docs/reviews/ in the repo under review. Artifacts are harvested
  # and the tree reset below, so re-runs start from the same state.
```

The restore happens *above* this comment, at the top of the loop body, and the runner states 85 lines later that nothing resets the tree afterwards:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:413
python3 "$ROOT/scripts/crb-materialize.py" --restore "$id" || {
```
```bash
# runs/review-arms/crb-pipeline/run-host.sh:510-512
  # The clone is left as the container wrote it; the NEXT cell's --restore wipes
  # it. Nothing on the host touches it in between, and a voided cell no longer
  # leaves a permanently dead clone (2026-08-19 A8).
```

`grep -n 'reset' runs/review-arms/crb-pipeline/run-host.sh` returns only this line and an unrelated `delete $dest to reset` message at `:399` (paraphrased — no quote available because the assertion is about the absence of matches across the file). What the code actually does: the tree is reset **above**, at the start of the *next* cell, not below within this one.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:399`, `:406-418`, `:423-425`, `:510-512`

---

## Claim 15: "E7 learned the exact failure string the hard way (e7-fable-3x/run-host.sh:87-89 — exit 0, result 'Not logged in · Please run /login', num_turns=0)."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:252-255`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the cited path and line range exist and say what is attributed to them; does not re-verify the underlying CLI behaviour.

```bash
# runs/review-arms/e7-fable-3x/run-host.sh:86-89
# ── Auth preflight ──────────────────────────────────────────────────────────
# A bad credential does NOT make claude exit non-zero: it returns exit 0 with
# result "Not logged in · Please run /login" and num_turns=0 (learned the hard
# way, 2026-08-14). Verify auth with one cheap prompt before burning the sweep.
```

Lines 87-89 are the three substantive lines; the quoted string, the exit code and `num_turns=0` all appear. The guard the reference justifies is present and tests both spellings:

```py
# runs/review-arms/crb-pipeline/run-host.sh:257
if d.get("num_turns", 0) < 1 or "log in" in low or "logged in" in low:
```

**Evidence:** `runs/review-arms/e7-fable-3x/run-host.sh:86-89`, `runs/review-arms/crb-pipeline/run-host.sh:245-262`

---

## Claim 16: "run-host.sh invokes it as: `docker run --rm --network none -v "$clone":/repo -v .../crb-audit-clone.sh:/audit.sh:ro <image> bash /audit.sh /repo <head-sha>`"

**Location:** `scripts/crb-audit-clone.sh:10-13`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the literal argument list in the header against the runner's actual `docker run`; does not affect the substantive claims of the same header (no network, no key, throwaway container), which are accurate.

Mechanism and conclusion are both right — the audit does run in a `--network none` throwaway container with no key — but the quoted command as written would not run, and differs in two ways from the real one:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:493-496
  if ! docker run --rm --network none -u node \
        -v "$clone":/repo \
        -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha"; then
```

(a) the real invocation adds `-u node`; (b) the header's `<image> bash /audit.sh` form would be passed as *arguments to the image's ENTRYPOINT*, which is `claude`:

```dockerfile
# runs/review-arms/crb-pipeline/docker/Dockerfile.review:28
ENTRYPOINT ["claude"]
```

so the runner uses `--entrypoint bash <image> /audit.sh …` instead. Precise version: replace the header's command with `docker run --rm --network none -u node -v "$clone":/repo -v .../crb-audit-clone.sh:/audit.sh:ro --entrypoint bash <image> /audit.sh /repo <head-sha>`. The no-network/no-key properties are separately pinned by the passing bats case `the audit container has no network and no key` (executed 2026-08-19T23:03Z).

**Evidence:** `scripts/crb-audit-clone.sh:4-14`, `runs/review-arms/crb-pipeline/run-host.sh:482-496`, `runs/review-arms/crb-pipeline/docker/Dockerfile.review:26-28`, `test/crb-egress-config.bats:79-90`

---

## Claim 17: "Belt and braces on top of the container boundary — none of the commands below trigger hooks or a fsmonitor today, and these overrides mean that stays true if one is added later. safe.directory is NOT optional."

**Location:** `scripts/crb-audit-clone.sh:34-42`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five git subcommands this script runs and whether any consults hooks or the fsmonitor; does not establish that every git configuration key capable of executing code is neutralised (the overrides name three), nor that `safe.directory` is required in the operator's specific uid mapping.

The wrapper and the commands it fronts:

```bash
# scripts/crb-audit-clone.sh:40-42
git() { command git -c safe.directory="$CLONE" -c core.hooksPath=/dev/null \
                    -c core.fsmonitor= -c protocol.ext.allow=never \
                    -C "$CLONE" "$@"; }
```

The only git subcommands used are `remote` (`:48`), `fsck` (`:60`), `rev-list` (`:73`) and `merge-base --is-ancestor` (`:77`). None of these runs a hook (git's hook set is tied to checkout/commit/ref-update/push operations) and none refreshes the index, which is where `core.fsmonitor` is consulted — so "belt and braces" rather than load-bearing is the correct characterisation. The one non-git command is `find` (`:87`), which reads no config:

```bash
# scripts/crb-audit-clone.sh:87
nested=$(find "$CLONE" -mindepth 2 -name .git -prune -print 2>/dev/null | head -5)
```

All ten cases in `test/crb-audit-clone.bats` drive the real script against real fixture repos and pass, including the corrupt-object-store case that would surface an unexpected git failure (command `bats test/crb-audit-clone.bats …`, cwd `/workspace`, exit 0, 2026-08-19T23:03Z). Confidence Medium because "no git command ever triggers a hook" is an argument over git's full surface, not an exhaustive enumeration.

**Evidence:** `scripts/crb-audit-clone.sh:34-88`, `test/crb-audit-clone.bats:57-158`, `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt`

---

## Claim 18: "It is EVIDENCE, not prevention. Prevention is the egress allowlist the same script sets up; this records whether anything reached past it."

**Location:** `scripts/crb-audit-clone.sh:15-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the same runner both sets up the allowlist and invokes the audit, and that the audit only records rather than repairs; does not establish that the allowlist actually prevents anything at runtime (Claim 7).

`run-host.sh` is indeed "the same script" for both: it creates the network and proxy at `:156-172` and invokes the audit at `:493-496`. The audit itself only records and exits:

```bash
# scripts/crb-audit-clone.sh:90-96
if [ "${#traces[@]}" -gt 0 ]; then
  echo "CONTAINMENT VOID:"
  printf '  - %s\n' "${traces[@]}"
  exit 1
fi
echo "audit clean — no contamination detected (${n_strays} agent commit(s) on top of the head)"
echo "NOTE: absence of a detection is not proof of cleanliness; prevention is the egress allowlist."
```

The same framing is propagated into the machine-readable artifact rather than left in a comment:

```py
# runs/review-arms/crb-pipeline/run-host.sh:347-348
"voided_cells_meaning": "cells where contamination was DETECTED; "
                        "an empty list is not proof of cleanliness",
```

**Evidence:** `scripts/crb-audit-clone.sh:15-23`, `:90-97`, `runs/review-arms/crb-pipeline/run-host.sh:156-172`, `:341-348`, `:482-496`

---

## Claim 19: "`--untracked-files=all` still honours `.gitignore`, so a rubric written to a path the upstream repo ignores was invisible."

**Location:** `scripts/crb-harvest-artifacts.py:11-14` (repeated at `scripts/crb-materialize.py:264-266`, `runs/review-arms/crb-pipeline/run-host.sh:474-477`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git's treatment of ignored files under `--untracked-files=all` and the new harvest's independence from it; does not establish the frequency of the collision in the benchmark corpus (Claim 21).

The test builds a real repo, ignores `docs/reviews/`, and asserts git cannot see the file *before* asserting the harvest can — a negative control, so the case cannot silently stop testing what it claims:

```bash
# test/crb-harvest-artifacts.bats — "an artifact written to a gitignored path is still harvested"
run git -C "$CLONE" status --porcelain --untracked-files=all
[[ "$output" != *"rubric.md"* ]]
harvest
[ "$status" -eq 0 ]
[ -f "$DEST/docs/reviews/rubric.md" ]
```

Passes as `ok 32 an artifact written to a gitignored path is still harvested` (command `bats test/crb-audit-clone.bats test/crb-disposable-clone.bats test/crb-egress-config.bats test/crb-harvest-artifacts.bats`, cwd `/workspace`, exit 0, 2026-08-19T23:03Z). The claim that the *rubric* is the artifact at risk also checks out: `skills/code-review/SKILL.md:315` directs the orchestrator to write its `artifact under docs/reviews/`.

**Evidence:** `scripts/crb-harvest-artifacts.py:1-30`, `test/crb-harvest-artifacts.bats`, `skills/code-review/SKILL.md:315`, `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt`

---

## Claim 20: "Everything here treats the clone as untrusted content …: paths are generated by walking rather than parsed, symlinks are never followed or copied, and per-file and total size caps stop a hostile or runaway repo from filling the host disk."

**Location:** `scripts/crb-harvest-artifacts.py:22-25` (companion claim at `scripts/crb-materialize.py:266-269`, "a symlinked directory is the one way an os.walk could leave the clone")
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers symlink handling, path generation and the three caps in the harvest and in `artifact_index`; does not establish behaviour against a hardlink or a race in which the tree changes during the walk.

Both walkers disable link-following at the `os.walk` level *and* filter symlinked directories out of `dirs`, so a symlinked directory is neither descended into nor reported:

```py
# scripts/crb-harvest-artifacts.py:60-72
for root, dirs, files in os.walk(clone, followlinks=False):
    dirs[:] = [d for d in dirs
               if d != ".git" and not (Path(root) / d).is_symlink()]
    for name in files:
        ...
        if fp.is_symlink() or not fp.is_file():
            continue
```
```py
# scripts/crb-materialize.py:272-282
for root, dirs, files in os.walk(dst, followlinks=False):
    dirs[:] = [d for d in dirs
               if d != ".git" and not (Path(root) / d).is_symlink()]
```

Destination paths are derived from the walk (`rel = str(fp.relative_to(clone))`, `scripts/crb-harvest-artifacts.py:74`) rather than parsed out of git porcelain, which is what retires the old loop's `/*|*..*` traversal guard. The three caps are `MAX_FILE_BYTES = 5 * 1024 * 1024`, `MAX_TOTAL_BYTES = 50 * 1024 * 1024`, `MAX_FILES = 500` (`scripts/crb-harvest-artifacts.py:44-46`), and both cap paths print to stderr rather than truncating silently (`:110-119`). Pinned by the passing cases `a symlinked artifact is not harvested and not followed`, `an oversized file is skipped, named, and does not stop the harvest`, and `artifact_index covers .md/.json, skips .git, and ignores symlinks` (exit 0, 2026-08-19T23:03Z).

**Evidence:** `scripts/crb-harvest-artifacts.py:39-80`, `:105-127`, `scripts/crb-materialize.py:257-284`, `test/crb-harvest-artifacts.bats`, `test/crb-disposable-clone.bats`, `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt`

---

## Claim 21: "Several benchmark repos ignore `docs/`-adjacent paths; the code-review skill writes its rubric under `docs/reviews/`."

**Location:** `scripts/crb-harvest-artifacts.py:13-14` (same claim at `test/crb-harvest-artifacts.bats:12-15` and `docs/working/crb-direction1-setup.md`, "which some upstream repos ignore")
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the 5 materialized pilot clones under `external/crb-eval/`; does not establish anything about the 45 unmaterialized benchmark PRs, where the claim may well hold.

The general shape holds — two of the five pilot clones do ignore paths under `docs/`:

```
15:/docs/menu.yaml   54:docs/AWS_S3_BUCKET   55:docs/GIT_BRANCH
56:docs/GITCOMMIT    57:docs/changed-files          # grafana-PR79265/.gitignore
25:/src/sentry/apidocs/…  32:/src/sentry/integration-docs   # sentry-greptile-PR5/.gitignore
```

But the specific collision the sentence implies — the rubric's own path being ignored — does not occur in any of them. `git -C <clone> check-ignore -v docs/reviews/rubric.md docs/rubric.md` returned no match for all five clones (command run over `external/crb-eval/*/`, cwd `/workspace`, exit 1 per clone = "not ignored", 2026-08-19T23:05Z; captured inline above because the useful output is the empty result plus the two `.gitignore` excerpts shown).

This is the same shape as the logged hallucination pattern *"a specific measured value quoted from a checked-in artifact set that does not contain it"* — but it is not a fabrication: the claim is about the 50-PR corpus, of which only 5 are materialized here, and the ignore-a-`docs/`-path half is true for 2 of those 5. It does not qualify for the log. Precise version: *"some benchmark repos ignore paths under `docs/` (grafana, sentry among the pilot five); whether any ignores `docs/reviews/` specifically is unmeasured — the defect the harvest closes is the class, not a confirmed instance."*

**Evidence:** `scripts/crb-harvest-artifacts.py:11-14`, `external/crb-eval/grafana-PR79265/.gitignore`, `external/crb-eval/sentry-greptile-PR5/.gitignore`, `test/crb-harvest-artifacts.bats:12-15`

---

## Claim 22: "the harvest's `git status` was the FIRST host command after the container exited, and `core.fsmonitor` fires on exactly that"

**Location:** `scripts/crb-materialize.py:262-264` (same claim at `scripts/crb-harvest-artifacts.py:7-10`, `runs/review-arms/crb-pipeline/run-host.sh:473-475`, `test/crb-harvest-artifacts.bats:7-9`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the ordering of host commands in the pre-197eec6 runner; does not re-verify that `core.fsmonitor` executes on `git status` (that was executed by the 2026-08-19 critic, not re-run here).

In the deleted runner, three host commands ran between the container exiting and the `git status`: `rm -rf "$INST_HOME"`, the transcript-parsing python heredoc, and the loop's `mkdir -p` (paraphrased — no quote available with a live `path:line` because the source is the deleted blob `197eec6^:runs/review-arms/crb-pipeline/run-host.sh`; the ordering was read from that blob at lines ~330-381). `git status` was the first host **git** command, which is what makes the `core.fsmonitor` argument work — the imprecision does not weaken it.

Precise version: *"the harvest's `git status` was the first host `git` command after the container exited."* The conclusion (fsmonitor fires there; nothing in the replacement reads `.git`) is unaffected and is separately pinned:

```py
# scripts/crb-harvest-artifacts.py:10
   2026-08-19 review executed (rubric R1). Nothing in this file reads `.git`.
```
```bash
# test/crb-egress-config.bats:95-98
run grep -nE '^[^#]*\bgit\b[^#]*"\$clone"' "$RUNNER"
[ "$status" -ne 0 ]
```
(the case passes as `ok 26 the runner never runs host git against the work clone`, exit 0, 2026-08-19T23:03Z).

**Evidence:** `scripts/crb-materialize.py:257-270`, `scripts/crb-harvest-artifacts.py:1-30`, `runs/review-arms/crb-pipeline/run-host.sh:472-480`, `test/crb-egress-config.bats:92-99`

---

## Claim 23: "Load-bearing for the AUDIT … materialize()'s own fetches write both, so unless they are cleared here EVERY baseline would carry them and EVERY cell would void — and the checks would mean nothing. Clearing them is what makes their later presence evidence."

**Location:** `scripts/crb-materialize.py:229-234` (`scrub_object_store` docstring)
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the causal chain from materialize's fetches, through the scrub, to the two audit checks it makes non-vacuous; does not establish that the chain is currently *pinned by a test* — see Claim 25, which finds the removed suite's non-vacuity case has no counterpart.

The mechanism is exactly as described. `materialize()` fetches (`:387-389`, plus `resolve_base`'s deepening fetches at `:171`), then deletes every ref but `review`/`main` (`:410-412`) — which turns the fetched, now-unreferenced commits into unreachable objects — and only then scrubs:

```py
# scripts/crb-materialize.py:242-246
subprocess.run(["git", "symbolic-ref", "-d", "refs/remotes/origin/HEAD"],
               cwd=dst, capture_output=True, text=True)
sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
(dst / ".git" / "FETCH_HEAD").unlink(missing_ok=True)
```

Those are precisely the two signals the audit voids on:

```bash
# scripts/crb-audit-clone.sh:55
[ ! -e "$CLONE/.git/FETCH_HEAD" ] || note "FETCH_HEAD present — something fetched into this clone"
```
```bash
# scripts/crb-audit-clone.sh:60-62
fsck_out=$(git fsck --unreachable --no-reflogs --connectivity-only --no-progress 2>&1)
unreachable=$(printf '%s\n' "$fsck_out" | grep -c '^unreachable commit' || true)
[ "${unreachable:-0}" -eq 0 ] || note "$unreachable unreachable commit(s) — a deleted fetched ref leaves exactly this"
```

The `--snapshot` path re-runs the same scrub before verifying (`:527-528`), so a hand-snapshotted clone reaches the same baseline state. The docstring's own safety caveat ("Runs on a clone this script just built from the fork, before any container has seen it") matches both call sites.

**Evidence:** `scripts/crb-materialize.py:225-246`, `:387-416`, `:512-533`, `scripts/crb-audit-clone.sh:51-67`

---

## Claim 24: "Tests: 37 new across four suites (disposable-clone, audit-clone, harvest-artifacts, egress-config)"

**Location:** commit message `197eec6`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count and suite names of the added tests and that all pass; does not establish net test-count change (37 added against 22 removed = +15).

`grep -c '^@test'` over the four added files gives 10 + 9 + 9 + 9 = 37, and all four files are new in this commit (the `--stat` shows insertions only). All 37 pass:

```
ok 37 usage and a missing clone both exit 2
EXIT=0
```
(command `bats test/crb-audit-clone.bats test/crb-disposable-clone.bats test/crb-egress-config.bats test/crb-harvest-artifacts.bats`, cwd `/workspace`, exit 0, 2026-08-19T23:03Z; full output captured at `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt`.)

**Evidence:** `test/crb-audit-clone.bats`, `test/crb-disposable-clone.bats`, `test/crb-egress-config.bats`, `test/crb-harvest-artifacts.bats`, `docs/reviews/execution-logs/crb-r2-bats-197eec6.txt`

---

## Claim 25: "test/crb-containment-reset.bats removed with the code it pinned, its load-bearing void cases carried into crb-audit-clone"

**Location:** commit message `197eec6` (same claim at `test/crb-audit-clone.bats:9-20`, "exactly as in the reset suite this file inherits from")
**Type:** Architectural / Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the case-by-case mapping from the 22 removed cases to the 10 new audit cases; does not assess whether the two uncarried cases are worth re-adding (that is a test-strategy judgement, not a fact-check one).

Five of the removed suite's void cases have direct counterparts, and the mapping is clean:

| removed case | counterpart in `test/crb-audit-clone.bats` |
|---|---|
| `a re-added remote still VOIDS the cell` | `a surviving remote VOIDS` (`:71`) |
| `a bare fetch by URL leaves FETCH_HEAD and VOIDS` | `a FETCH_HEAD trace VOIDS` (`:79`) |
| `r1's exact attack: fetch by URL, delete the ref, commit on top — VOIDS` | `a fetched-then-deleted ref VOIDS via the unreachable commit` (`:89`) |
| `a commit outside the reviewed ancestry still VOIDS the cell` | `a commit that does not descend from the head VOIDS` (`:102`) |
| `the --reset CLI VOIDS on contamination` | every audit case drives the CLI (`audit() { run bash "$AUDIT" … }`, `:55`) |

Two removed void cases have **no** counterpart:

1. `scrub_object_store is load-bearing — benign sequence VOIDS without it`. `grep -rn 'scrub_object_store' test/ scripts/` returns three hits, all in `scripts/crb-materialize.py` — none in `test/` (paraphrased — no quote available because the assertion is about the absence of grep matches). The mechanism it pinned is still load-bearing (Claim 23), so it is now an unpinned invariant; the nearest survivor, `the unreachable-commit check is non-vacuous only because of --no-reflogs` (`test/crb-audit-clone.bats:146`), pins the flag, not the scrub.
2. `a tag pointing outside the reviewed ancestry still VOIDS the cell`. `grep -rn 'tag' test/crb-audit-clone.bats test/crb-disposable-clone.bats` returns no tag-creating case; the surviving descent case uses an orphan **branch** (`git -C "$CLONE" checkout -q --orphan foreign`, `test/crb-audit-clone.bats:103`). Both refs are walked by the same `git rev-list --all` (`scripts/crb-audit-clone.sh:73`), so the mechanism is covered even though the ref type is not.

Precise version: *"its load-bearing void cases carried into crb-audit-clone, except the `scrub_object_store` non-vacuity case (now unpinned) and the tag variant of the descent case (mechanism covered by the branch variant)."*

**Evidence:** `197eec6^:test/crb-containment-reset.bats`, `test/crb-audit-clone.bats:55-158`, `test/crb-disposable-clone.bats`, `scripts/crb-audit-clone.sh:73`, `scripts/crb-materialize.py:225-246`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11b** (`runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-19`): `ConnectPort 443` restricts the CONNECT method only — it does not refuse plain-HTTP proxying, which the file permits and constrains solely via `Filter`/`FilterDefaultDeny`. Reword to *"CONNECT is restricted to 443; plain-HTTP proxying is still served, and the filter is what constrains it."*

### Stale
- **Claim 5** (`docs/working/crb-direction1-setup.md:27`): the `--all` disk figure still reads `~6-7 GB`; with baselines it is ~13 GB, as the same commit's `scripts/crb-materialize.py:38` and `docs/decisions/034:63` both state.
- **Claim 14** (`runs/review-arms/crb-pipeline/run-host.sh:425`): "the tree reset below" survives from the deleted `--reset` design; the restore now runs *above*, at the top of the loop, and `:510-512` states nothing resets the tree afterwards.

### Mostly Accurate
- **Claim 3** (`docs/decisions/034:67-68`, `scripts/crb-materialize.py:263-266`): "strictly more complete" — true on the `.gitignore` case, but the new harvest skips symlinks and enforces 5 MB/50 MB/500-file caps that the old loop did not.
- **Claim 13** (`runs/review-arms/crb-pipeline/run-host.sh:193-196`): leg 2 accepts `000`, so it isolates "the filter works" only in combination with leg 1's positive result.
- **Claim 16** (`scripts/crb-audit-clone.sh:10-13`): the header's example `docker run` omits `-u node` and would be swallowed by the image's `ENTRYPOINT ["claude"]`; the real call uses `--entrypoint bash`.
- **Claim 21** (`scripts/crb-harvest-artifacts.py:13-14`): none of the 5 materialized pilot clones ignores `docs/reviews/`; 2 of 5 ignore other paths under `docs/`. Scope the claim to the class rather than a confirmed instance.
- **Claim 22** (`scripts/crb-materialize.py:262-264` and 3 sibling locations): `git status` was the first host **git** command after the container exited, not the first host command; the fsmonitor conclusion is unaffected.
- **Claim 25** (commit message): two removed void cases have no counterpart — the `scrub_object_store` non-vacuity case (now an unpinned invariant) and the tag variant of the descent case (mechanism covered by the branch variant).

### Unverifiable
- **Claim 7** (`runs/review-arms/crb-pipeline/docker/Dockerfile.review:3-8`): "a running cell needs exactly ONE reachable host" is an executable guarantee and `docker` is not available in this environment. Verifying it requires running the image on a docker host — which is what the egress preflight does, at $0, before the first paid cell. Note for the preflight: no `DISABLE_AUTOUPDATER` is set in image or runner.

## Goal-Alignment Note
- Answered: yes — 26 claims verdicted against commit `197eec6`, report at `docs/reviews/code-fact-check-report-r2.md`
- Out of scope: code-quality, security and test-strategy judgements (sibling critics own those); sibling commits on the branch, read for context only; the 45 unmaterialized benchmark clones, unavailable here
- Escalate: the one Incorrect (Claim 11b, `ConnectPort` credited with blocking plain-HTTP proxying) and two Stale comments are all one-line doc edits and do not gate a sweep. The one thing that does touch sweep readiness is Claim 7 — every docker-shaped guarantee remains Unverifiable in this environment by design, so the egress preflight is the gate, and it must be watched rather than assumed to pass on its first run.
