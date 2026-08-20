# Security Review — `feat/crb-direction1-harness`, commits `1d8ea67`..`4624c5d`

**Commit:** `4624c5d` (HEAD); scope `git diff c98343b..HEAD -- scripts runs test docs/decisions docs/working` (13 files, +912/−201)
**Scope:** PARTIAL — the two fix commits only. `197eec6` is already reviewed and is context, not under review.
**Date:** 2026-08-19
**Based on:** `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness-r2.md` (R1–R4, A1–A14); the prior iteration's `docs/reviews/security-review.md` (findings 1–9 on `197eec6`), which this file replaces.
**Position:** TERMINAL pass of a review-fix loop at its 3-iteration cap.

> ⚠️ **No code fact-check report was supplied to this pass.** An iteration-2 fact-check is
> referenced by the commits themselves but was not provided as input here. Claims about
> security properties in comments and documentation were therefore re-derived from the code,
> and where I state a property I say whether I executed it or only read it.

Threat model as given, unchanged: the repository under review is third-party content from a
public benchmark org; the review container runs `--dangerously-skip-permissions` with a live
`ANTHROPIC_API_KEY`; a reviewing agent has an incentive to reach the merged upstream PR. Both
repo-content prompt injection and the agent's own resourcefulness are in scope. Nothing
docker-shaped ran in this environment; that is not reported as a defect. What is assessed is
whether the controls as written would hold.

No Critical Finding Escalation pattern matched.

## Trust Boundary Map

```
B1 (unchanged): [container-written .git in external/crb-eval/<slug>] → [--restore: sha256-pinned tar + index, rmtree + extract, NO host git] → [host filesystem]
B2 (unchanged): [same container-written .git]                        → [crb-audit-clone.sh inside --network none throwaway container]        → [operator verdict / CONTAINMENT_FAILED / exit 4|6]
B3 (REMOVED):   [same container-written .git]                        → [HOST git: symbolic-ref -d / gc / rev-list / diff, via --snapshot]     → [host process]   ← closed this pass
B4 (unchanged): [review cell's outbound sockets]                     → [tinyproxy Filter + ConnectPort on an --internal net]                  → [api.anthropic.com]
B5 (new):       [docker/curl observations: http codes, a command line] → [scripts/crb-egress-verdict.sh `case` rules → egress_leg exit 5]     → [the decision to spend $10–40 per cell]
B6 (unchanged): [ANTHROPIC_API_KEY in cell env]                      → [same egress allowlist]                                                → [external network]
B7 (unchanged): [container-written .md/.json in the clone]           → [crb-harvest-artifacts.py: no git, no symlink follow, size caps]       → [runs/review-arms/crb-pipeline/<id>/artifacts]
B8 (widened):   [argv/manifest slug]                                 → [crb-materialize.py --baseline-paths → mapfile → bash path tests]      → [host `-f` tests, harvest argv]
B9 (unchanged): [review cell's DNS queries]                          → [docker embedded resolver 127.0.0.11 — NOT filtered]                   → [host resolvers → internet]
B10 (new):      [CONTAINMENT_FAILED marker written by a prior sweep]  → [`rm -f` at cell start / voided count at sweep end]                    → [run-meta.json voided_cells, sweep exit status]
```

The one structural improvement in this pass is that **B3 is gone**: the last host-`git`-on-a-
container-written-`.git` path was deleted rather than guarded. The one structurally new
boundary is **B5** — a shell script's exit status is now the sole gate on all spending, and its
inputs are strings produced by `docker`/`curl`. **B10** is new and is where two of the findings
below sit: the void protocol now has a delete on one side and a count on the other, and they
are not symmetric.

## Findings

#### The `api-reachable` verdict fails open on every observation except the literal `000`

**Severity:** Medium
**Location:** `scripts/crb-egress-verdict.sh:44-55`; consumed at `runs/review-arms/crb-pipeline/run-host.sh:241`
**Boundary:** B5 (new), which anchors B4
**Move:** #3 check the error path, #11 enumerate bypasses
**Confidence:** High (executed)
**Legibility-target:** for-author

```
50	    if [ "$observed" = "000" ]; then
51	      echo "FAIL api-reachable: api.anthropic.com unreachable through the proxy — every cell would fail"
52	      exit 1
53	    fi
54	    echo "ok  api.anthropic.com reachable through the proxy (HTTP $observed)"
```

Executed against the committed script:

```
$ bash scripts/crb-egress-verdict.sh api-reachable ""
ok  api.anthropic.com reachable through the proxy (HTTP )        # exit 0
$ bash scripts/crb-egress-verdict.sh api-reachable "curl: (6) Could not resolve"
ok  api.anthropic.com reachable through the proxy (HTTP curl: (6)…)  # exit 0
$ bash scripts/crb-egress-verdict.sh api-reachable "000x"
ok  …                                                             # exit 0
```

An **empty** observation is the reachable one. `run-host.sh:241` builds the argument from
`$(in_cell_net 'curl … || echo 000')`; the `|| echo 000` covers a failing *curl*, not a failing
*container*. A `docker run` that fails to start (image gone, daemon hiccup, OOM, the 125/126/127
class this same commit learned to distinguish for the audit) writes its error to stderr and
leaves stdout empty — and an empty string is not `000`, so the leg prints `ok`.

That matters more than a single leg, because this leg is what the other two refusal legs are
*documented to depend on* (`:47-49`: "legs 2 and 4 accept `000` as a refusal, and `000` is also
what an unreachable proxy returns, so on their own they cannot tell a working filter from a
dead proxy"). If leg 1 can pass without observing anything, a dead proxy yields
`internal-net ok / api-reachable ok / filter-blocks 000 ok / plain-http 000 ok /
no-direct-route 000 ok` — a fully green preflight in which the allowlist was never exercised,
followed immediately by paid cells. A second, non-hypothetical instance of the same weakness:
if `EGRESS_SUBNET` is overridden (an invited override, `run-host.sh:114`) the proxy's baked
`Allow 172.31.250.0/24` no longer matches and tinyproxy answers **403 to everything**; leg 1
sees `403`, calls it reachable, and legs 2/2b see the same `403` and call it filtered. The
allowlist has proven nothing in either case. `test/crb-egress-verdict.bats` pins `200 401 403
404 500` as passes and `000` as a fail; it never passes an empty or malformed observation.

The direction of failure is fail-*closed* for containment itself (the network is still
`--internal`, so cells reach nothing), so this is not a route to the answer key. What it
breaks is the arm's central honesty claim — that the control is proven by execution before
money is spent — at exactly the moment the money is authorized.

**Recommendation:** Make leg 1 assert a *real* API answer rather than the absence of one
sentinel: `case "$observed" in 200|401|403) ok ;; *) FAIL` — and distinguish tinyproxy's own
`403 Access denied` from an upstream answer (e.g. probe a second allowlisted path, or assert
`401`, the documented expected status). Separately, make `egress_leg` reject an observation
that is not three digits before it reaches the verdict script. Add bats cases for `""` and a
non-numeric observation on every leg.

#### `rm -f CONTAINMENT_FAILED` at cell start erases a prior sweep's void with no re-decision

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:503-506`, `:520-529`, `:690-699`; `:355-357` (run-meta)
**Boundary:** B10 (new), B2
**Move:** #4 time-of-check/time-of-use, #3 check the error path
**Confidence:** High
**Legibility-target:** for-author

```
503	  # A void marker from an EARLIER sweep must not make this sweep exit 6: nothing
504	  # else ever deletes it, so the status would be sticky forever once any cell had
505	  # ever voided. This cell is about to be re-decided, so its old verdict goes.
506	  rm -f "$dest/CONTAINMENT_FAILED"
```

"This cell is about to be re-decided" is the load-bearing assumption, and it is not enforced.
The delete happens *before* the two paths that can leave the cell un-re-decided:

```
515	  python3 "$ROOT/scripts/crb-materialize.py" --restore "$id" || {
516	    echo "$id: RESTORE failed — skipping cell (nothing was paid for)" >&2
…
519	    skipped_bad=$((skipped_bad+1)); continue; }
```

A baseline hash mismatch, a missing index, or a `--force` rebuild that has not been run yet all
land there — after the marker is gone. The cell is counted `skipped_bad`, the sweep can still
exit 0 if anything else ran, and `write_run_meta` (`:355-357`) reads the same marker to build
`voided_cells`, so the JSON provenance artifact loses the record too. The end-of-sweep counter
that produces `exit 6` (`:690-699`) counts markers on disk, so a deleted marker is an
uncounted void.

The reversible-by-retry case is the same shape and is reachable in the ordinary flow: a void
sets `is_error=true, subtype="containment_failed"` on `result.json` (`:646-655`), which
`crb-cell-status.py:75-77` classifies as incomplete, so on the next invocation the cell re-runs
under `MAX_ATTEMPTS=2`, the marker is deleted, and a second audit that happens to pass leaves
the sweep exiting 0 with `voided_cells: []`. A containment breach that was *detected once* does
not stop being a breach because a re-run of the same cell came back clean — the transcript,
the cost and the artifacts of the first attempt are still on disk, and the arm's published
numbers no longer say so.

**Recommendation:** Make the void record append-only. Keep the per-attempt verdict in
`attempts.jsonl` (which already exists and is already written before the audit) and derive both
`voided_cells` and the `exit 6` decision from *any* attempt having voided, rather than from a
marker file that the next attempt deletes. If a marker is still wanted for the current state,
move the `rm -f` to immediately after a *passing* audit, not to cell start.

#### A detected void still does not stop the sweep — only the exit code changed

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:643-657` (no `continue`/`exit` in the void branch), `:690-699`
**Boundary:** B2, B4
**Move:** #3 check the error path, #5 invert the access-control model
**Confidence:** High
**Legibility-target:** for-author

```
643	  if [ "$audit_rc" -eq 1 ]; then
644	    echo "$id: POST-RUN containment audit FAILED — voiding this cell" >&2
645	    : > "$dest/CONTAINMENT_FAILED"
…
656	  fi
657	  # The clone is left as the container wrote it; the NEXT cell's --restore wipes
```

Control flow falls straight through to the next iteration. The prior review's recommendation
had two halves — "treat the first void as a halt condition **and** make the final exit non-zero
whenever `voided_cells` is non-empty" — and only the second half landed (`exit 6`, `:699`). A
void is direct evidence that the egress allowlist, the control this whole commit exists to add,
did not hold for the cell that just ran. Continuing to spend $10–40 per cell for the remaining
instances under a control observed failing is default-allow: the uncovered case (the control is
broken) is handled by continuing, and the operator learns at the end.

Note the asymmetry the commit itself introduces one branch earlier: `audit_rc > 1` ("could not
check") **does** stop the sweep with `exit 4` (`:637-642`). The weaker signal halts; the
stronger one does not.

**Recommendation:** Halt on the first void — `exit 6` from inside the loop after
`write_run_meta` is guaranteed by the EXIT trap — or gate continuation behind an explicit
`ALLOW_VOIDED_CELLS=1`. Keep the end-of-sweep count for the resumed-sweep case.

#### The DNS side channel is disclosed but unclosed, and the proxy's hostname URL now makes closing it more expensive

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:49-54` (disclosure), `:116` (`PROXY_URL`), `:176-178` (network create); `docs/decisions/034-…:95-97`
**Boundary:** B9
**Move:** #1 trust boundaries, #6 follow the secrets
**Confidence:** Medium
**Legibility-target:** for-author

```
49	#   WHAT IT DOES NOT CLOSE, stated here rather than only in decision 034 because
50	#   this is where spend is authorized: containers on $EGRESS_NET still reach
51	#   docker's embedded DNS resolver, which is a low-bandwidth exfiltration and
52	#   retrieval side channel. Leg 3 proves one internet host is unroutable; it
53	#   proves nothing about the docker host itself or sibling containers.
```

The disclosure is correct, is in the right place (the file an operator reads before spending),
and states leg 3's scope limit honestly. **Disclosure is the right call here** and I would not
block on it: closing the channel is not free, and this pass makes that visible —

```
116	PROXY_URL="http://$PROXY_NAME:3128"
```

the proxy is addressed **by name**, so every cell requires the embedded resolver to function at
all. The prior review's suggested fix (`--dns 127.0.0.1` plus a pinned proxy IP) is therefore a
two-part change to `setup_egress` and `in_cell_net`, not a flag, and it would have to be
executed against docker to be trusted — which this environment cannot do. Carrying it as a
named, disclosed residual into a pilot sweep is defensible; carrying it silently into a full
50-cell `--all` run is not.

What remains materially undisclosed at the point of spend is thinner but non-empty: the
`voided_cells` semantics (correctly caveated inside `run-meta.json` at `:379-385`, not in the
runner header), and the fact that a *passing* preflight does not distinguish "the filter works"
from "the proxy refuses everyone" (finding 1).

**Recommendation:** Keep the disclosure. Before an `--all` sweep, close it: `docker network
connect --ip` the proxy, set `PROXY_URL` to that literal address, and run cells with a resolver
that cannot answer. Add the `voided_cells_meaning` sentence to the runner header so the caveat
is where the spend decision is.

#### The `internal-net` leg is a substring test over an operator-influenced string, not an observation of the network

**Severity:** Low
**Location:** `scripts/crb-egress-verdict.sh:79-89`; `runs/review-arms/crb-pipeline/run-host.sh:176-178`, `:114`
**Boundary:** B5, B4
**Move:** #11 enumerate bypasses
**Confidence:** High (executed)
**Legibility-target:** for-author

```
176	  NET_CREATE_CMD="docker network create --internal --subnet $EGRESS_SUBNET $EGRESS_NET"
177	  $NET_CREATE_CMD >/dev/null
```

Executed: the leg passes on a command line where `--internal` appears only inside another token.

```
$ bash scripts/crb-egress-verdict.sh internal-net \
    "docker network create --subnet 10.0.0.0/24--internal-x crb"
ok  network created --internal        # exit 0
```

`EGRESS_SUBNET` is an invited override (`:114`, `${EGRESS_SUBNET:-172.31.250.0/24}`), so an
operator value containing that substring makes the leg vacuous. Two smaller notes on the same
two lines: `$NET_CREATE_CMD` is expanded **unquoted**, so `EGRESS_SUBNET` is a word-splitting
and globbing injection point into `docker network create`'s argv (operator-trusted, hence Low);
and the leg asserts the command's *text*, never the created network's *state*. Decision 034
concedes the second point in its own words ("whether docker honours `--internal` is itself only
observable at runtime") — but that is precisely what `docker network inspect -f '{{.Internal}}'`
observes, at $0, and it cannot be satisfied by a string.

I want to be clear about what the commit got right here: tying the assertion to the same
variable that is executed is a genuine improvement over asserting the author's intention, and
`test/crb-egress-verdict.bats:130-141` pins that wiring three ways. The remaining gap is the
last hop.

**Recommendation:** Replace the leg's observation with `docker network inspect -f
'{{.Internal}}' "$EGRESS_NET"` and have the verdict require the literal `true`; keep the
command-line case as a second leg if desired. Quote `"$NET_CREATE_CMD"` out of existence by
invoking docker directly and building the assertion string from the same array.

#### `ConnectPort 443` bounds CONNECT only; the new `plain-http` leg proves the host filter, not the port

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:17-33`; `runs/review-arms/crb-pipeline/run-host.sh:246-251`
**Boundary:** B4, B6
**Move:** #11 enumerate bypasses
**Confidence:** Medium
**Legibility-target:** for-author

```
28	# The allowlist. FilterURLs Off => the filter matches the HOST, which for a
29	# CONNECT request is the tunnel target. FilterDefaultDeny inverts the usual
30	# sense: entries are what is ALLOWED, everything else is refused.
```

The comment defect the prior pass raised is **fixed correctly** — `tinyproxy.conf:17-26` now
states plainly that `ConnectPort` scopes CONNECT alone and credits `Filter` with the plain-HTTP
refusal — and the new leg exercises the path rather than asserting it
(`run-host.sh:250-251`, `egress_leg plain-http … http://github.com/`). Bypass candidates I then
enumerated against the *remaining* surface, and their disposition:

1. `http://api.anthropic.com:9999/` through the proxy — **traced, live.** `FilterURLs Off`
   matches the host; `ConnectPort` never sees a non-CONNECT request; so tinyproxy would open a
   connection to an arbitrary TCP port on an allowlisted host. Bounded to Anthropic-controlled
   IPs, which is why this is Low rather than Medium.
2. `CONNECT api.anthropic.com:9999` — **traced, refused** by `ConnectPort 443`, which is the
   one thing that directive does do. Not pinned by exclusivity: `test/crb-egress-config.bats`
   asserts the line's presence, so adding `ConnectPort 80` survives the suite (rubric A7).
3. A non-GET forward-proxy verb (`POST`/`PUT` to `http://github.com/…`) — **listed, untested**;
   see Untested bypass candidates.
4. Case and trailing-dot host variants (`GitHub.COM`, `github.com.`) — **partly traced.**
   `FilterCaseSensitive Off` covers the first. The trailing dot is untested.

**Recommendation:** Add `ConnectPort`-exclusivity to the config test (assert exactly one
`ConnectPort` line and that it is `443`). If nothing in a cell needs plain HTTP, stop exporting
`HTTP_PROXY`/`http_proxy` (`run-host.sh:203-204`, `:266-267`) and delete the path rather than
testing it — the `plain-http` leg then becomes a regression pin on an env that should not exist.

#### The autoupdater and telemetry are left enabled behind the allowlist

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.review:10-18`
**Boundary:** B4, B6
**Move:** #5 invert the access-control model, #10 review dependency changes
**Confidence:** High
**Legibility-target:** for-author

```
10	# It will still ATTEMPT others — this repo's own devcontainer-config/egress/base.txt
11	# lists claude.ai, console.anthropic.com, sentry.io, statsig.com and
12	# registry.npmjs.org, and nothing here disables the autoupdater or telemetry. The
13	# allowlist refuses them. "Needs one" is the claim; "contacts one" is not, and an
14	# earlier version of this comment said the latter.
```

The documentation fix is right and the distinction it draws (needs vs. attempts) is the correct
one. The disposition question is whether "the allowlist refuses them" is enough. **My
assessment: acceptable to ship, but it should be disabled anyway**, for two reasons that are
about control count rather than current exposure. First, the allowlist is the *only* thing
between a running cell and `registry.npmjs.org`; if it holds, the autoupdater is a no-op, and
if it is ever widened by one line the autoupdater can replace the CLI binary the image pins —
which is simultaneously a code-execution path into the cell and a silent break of the version
pinning that makes this arm comparable to E5/E7. Defense in depth costs one `ENV` line here.
Second, a cell that spends its first turns retrying blocked update and telemetry endpoints adds
noise to a transcript that is the arm's primary artifact.

There is no reachable mechanism today — `registry.npmjs.org` is not in `egress-allowlist`, and
I read that file — which is why this is Low and not Medium.

**Recommendation:** Add `ENV DISABLE_AUTOUPDATER=1 DISABLE_TELEMETRY=1
DISABLE_ERROR_REPORTING=1` to `Dockerfile.review` and note in the comment that the allowlist is
now the *second* control on those endpoints, not the first.

#### `--verify` hash-pins the baseline tar but not the index before running host `git` on the extract

**Severity:** Informational
**Location:** `scripts/crb-materialize.py:583-597` vs. `:386-400` (`restore_clone`)
**Boundary:** B1
**Move:** #1 trust boundaries
**Confidence:** High
**Legibility-target:** for-author

`restore_clone` now checks **both** halves of the baseline contract — tar sha256 and index
sha256 — before the paid cell, which is the R3 fix and it is correct. The `--verify` branch was
not brought along: it checks `baseline_sha256`, extracts, and runs `verify_containment` on the
extract, never touching `baseline_index_sha256`. Nothing unsafe follows from that today (the
tar is what it inspects, and the tar is pinned), but `--verify` is the mode an operator runs to
answer "is this baseline still the one the manifest describes", and it currently answers that
for half the contract. The asymmetry is the same shape as the defect R3 named.

**Recommendation:** Have `--verify` assert `baseline_index_sha256` too, and say so in its
output line.

## Endorsement Claims

- **Claim:** No code path in `scripts/crb-materialize.py` reaches `scrub_object_store` or
  `verify_containment` against a directory the script did not itself create in the same
  invocation.
  **Location:** `scripts/crb-materialize.py:224-247`, `:192-221`, `:462-464`, `:583-597`
  **Evidence:** executed (`grep -n "scrub_object_store\|verify_containment"` over the file; all
  five call sites read)
  **Verified:** `scrub_object_store` has exactly one caller, `materialize():462`, on the tree
  cloned a few lines above at `:440-460`. `verify_containment` has two: `materialize():464` on
  that same fresh tree, and the `--verify` branch at `:596`, which runs on a
  `tempfile.TemporaryDirectory` extract of a tar whose sha256 was compared to the manifest at
  `:588-593`. The `--snapshot` CLI branch and its `elif` are deleted; `argparse` no longer
  defines the flag (`:504-521`); `restore_clone` runs `tar --extract` and no `git` at all.
  **Not verified:** whether `runs/review-arms/crb/instances.json`, the source of the pinned
  hashes, is itself unreachable from a review container — I read the runner's `-v` mounts
  (`$clone` only) but did not enumerate every container invocation in the repo.
  **route: code-fact-check**

- **Claim:** Both runner remediation messages now name `--slug <id> --force`, and that mode
  deletes and re-clones rather than repairing in place.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:449-454`, `:515-519`;
  `scripts/crb-materialize.py:414-421`
  **Evidence:** read-static
  **Verified:** both messages print `python3 scripts/crb-materialize.py --slug $id --force`; the
  first adds "there is deliberately no mode that baselines an existing clone in place".
  `materialize()` under `force` reaches `shutil.rmtree(dst)` before `git clone`, so the tree the
  scrub later runs on is one this invocation created. `crb-harvest-artifacts.py:99-103` and
  `restore_clone`'s three error strings were updated to the same remedy; a repo-wide grep for
  `--snapshot` returns only historical prose in `docs/decisions/034` and
  `crb-materialize.py`'s explanatory comments.
  **Not verified:** an actual `--slug … --force` run (needs network access to the forks).
  **route: code-fact-check**

- **Claim:** `egress_leg` fails closed on every mechanical failure of the verdict script I could
  construct, and prints the verdict's output on the legs it fails.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:220-236`
  **Evidence:** executed (the function body copied verbatim into a harness under the same
  `set -euo pipefail`; five cases)
  **Verified:** missing file → 127 → `exit 5`; `chmod 000` file → 126 → `exit 5`; a directory
  path → `exit 5`; a leg that both prints and exits 1 → the FAIL text is printed *and*
  `exit 5`; usage error (exit 2) → `exit 5`. The `|| rc=$?` form does not lose a status the way
  the pipeline form it replaced did.
  **Not verified:** the one fail-*open* path is inside the verdict script rather than in
  `egress_leg` — see finding 1; and I did not exercise `egress_leg` with `$VERDICT` unset (it is
  set unconditionally at `:216` under `set -u`).

- **Claim:** The audit's three exit states are no longer collapsed: only exit 1 writes
  `CONTAINMENT_FAILED`, and exit >1 (including docker's 125/126/127) aborts the sweep.
  **Location:** `runs/review-arms/crb-pipeline/run-host.sh:632-656`; `scripts/crb-audit-clone.sh:31-38`
  **Evidence:** read-static, plus the audit suite executed (`bats test/crb-audit-clone.bats`,
  all cases pass within a 55/55 run of the four relevant suites)
  **Verified:** `audit_rc=0; docker run … || audit_rc=$?` then `-gt 1 → exit 4` before
  `-eq 1 → void`; the bare `if ! docker run` form is gone and
  `test/crb-egress-config.bats` pins its absence with a comment-excluding regex.
  **Not verified:** that the review image actually produces 125/126/127 rather than some other
  status for the failure modes named — no docker here.
  **route: code-fact-check**

- **Claim:** The baseline index is now hash-pinned and checked before the paid cell, on the same
  footing as the tar.
  **Location:** `scripts/crb-materialize.py:311-336`, `:386-400`; `runs/review-arms/crb-pipeline/run-host.sh:448-454`
  **Evidence:** read-static, plus `bats test/crb-disposable-clone.bats` passing (includes
  "snapshot records a hash for the index as well as the tar")
  **Verified:** the index is written to a `.part` and `replace()`d (atomic publish),
  `baseline_index_sha256` is recorded in the manifest, and `restore_clone` raises on a missing
  index, a missing manifest hash, or a mismatch — all before `rmtree`. The runner obtains both
  paths from `--baseline-paths` rather than respelling the layout, and skips the cell if either
  is absent.
  **Not verified:** `--verify` does not check the index hash (see the Informational finding), so
  this claim covers the `--restore` path only.

Not endorsed, deliberately: **the egress preflight as a whole**. Move #11 leaves it with
untested bypass candidates (below), and finding 1 is a live fail-open in one of its legs, so
per this skill's rules it may not appear as an endorsement claim in any form.

## Untested bypass candidates

Enumerated against the guardrails this diff adds or modifies; not traced to a conclusion here,
and named so the gap is a recorded state rather than a silent one.

| # | Guardrail | Candidate | Why untested |
|---|---|---|---|
| U1 | tinyproxy `Filter` (B4) | Non-GET forward-proxy verbs — `POST`/`PUT`/`PATCH http://github.com/…` through the proxy | Requires a running tinyproxy; no docker in this environment. tinyproxy applies the filter per request regardless of method by design, but I did not read its source to confirm. |
| U2 | tinyproxy `Filter` (B4) | Trailing-dot and IDN/punycode host forms (`github.com.`, `xn--…`) against the anchored regex `^api\.anthropic\.com$` and the default-deny inversion | Same: needs the proxy running. The default-deny direction means an unmatched variant is *refused*, so the risk direction is availability, not bypass — but an allowlist entry that fails to match its own host would be caught only at runtime. |
| U3 | `--internal` network (B4/B9) | Reachability of the **docker host itself** and of sibling containers from a cell — the runner header now states leg 3 proves nothing about either | Needs docker. This is the gap decision 034 and `run-host.sh:52-54` both disclose; it is untested by design, not by omission, and is the strongest argument for running `PREFLIGHT_ONLY=1` plus a manual host-reachability probe before the first paid sweep. |
| U4 | egress preflight ordering (B5) | A proxy that is up and filtering correctly at preflight time and mis-configured (or restarted with a different image) mid-sweep | The per-cell `in_cell_net` liveness probe (`:525-529`) tests *reachability*, not *filtering* — a proxy that came back with an empty filter passes it. Testing needs docker. |
| U5 | `crb-audit-clone.sh` (B2) | Non-git retrieval: `curl`/WebFetch of the merged PR into a plain file, or an answer key held only in the agent's context and never written to disk | Not testable at all by this control — the audit is git-shaped evidence. `run-meta.json:379-385` states this limit correctly. Recorded because it is the largest residual on the arm's contamination story and it is *not* closed by anything in this diff. |
| U6 | `--baseline-paths` (B8) | A slug containing `..`, a newline, or shell-significant characters, reaching `mapfile` and then `-f` tests and harvest argv | Slugs come from operator argv or the manifest; the charset gap is already rubric C9 and the new mode widens the surface by one consumer. `mapfile -t` plus `${_bl[0]:-/nonexistent}` fails closed on an empty result (read), but I did not execute a newline-bearing slug end to end. |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| 1 | `api-reachable` passes on any observation but `000`, including empty | Medium | B5 | `scripts/crb-egress-verdict.sh:50-54` | High |
| 2 | `rm -f CONTAINMENT_FAILED` erases a prior void with no re-decision | Medium | B10 | `run-host.sh:506`, `:515-519`, `:690-699` | High |
| 3 | A void still does not stop the sweep — only the exit code changed | Medium | B2 | `run-host.sh:643-657` | High |
| 4 | DNS side channel disclosed but unclosed; hostname `PROXY_URL` raises the cost | Medium | B9 | `run-host.sh:49-54`, `:116` | Medium |
| 5 | `internal-net` leg is a substring test over an operator-influenced string | Low | B5 | `crb-egress-verdict.sh:79-89`, `run-host.sh:176-177` | High |
| 6 | Plain-HTTP to an allowlisted host on an arbitrary port is unbounded | Low | B4 | `tinyproxy.conf:17-33` | Medium |
| 7 | Autoupdater and telemetry left enabled behind the allowlist | Low | B4 | `Dockerfile.review:10-18` | High |
| 8 | `--verify` pins the tar but not the index | Informational | B1 | `crb-materialize.py:583-597` | High |

## Disposition of the prior pass's findings

| Prior | Claim | Verdict this pass |
|---|---|---|
| 1 (High) `--snapshot` reopens R1 | mode DELETED | **Closed.** Enumeration executed; no remaining route to host `git` on a directory the script did not create. Both remediation messages now point at `--slug <id> --force`, which re-clones. B3 is removed from the map. |
| 6 (Medium) `--snapshot` rewrites `baseline_sha256` | route gone | **Closed.** `snapshot_baseline` has one caller, `materialize()`, on a freshly cloned tree; no mode rewrites a manifest hash from a used clone. |
| 2 (Medium) a void keeps spending; sweep exits 0 | `exit 6` added | **Partially closed.** The exit code is fixed; the spending is not (finding 3), and the new `rm -f` opens a way for the exit code to be wrong in the other direction (finding 2). |
| 3 (Medium) `ConnectPort` comment + plain-HTTP gap | comment corrected, leg 2b added | **Closed for the named gap.** The comment is right and the non-CONNECT host filter is now exercised. Residual: port scoping on allowlisted hosts, and non-GET verbs (finding 6, U1). |
| 4/5 (Medium) DNS + leg-3 scope undisclosed | disclosed in the runner header | **Disclosure accepted** as the right call (finding 4). One item still absent from the point of spend: the `voided_cells` "not proof of cleanliness" caveat. |
| 8 (Low) `DISABLE_AUTOUPDATER` | deliberately not set, documented | **Acceptable, but do it anyway** (finding 7) — one `ENV` line buys a second control on the one endpoint class that can replace the pinned binary. |

## Overall Assessment

The High finding is genuinely closed, and closed the right way — by deleting the mode rather
than documenting its precondition, which is the first time in this loop's history that a
mechanism error was answered by removing the mechanism. The extraction of
`scripts/crb-egress-verdict.sh` is the correct structural move and it is now the most
consequential 94 lines in the arm: every dollar is gated on its exit status. That is also where
the remaining risk concentrated. The single most important thing to address is **finding 1** —
`api-reachable` treats any string that is not literally `000` as proof of a working tunnel, so
the leg that the other refusal legs are documented to depend on can print `ok` having observed
nothing, and a plausible `EGRESS_SUBNET` misconfiguration makes the entire five-leg preflight
green while tinyproxy refuses every request for a reason unrelated to the allowlist. It is a
three-line fix in the same `case` block and it should land before `PREFLIGHT_ONLY=1` is used to
authorize spend, because it is precisely the "control that passes for the wrong reason" the
file's own header says this harness has gone wrong on before. Findings 2 and 3 are the void
protocol still not being a protocol: it now has a delete, a marker, a JSON field and an exit
code, and no two of them agree about what a void means over time; both are small, local edits
against `attempts.jsonl`, which already exists. Nothing here is architectural.

Verdict: **no findings within the code paths read that reach the answer key or the API key;
endorsement claims pending execution verification.** Four of the five endorsement claims are
`read-static` with their nearest unread hop named, and the egress preflight — the control the
sweep's honesty rests on — is deliberately not endorsed, because move #11 left it with six
untested bypass candidates and one executed fail-open. This is not a "safe to merge" verdict
and should not be read as one; it is "the escalated design question was answered correctly, and
the seams around it have moved but not closed."

## Goal-Alignment Note
- Answered: yes — terminal security pass delivered against the two fix commits.
- Out of scope: `197eec6` itself (context only); the performance, api-consistency, architecture, test-strategy and tech-debt findings in the r2 rubric; anything requiring docker execution (stated as environmental, not a defect).
- Escalate: finding 1 (`api-reachable` fail-open) should be fixed before `PREFLIGHT_ONLY=1` is used to authorize the paid sweep — it is a three-line change and it invalidates the arm's central pre-spend assurance; findings 2 and 3 should be decided by the human, since "halt on first void" is a policy call about a $10–40-per-cell sweep, not a code defect. U3 and U5 are residuals no code change in this diff closes and belong in whatever results doc the sweep produces.
