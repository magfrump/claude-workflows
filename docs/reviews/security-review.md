# Security Review — `feat/crb-direction1-harness`, commit `197eec6`

**Commit:** `197eec613c6cf986c929a926a705e76c4dd21605` ("feat(crb): egress allowlist + disposable clones (decision 034)")
**Scope:** PARTIAL — `git show 197eec6` only. Sibling commits on the branch are context, not under review.
**Date:** 2026-08-19
**Based on:** `docs/reviews/code-fact-check-report.md` (merged k=3), `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md`, `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md` (R1/R2/R4), `code-review-rubric-2026-08-18-...` (R3)
**High-churn files evaluated on resulting code, not diff:** `scripts/crb-materialize.py`, `runs/review-arms/crb-pipeline/run-host.sh`

Threat model as given: the repository under review is third-party content from a public
benchmark org; the review container runs `--dangerously-skip-permissions` with a live
`ANTHROPIC_API_KEY`; the reviewing agent has an incentive to reach the merged upstream PR.
Both repo-content prompt injection and the agent's own resourcefulness are in scope.
Nothing docker-shaped has been executed in the authoring environment — that is stated as
deliberate and is not reported as a defect below; what is assessed is whether the controls
as written would hold.

## Trust Boundary Map

```
B1 (moved):   [container-written .git in external/crb-eval/<slug>] → [`--restore`: rmtree + tar extract, NO host git] → [host filesystem]
B2 (new):     [same container-written .git]                        → [crb-audit-clone.sh inside `--network none` throwaway container] → [host operator's verdict / CONTAINMENT_FAILED]
B3 (RETAINED):[same container-written .git]                        → [HOST git: symbolic-ref -d / reflog expire / gc / rev-list / diff]  → [host process, via `--snapshot`]
B4 (new):     [review cell's outbound sockets]                     → [tinyproxy CONNECT filter on `--internal` net]     → [api.anthropic.com]
B5:           [ANTHROPIC_API_KEY in cell env]                      → [same egress allowlist]                            → [external network]
B6 (moved):   [container-written .md/.json in the clone]           → [crb-harvest-artifacts.py: no git, no symlink follow, size caps] → [runs/review-arms/crb-pipeline/<id>/artifacts]
B7:           [argv slug + instances.json manifest]                → [path construction in crb-materialize.py]          → [host `shutil.rmtree` / `tar --extract`]
B8 (new):     [review cell's DNS queries]                          → [docker embedded resolver 127.0.0.11 — NOT filtered] → [host's upstream resolvers → internet]
```

What enters from outside: a third-party git repository, and everything a
`--dangerously-skip-permissions` agent writes into it while holding an API key. The commit's
central assumption is that the host never interprets that content — B1, B2 and B6 are the
three places the old design did and no longer does. B3 is the one place it still does, and B4/B5
are new controls whose only honest verification is execution. B8 is named as residual in 034
but has no control at all.

## Findings

#### `--snapshot` runs host `git` against a container-written `.git`, and the runner tells the operator to do exactly that

**Severity:** High
**Location:** `scripts/crb-materialize.py:511-533` (CLI `--snapshot` branch, `scrub_object_store` at `:527`, `verify_containment` at `:528`); `scripts/crb-materialize.py:225-246` (`scrub_object_store`); `runs/review-arms/crb-pipeline/run-host.sh:413-418`
**Boundary:** B3 (retained), and B1 which it contradicts
**Move:** #1 trust boundaries, #2 implicit sanitization assumption, #5 invert the access-control model
**Confidence:** High

`scrub_object_store` states its own precondition as prose and enforces nothing:

```
236	    Runs on a clone this script just built from the fork, before any container
237	    has seen it, which is the only reason it is safe to run host `git` here.
```

Its second call site is the `--snapshot` CLI mode, which reaches it against **any** directory
under `external/crb-eval/<slug>` that contains a `.git`:

```
511	                elif args.snapshot:
512	                    dst = DST_ROOT / slug
513	                    if not (dst / ".git").is_dir():
514	                        raise RuntimeError(f"no clone at {dst}")
519	                    if (BASELINE_ROOT / f"{slug}.tar").exists() and not args.force:
527	                    scrub_object_store(dst)
528	                    n_commits, stat = verify_containment(dst, slug, head)
```

The only guard on that branch is `--force` against overwriting an *existing baseline*. There
is no check that a container has never run against the tree — and in the normal flow a
leftover clone is by definition post-container, because `run-host.sh:510-512` deliberately
leaves each cell's clone as the container wrote it. The runner then prints `--snapshot` as
the remediation for a missing baseline:

```
413	  python3 "$ROOT/scripts/crb-materialize.py" --restore "$id" || {
414	    echo "$id: RESTORE failed — skipping cell" >&2
415	    echo "    A clone materialized before 2026-08-19 has no baseline yet. If no" >&2
416	    echo "    container has ever run against it, build one once:" >&2
417	    echo "      python3 scripts/crb-materialize.py --snapshot $id" >&2
```

The commands `scrub_object_store` then runs are the same class the 2026-08-19 review
*executed* out of. Rubric R1 (Critical) names `symbolic-ref -d` and `gc` explicitly, and
`docs/working/crb-direction1-setup.md:126-131` records that the host-side
`checkout --force`/`reset --hard`/`clean -qffdx`/`gc`/`fsck` "executed `post-checkout` and
`reference-transaction` hooks, `core.hooksPath`, `core.fsmonitor`, and a `filter.X.smudge`
reachable from tracked `.gitattributes` **with no agent action at all**". `git symbolic-ref -d`
performs a ref transaction, so a `.git/hooks/reference-transaction` or a `core.hooksPath` the
container wrote fires on line 242 — host code execution as the operator, before any of the
verification on line 528 runs. `verify_containment`'s own `git diff --shortstat main review`
(`:219`) additionally interprets `.gitattributes` diff drivers from the same untrusted config.
Nothing about the container boundary that closed R1 for the per-cell path applies here.

The R6 regression makes this the *expected* first-run experience rather than an edge case:
`run-host.sh:366` gates every instance on `$CLONES/.baselines/$id.tar`, the five clones that
exist predate baselines, so the first run of the new harness skips every cell and prints the
`--snapshot` instruction (the fact-check rates 034:69-70's "R6 dissolves" **Incorrect** for
exactly this reason). Severity is one notch below R1's Critical only because the trigger is an
operator command rather than the unattended per-cell loop; if the operator follows the text the
runner prints, the mechanism is identical.

**Recommendation:** Make the precondition machine-checked or remove the path. Cheapest correct
fix: delete `--snapshot` and change both remediation messages (`run-host.sh:367`, `:415-418`,
`docs/working/crb-direction1-setup.md:30`) to `--slug <id> --force`, which re-clones from the
fork and reaches `scrub_object_store` only on a tree this script just built. If `--snapshot`
must survive for the five pre-existing clones, run its scrub+verify inside the same throwaway
container pattern `crb-audit-clone.sh` already uses, and add the non-vacuity test the
migration dropped (fact-check §"three void cases did not carry over").

#### A detected containment void does not stop the sweep

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:493-509`, `:578-581`
**Boundary:** B2, B4
**Move:** #3 check the error path
**Confidence:** High

```
493	  if ! docker run --rm --network none -u node \
496	        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha"; then
497	    echo "$id: POST-RUN containment audit FAILED — voiding this cell" >&2
498	    : > "$dest/CONTAINMENT_FAILED"
```

The cell is marked and the loop continues to the next paid cell. A void means the egress
allowlist — the control this commit exists to add — did not hold, or the agent found a
retrieval path the allowlist does not cover. Continuing to spend `$10–40` per cell for the
remaining instances under a control that has just been observed failing is the wrong default,
and the sweep-level exit code cannot express it either: `:578` exits non-zero only when
`ran -eq 0 && skipped_bad -gt 0`, so a sweep in which every cell voided still exits 0. The
budget gate at `:544` is the only thing that stops it, and it stops it for the wrong reason.

**Recommendation:** Treat the first void as a halt condition (exit non-zero immediately, or gate
continuation behind an explicit `ALLOW_VOIDED_CELLS=1`), and make the final exit non-zero
whenever `voided_cells` is non-empty.

#### Plain-HTTP proxying is an unfiltered-by-`ConnectPort`, untested path through the only egress control

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:18-20`; `runs/review-arms/crb-pipeline/run-host.sh:435-436`, `:206-214`
**Boundary:** B4, B5
**Move:** #11 enumerate bypasses, #2 implicit sanitization assumption
**Confidence:** Medium

```
18	# CONNECT to 443 only: plain-HTTP proxying and every other port are refused, so
19	# the tunnel cannot be repointed at an arbitrary service.
20	ConnectPort 443
```

The fact-check rates this **Incorrect**: `ConnectPort` scopes the CONNECT method only. Plain
`GET http://host/…` proxying is a different tinyproxy code path, and the runner exports the
lowercase and uppercase HTTP variants to every cell and every preflight container:

```
435	    -e HTTPS_PROXY="$PROXY_URL" -e HTTP_PROXY="$PROXY_URL" \
436	    -e https_proxy="$PROXY_URL" -e http_proxy="$PROXY_URL" \
```

The `Filter`/`FilterDefaultDeny` pair should still apply on that path, so the residual exposure
is probably nil — but "probably" is the whole problem. Preflight leg 2 (`:208`) exercises
`https://github.com/` only, `test/crb-egress-config.bats:45-54` pins `ConnectPort 443` as
though it were the plain-HTTP guard, and the config comment tells the next reader that the
CONNECT port is what closes it. That combination is how a future edit — adding a host,
relaxing the filter, or moving to a proxy whose non-CONNECT filtering differs — passes review.
Two consequences remain even if the filter does apply as documented: a cell can proxy plain
HTTP to `api.anthropic.com` on an arbitrary port (`ConnectPort` does not bound it), and the
`api.anthropic.com` leg of B5 is cleartext if anything ever uses it.

**Recommendation:** Correct the comment to credit `Filter`/`FilterDefaultDeny`, and add a
preflight leg 2b — `curl -x $PROXY_URL http://github.com/` must return 403/000 — so the
non-CONNECT path is proven rather than assumed. Consider unsetting `HTTP_PROXY`/`http_proxy` in
the cell if nothing needs plain HTTP, which removes the path instead of testing it.

#### DNS through docker's embedded resolver is an unfiltered bidirectional channel

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:156-166` (network creation), `:432-444` (cell invocation); acknowledged at `docs/decisions/034-...:75-77`
**Boundary:** B8
**Move:** #1 trust boundaries, #11 enumerate bypasses
**Confidence:** Medium

```
159	  docker network create --internal --subnet "$EGRESS_SUBNET" "$EGRESS_NET" >/dev/null
```

`--internal` blocks IP routing off the host; it does not block the embedded resolver at
`127.0.0.11`, which lives in the container's netns and is serviced by the daemon on the host
side. A cell can therefore emit arbitrary DNS queries that leave the machine. That is a working
exfiltration channel for `ANTHROPIC_API_KEY` (chunked into labels of an attacker-controlled
domain reachable from a hostile fork's content) and a low-bandwidth retrieval channel. 034
names it as residual and unclosed, which is the honest disposition — but the decision record is
the only place it appears, and the two artifacts an operator actually reads before spending
(`run-host.sh`'s header, `crb-direction1-setup.md`'s guard list) both describe the cell as
needing "exactly ONE reachable host". The fact-check rates that phrasing **Mostly Accurate**
for a different reason; B8 is the reason it is not accurate at all.

**Recommendation:** Either close it — pin the proxy's address with `docker network connect --ip`,
set `PROXY_URL` to that literal IP, and run cells with a resolver that cannot answer (e.g.
`--dns 127.0.0.1`), so the proxy is reachable without the cell having name resolution — or
carry the residual into `run-host.sh`'s header and the setup doc's guard list, where the person
authorizing the spend will see it.

#### Egress preflight proves nothing about the host or sibling containers

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:215-223`
**Boundary:** B4
**Move:** #5 invert the access-control model, #11 enumerate bypasses
**Confidence:** Medium

```
218	direct=$(docker run --rm --network "$EGRESS_NET" --entrypoint bash "$REVIEW_IMAGE" \
219	  -c 'curl -s -o /dev/null -w "%{http_code}" --max-time 20 https://github.com/ || echo 000')
```

Leg 3 establishes that one internet host is unroutable without the proxy. It says nothing about
what *is* reachable on the internal segment: the bridge gateway address (i.e. services listening
on the docker host, which on WSL includes the developer's own machine), other containers the
operator happens to have running, or the proxy container's second interface. Inverting the
control: the allowlist enumerates one permitted destination, and the preflight verifies one
denied destination; the set of destinations that are neither is unenumerated. This is not
speculative for the answer-key threat specifically — a local git mirror, a running IDE server,
or a `docker.sock` proxy on the host would all sit in that set.

**Recommendation:** Add a fourth leg that asserts the docker host's gateway address is
unreachable from the cell network on a port the operator knows is listening, and state in the
header that the control's guarantee is "no route off this host", not "no route anywhere".

#### `--snapshot --force` launders a used clone into the baseline *and* into the manifest's integrity pin

**Severity:** Medium
**Location:** `scripts/crb-materialize.py:519-533`, `:287-296` (`snapshot_baseline` docstring), `:351-358` (`restore_clone`'s sha check)
**Boundary:** B1, B3
**Move:** #4 time-of-check to time-of-use
**Confidence:** High

```
530	                    rec.update(snapshot_baseline(dst, slug))
531	                    manifest[slug] = rec
532	                    MANIFEST.write_text(
533	                        json.dumps(manifest, indent=2, sort_keys=True) + "\n")
```

`restore_clone`'s hash pin (`:351-358`) compares the tar against `baseline_sha256` **in the
manifest**, and this is the code path that writes that field. A snapshot taken over a used
clone therefore does not merely produce a dirty baseline — it re-pins the manifest to it, after
which every later `--restore` and every `--verify` reports the laundered tree as intact, for
the rest of the arm. The check and the value it checks against have the same author. The
docstring at `:288-295` states the invariant ("ONLY EVER CALL THIS ON A CLONE NO CONTAINER HAS
TOUCHED") and names `--force` as the escape hatch; nothing verifies it.

**Recommendation:** If `--snapshot` survives finding 1, require the tree to be provably pristine
before it can re-pin the manifest — at minimum re-run `verify_containment` *before*
`scrub_object_store` rather than after, refuse when `.git/FETCH_HEAD`, unreachable commits, or a
nested `.git` are present (the same evidence `crb-audit-clone.sh` already collects), and record
in the manifest that this baseline came from `--snapshot` rather than from a fresh clone.

#### CLI slug arguments are not charset-validated; traversal is blocked only incidentally

**Severity:** Low
**Location:** `scripts/crb-materialize.py:474-479`, `:348-363` (`restore_clone`), `:97-112` (`slug_for`, the validation that does exist)
**Boundary:** B7
**Move:** #2 implicit sanitization assumption
**Confidence:** High

`slug_for` validates the charset because "`Path(DST_ROOT) / "/abs"` would silently discard
DST_ROOT while a `/` or `..` component would escape it — into a tree that --force then
shutil.rmtree()s" (`:101-104`). That validation is on the *dataset-derived* path only. The
`--verify`/`--restore`/`--snapshot` modes take slugs straight from argv (`:475`) and interpolate
them into `BASELINE_ROOT / f"{slug}.tar"`, `DST_ROOT / slug`, and a `shutil.rmtree`, with
`run-host.sh:105-106` forwarding its own argv into the same modes. Traversal is currently
stopped, but only as a side effect: `--restore` needs `baseline_sha256` from a manifest entry
that a traversal slug will not have, and `--snapshot`/`--verify` need `head` from the same
place. Those are correctness guards being asked to do a security job they were not written for.

**Recommendation:** Apply the same `re.fullmatch(r"[A-Za-z0-9_-]+", slug)` at the top of the
`--verify/--restore/--snapshot` branch, next to the mode dispatch.

#### Review image leaves the autoupdater and non-essential traffic enabled

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:13-28`
**Boundary:** B4
**Move:** #10 dependency changes (baked toolchain), #1 trust boundaries
**Confidence:** Medium

The image bakes a pinned CLI (`:18`) and asserts it at build time (`:23`), but sets no
`DISABLE_AUTOUPDATER`, `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, or
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`. This repo's own
`devcontainer-config/egress/base.txt` lists five further hosts the CLI contacts
(`claude.ai`, `console.anthropic.com`, `sentry.io`, `statsig.com`, `registry.npmjs.org`).
Today the allowlist denies all five, so the effect is failed connections and log noise rather
than a leak — but the pinned `CC_VERSION` is the arm's reproducibility claim, and the
autoupdater is a mechanism by which the artifact under test can change itself the moment
`registry.npmjs.org` becomes reachable (a future allowlist edit, a proxy misconfiguration, or a
cell run outside this harness). `USER node` with a root-owned global install (`:18`, `:26`)
makes the update fail rather than succeed today; that is an accident of layering, not a control.

**Recommendation:** Add `ENV DISABLE_AUTOUPDATER=1 DISABLE_TELEMETRY=1 DISABLE_ERROR_REPORTING=1
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` to `Dockerfile.review`, and pin the count in
`test/crb-egress-config.bats` alongside the existing "bakes the CLI" assertion.

#### Audit container mounts the untrusted clone read-write

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:493-496`
**Boundary:** B2
**Move:** #5 invert the access-control model
**Confidence:** High

```
494	        -v "$clone":/repo \
495	        -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
```

The audit script is correctly mounted `:ro`; the clone is not, and the audit only ever reads.
`git fsck`/`rev-list` on a hostile repo have no reason to need write access, and a read-only
mount would remove the audit itself as a way for repo content to alter the record it is about
to produce. The clone is wiped by the next `--restore` regardless, so this is hardening, not a
live hole.

**Recommendation:** Mount `-v "$clone":/repo:ro`; if a git command objects, mount an overlay or
copy instead.

### Untested bypass candidates (move #11)

Enumerated against the egress allowlist (B4/B5). Docker is unavailable in this environment, so
none of the network-dependent candidates could be exercised; the traced ones were traced through
`tinyproxy.conf` semantics and `run-host.sh` statically.

| # | Candidate | Disposition |
|---|-----------|-------------|
| 1 | Trailing-dot FQDN `api.anthropic.com.` | **Traced** (read-static): anchored ERE `^api\.anthropic\.com$` does not match → denied. Fails closed. |
| 2 | Suffix/prefix variants `evil-api.anthropic.com`, `api.anthropic.com.evil.tld` | **Traced** (read-static): both anchors present → denied. |
| 3 | Raw IP literal `CONNECT 140.82.x.x:443` | **Traced** (read-static): filter matches the host string, an IP literal matches no entry → denied. |
| 4 | `CONNECT host:22` / any non-443 port | **Traced** (read-static): `ConnectPort 443` (`tinyproxy.conf:20`) refuses. |
| 5 | Case variants `API.ANTHROPIC.COM` | **Traced** (read-static): `FilterCaseSensitive Off` → allowed, intended. |
| 6 | Plain-HTTP absolute-URI `GET http://github.com/` via the exported `HTTP_PROXY` | **Untested** — different tinyproxy code path; no test and no preflight leg exercises it (finding 3). |
| 7 | Plain-HTTP to a non-standard port on the allowed host, `http://api.anthropic.com:9999/` | **Untested** — `ConnectPort` does not bound the non-CONNECT path. |
| 8 | DNS queries to `127.0.0.11` as an exfil/retrieval channel | **Untested** — no docker; mechanism argued in finding 4, acknowledged as residual in 034. |
| 9 | Docker host gateway / sibling containers on the internal segment | **Untested** — preflight leg 3 covers one internet host only (finding 5). |
| 10 | CR/LF or `%00` smuggling in the CONNECT target host | **Untested** — needs a running proxy; low plausibility, but unexercised. |

Per the skill's rule, the egress allowlist therefore does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** The per-cell path in `run-host.sh` contains no host-side `git` invocation against
  the clone directory; the only `git` calls in the file target `$ROOT`.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:126-128`, `:94`, `:413-509`
  **Evidence:** read-static
  **Verified:** Read the whole file; every `git` occurrence is `git -C "$ROOT" archive|rev-parse`.
  Harvest is `crb-harvest-artifacts.py` (no `git` import, no `.git` read) and the audit is a
  `docker run`. `test/crb-egress-config.bats` pins the absence.
  **Not verified:** `scripts/crb-cell-status.py`, invoked at `:377`, was not read — it is a
  sibling-commit file that receives only `$dest/result.json`, but its own file access was not traced.
  **route: code-fact-check**

- **Claim:** A non-zero exit from `crb-audit-clone.sh` — including exit 2, "could not check" —
  voids the cell rather than passing it.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:493-508`; `scripts/crb-audit-clone.sh:23-32`
  **Evidence:** read-static
  **Verified:** The runner branches on `if ! docker run …`, which is true for any non-zero status;
  the audit's usage/validation failures exit 2 and the contamination path exits 1.
  **Not verified:** whether `docker run` itself can exit 0 while the in-container script was never
  reached (e.g. an image-level failure), which would read as a clean audit.
  **route: code-fact-check**

- **Claim:** `restore_clone` refuses to extract when the baseline tar's sha256 differs from the
  manifest's `baseline_sha256`, and refuses when the field is absent.
  **Location:** `scripts/crb-materialize.py:348-366`
  **Evidence:** read-static
  **Verified:** Read both raise sites (`:352-353`, `:356-358`); the `rmtree` at `:361` is
  downstream of both.
  **Not verified:** that the manifest itself is trustworthy at that moment — finding 6 names the
  path (`--snapshot --force`) that rewrites the pin.

- **Claim:** `crb-harvest-artifacts.py` does not follow or copy symlinks, and caps per-file,
  total-byte and file-count output.
  **Location:** `scripts/crb-harvest-artifacts.py:60-80`, `:44-46`, `:107-124`
  **Evidence:** read-static
  **Verified:** `os.walk(..., followlinks=False)`, symlinked directories pruned from `dirs[:]`,
  `fp.is_symlink()` skipped, `shutil.copyfile` (not `copy2`) so no mode bits carry over, and all
  three caps enforced before the copy.
  **Not verified:** behaviour when a file grows between `src.stat()` (`:109`) and `copyfile`
  (`:122`) — no container is running at that point, but the window was not exercised.
  **route: code-fact-check**

- **Claim:** Each cell receives its own writable copy of the payload, and the payload source is a
  `git archive` extract that is never mounted into any container.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:124-131`, `:422`, `:449`
  **Evidence:** read-static
  **Verified:** `PAYLOAD_SRC` appears only in `cp -r` sources and the EXIT trap; the mounts at
  `:438` and `:239` are `$INST_HOME`/`$PF_HOME`, both `mktemp -d` copies, both removed after use.
  **Not verified:** whether a cell can influence the *next* cell through anything else the host
  carries forward — `$dest/attempts.jsonl` and `result.json` are host-written, but the artifacts
  directory holds cell-authored files and was not traced to a later consumer.

- **Claim:** `crb-audit-clone.sh` neutralises hooks and fsmonitor on every git call it makes.
  **Location:** `scripts/crb-audit-clone.sh:40-42`
  **Evidence:** read-static
  **Verified:** A shell function shadows `git`, so all seven call sites inherit
  `core.hooksPath=/dev/null`, `core.fsmonitor=`, `protocol.ext.allow=never`, `safe.directory`.
  **Not verified:** config keys not in that list that the commands used could still honour
  (`include.path`, `diff.external`, `filter.*`, `core.worktree`) — none of the commands used
  reads the worktree or generates a diff today, but that was reasoned about, not executed. The
  container boundary is what makes this non-load-bearing.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `--snapshot` runs host git on a container-written `.git`; the runner prints it as the remedy | High | B3 | `crb-materialize.py:511-533`, `run-host.sh:413-418` | High |
| 2 | A detected containment void does not stop the sweep or change the exit code | Medium | B2, B4 | `run-host.sh:493-509`, `:578-581` | High |
| 3 | Plain-HTTP proxying is untested and miscredited to `ConnectPort` | Medium | B4, B5 | `tinyproxy.conf:18-20`, `run-host.sh:435-436` | Medium |
| 4 | Docker embedded DNS is an unfiltered channel, disclosed only in 034 | Medium | B8 | `run-host.sh:156-166`, `:432-444` | Medium |
| 5 | Preflight proves nothing about the host or sibling containers | Medium | B4 | `run-host.sh:215-223` | Medium |
| 6 | `--snapshot --force` re-pins the manifest to a laundered baseline | Medium | B1, B3 | `crb-materialize.py:519-533` | High |
| 7 | CLI slugs unvalidated; traversal blocked only incidentally | Low | B7 | `crb-materialize.py:474-479` | High |
| 8 | Autoupdater/telemetry not disabled in the review image | Low | B4 | `Dockerfile.review:13-28` | Medium |
| 9 | Audit container mounts the untrusted clone read-write | Informational | B2 | `run-host.sh:493-496` | High |

## Overall Assessment

This is a real improvement in kind, not degree: R1/R2 were closed by removing the interpreter
rather than by enumerating what it interprets, and R3 was answered with a prevention control
instead of a detector. The disposable-clone design is sound where it is followed — the per-cell
path genuinely contains no host `git`, the audit runs where a hostile `.git` reaches nothing that
outlives it, and the harvest was rewritten to avoid `.git` entirely while also fixing the
`.gitignore` blind spot. The single most important thing to address is finding 1: `--snapshot` is
the one surviving edge on B3, its precondition is prose, and the R6 regression makes the runner
print that exact command on the first run against the clones that exist today. Deleting the mode
in favour of `--slug --force` closes it with a smaller diff than defending it. Findings 2–5 are
all fixable in place and share a shape worth naming: the controls are stronger than the evidence
collected about them — one preflight leg per control, each testing the case the author had in
mind. Since the preflight is the design's own answer to "the only honest verification is
execution", widening it (plain HTTP, host reachability, DNS) is cheap and is the right place to
spend before the first paid cell.

No findings within the code paths read; endorsement claims pending execution verification — and
per move #11 the egress allowlist itself carries five untested bypass candidates, so it is not
endorsed here at all. The preflight is the correct place to convert them, and it costs $0.

## Goal-Alignment Note
- Answered: yes — the escalated `--snapshot` question resolves as a reopening of R1 on that path, with a named fix
- Out of scope: everything docker-shaped (no docker available, per the brief); sibling commits; `scripts/crb-cell-status.py` and `crb-pipeline-to-benchmark.py`, which are not in this commit
- Escalate: the R6 regression (`run-host.sh:366` skips all five existing clones) is an availability defect the fact-check already rated Incorrect at 034:69-70, but it is also what makes finding 1 reachable — whoever fixes R6 should fix it by pointing at `--slug --force`, not `--snapshot`
