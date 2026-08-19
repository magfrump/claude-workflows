# Code Fact-Check Report

**Scope:** commit `197eec6` (partial scope on `feat/crb-direction1-harness`)
**Commit:** 197eec6
**Replication:** k=3
**Date:** 2026-08-19
**Total claims checked:** 28 merged clusters (r1 26, r2 26, r3 34 raw claims)

Merged most-severe-wins from `code-fact-check-report-r{1,2,3}.md`. Severity order:
`Incorrect (high)` > `Incorrect (medium)` > `Incorrect (low)` > `Stale` > `Mostly Accurate` >
`Unverifiable` > `Verified`. Evidence and reasoning are carried from the replicate that
assigned the winning verdict. All three replicates executed the four new bats suites
(37 ok / 0 not ok); r3 additionally reproduced `materialize()`'s clone/fetch/prune sequence
from scratch, and r2 executed the `Dockerfile.proxy` build assertion against the copied files.
Docker is absent in the authoring environment, which is the named blocker on every
`Unverifiable` row.

---

## Claim 1: "Disk roughly doubles: pilot ~670 MB → ~1.3 GB, `--all` ~6.5 → ~13 GB."

**Location:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:63`
**Verdict:** Mostly Accurate
**Confidence:** High
**Evidence:** `clone_mb` in `runs/review-arms/crb/instances.json` sums to exactly 670 across
the five pilot clones. The doubling is the right model (a baseline tar is ~the clone's size),
but "doubles" is an approximation — a tar of a git clone is not byte-identical in size to the
directory it archives.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Verified · r3=Verified

## Claim 2: "R3 (nested clone) and A8 (a voided cell leaving a permanently dead clone) are closed structurally rather than by a flag or a message."

**Location:** `docs/decisions/034-...:65-66`
**Verdict:** Verified
**Confidence:** High
**Evidence:** `test/crb-disposable-clone.bats` "restore destroys a nested clone of the answer
key" passes; `run-host.sh` leaves the clone untouched after a void and the next cell's
`--restore` wipes it.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 3a: "`git status --untracked-files=all` honours `.gitignore`, so a rubric written to an ignored path used to vanish."

**Location:** `docs/decisions/034-...:67-68`; restated `scripts/crb-harvest-artifacts.py:11-14`,
`run-host.sh:475-477`
**Verdict:** Verified
**Confidence:** High
**Evidence:** `test/crb-harvest-artifacts.bats` "an artifact written to a gitignored path is
still harvested" runs a real negative control — `git status --porcelain
--untracked-files=all` is asserted NOT to list the file — then asserts the harvest finds it.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 3b: "The harvest became **strictly** more complete."

**Location:** `docs/decisions/034-...:67`
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** The new harvest skips symlinked artifacts, which the old loop deliberately
copied (`cp --no-dereference`), and imposes 5 MB / 50 MB / 500-file caps the old loop had
none of. It is more complete on the `.gitignore` axis and less complete on two others, so
"strictly" is refuted as a set relation. The gitignore half of the sentence (Claim 3a) stands.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Mostly Accurate · r3=Mostly Accurate

## Claim 3c: "Several benchmark repos ignore `docs/`-adjacent paths; the code-review skill writes its rubric under `docs/reviews/`."

**Location:** `scripts/crb-harvest-artifacts.py:13-14`
**Verdict:** Mostly Accurate
**Confidence:** Medium
**Evidence:** None of the five materialized clones ignores `docs/reviews/`; two of five ignore
other `docs/`-adjacent paths. The mechanism is real and the guard is worth having; the
prevalence claim overstates what the corpus shows.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Unverifiable · r2=Mostly Accurate · r3=—

## Claim 4: "`--reset` and `--heal` are gone; `--restore` and `--snapshot` replace them. R6 (no existing clone could pass the pre-run gate) dissolves with them."

**Location:** `docs/decisions/034-...:69-70`
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** The first sentence is Verified — both modes are gone. The R6 sentence is
refuted: `run-host.sh:366` requires `.baselines/$id.tar`, no baseline exists for any of the
five pilot clones, so every instance becomes `skipped_bad`, `ran=0`, and `run-host.sh:578-581`
exits 3. That is R6's exact symptom — the harness runs nothing against any clone that
currently exists — with the same shape of remedy, a one-shot operator command renamed
`--heal` → `--snapshot`. It fails safe at $0, but it did not dissolve.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Verified · r3=Incorrect

## Claim 5: "`scripts/crb-materialize.py --all           # all 50 (~6-7 GB)`"

**Location:** `docs/working/crb-direction1-setup.md:27`
**Verdict:** Stale
**Confidence:** High
**Evidence:** The same commit's `scripts/crb-materialize.py:38` and `docs/decisions/034:63`
both state ~13 GB once baselines are counted. The setup doc's stage-1 usage block was not
updated with the rest of the doc.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale

## Claim 6: "Assert both halves here so the image cannot be built in that state." (Dockerfile.proxy build-time filter assertion)

**Location:** `runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:15-23`
**Verdict:** Verified
**Confidence:** High
**Evidence:** r2 executed the three `grep` assertions against the copied `tinyproxy.conf` and
`egress-allowlist`; all pass, and each fails when its target line is removed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 7: "`FilterURLs Off` => the filter matches the HOST … `FilterDefaultDeny` inverts the usual sense: entries are what is ALLOWED."

**Location:** `docker/tinyproxy.conf:22-24`
**Verdict:** Verified
**Confidence:** Medium
**Evidence:** Matches tinyproxy's documented directive semantics. Confidence is Medium because
it is verified against documentation, not against a running proxy.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 8: "The proxy is reachable only from the internal `crb-inner` network, whose subnet run-host.sh pins so this line can be exact."

**Location:** `docker/tinyproxy.conf:12-16`
**Verdict:** Mostly Accurate
**Confidence:** High
**Evidence:** The subnet is pinned and `test/crb-egress-config.bats` cross-checks the `Allow`
line against `EGRESS_SUBNET`. "Reachable only from" overstates: the proxy is also attached to
the default bridge (that is how it reaches the internet), so it is reachable from other
containers on that bridge — the `Allow` line, not the topology, is what refuses them. The
comment two lines below says this correctly.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Verified · r3=—

## Claim 9a: "CONNECT to 443 only: … every other port [is] refused, so the tunnel cannot be repointed at an arbitrary service."

**Location:** `docker/tinyproxy.conf:18-20`
**Verdict:** Unverifiable
**Confidence:** Medium
**Evidence:** Correct per tinyproxy's documented `ConnectPort` semantics, but no test and no
preflight leg exercises a non-443 CONNECT, and docker is absent. Settleable at $0 by an
added preflight leg.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Verified · r3=Unverifiable

## Claim 9b: "plain-HTTP proxying … [is] refused" (credited to `ConnectPort 443`)

**Location:** `docker/tinyproxy.conf:18-19`
**Verdict:** Incorrect
**Confidence:** Medium
**Evidence:** `ConnectPort` scopes the CONNECT method only. A plain `GET http://…` through the
proxy is an ordinary forward-proxy request and is still served — constrained solely by
`Filter`/`FilterDefaultDeny`, not by `ConnectPort`. `HTTP_PROXY`/`http_proxy` are exported to
every cell, and preflight leg 2 tests `https://github.com/` only, so no leg exercises this
path. The containment conclusion still holds (the filter allows one host either way); the
stated mechanism is wrong. Two replicates converged independently.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Incorrect · r3=Incorrect

## Claim 10: "Baking the CLI means a running cell needs exactly ONE reachable host, `api.anthropic.com`."

**Location:** `docker/Dockerfile.review:6-8`; restated `run-host.sh:140-143`,
`docs/decisions/034:44-46`
**Verdict:** Mostly Accurate
**Confidence:** Medium
**Evidence:** This repo's own `devcontainer-config/egress/base.txt` lists five further hosts
Claude Code contacts, of which only `api.anthropic.com` is marked required; nothing in the
image or the runner disables the autoupdater or other non-essential traffic. The claim is
right about what a cell *needs* and wrong about what it *attempts*. Whether the extra
attempts are fatal is the one item genuinely gated on execution — and the egress preflight,
which runs a real headless invocation inside the restricted network, is the instrument that
settles it at $0.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Mostly Accurate

## Claim 11: "each leg is separate because they fail for different reasons — a single test passing for the wrong reason is how this harness has gone wrong before."

**Location:** `run-host.sh:193-196`; restated `docs/working/crb-direction1-setup.md`
**Verdict:** Mostly Accurate
**Confidence:** Medium
**Evidence:** Legs 1 and 3 are cleanly separate. Leg 2 accepts `403` **or** `000`, and `000`
is also what an unreachable proxy returns — so leg 2 isolates "the filter works" only given
leg 1 having passed. True in sequence, weaker than the comment's claim of independence.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate

## Claim 12: "Artifacts are harvested and the tree reset below, so re-runs start from the same state."

**Location:** `run-host.sh:423-425`
**Verdict:** Stale
**Confidence:** High
**Evidence:** Survives verbatim from the deleted `--reset` design. Nothing resets the tree
below; the restore runs *above*, at the top of the loop (`:413`), and `:510-512` states
correctly that the clone is left as the container wrote it. This is the
comment-credits-a-mechanism-that-does-not-exist class the prior loop produced three of.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale

## Claim 13: "Nothing below reads `.git`." (of the artifact harvest)

**Location:** `run-host.sh:477`; restated `scripts/crb-harvest-artifacts.py:10`
**Verdict:** Verified
**Confidence:** High
**Evidence:** `crb-harvest-artifacts.py` excludes `.git` at every depth and never invokes git;
`test/crb-egress-config.bats` "the runner never runs host git against the work clone" pins the
runner side.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 14: "run-host.sh invokes it as: `docker run --rm --network none -v "$clone":/repo -v .../crb-audit-clone.sh:/audit.sh:ro <image> bash /audit.sh /repo <head-sha>`"

**Location:** `scripts/crb-audit-clone.sh:10-13`
**Verdict:** Mostly Accurate
**Confidence:** High
**Evidence:** The real invocation adds `-u node` and `--entrypoint bash`. As written the
example would not run: the review image sets `ENTRYPOINT ["claude"]`, so `<image> bash
/audit.sh …` passes `bash` as an argument to `claude`. The documented flags that carry the
security claim (`--network none`, no key) are accurate.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=—

## Claim 15: "every stray is reported, and only contamination changes the exit code."

**Location:** `scripts/crb-audit-clone.sh:19-21`
**Verdict:** Mostly Accurate
**Confidence:** High
**Evidence:** Strays are counted, not individually reported; only the first foreign commit is
named (`n_foreign -gt 1` suppresses the rest). The exit-code half is accurate.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=— · r3=—

## Claim 16: "Exit: 0 = nothing detected · 1 = VOID (contamination) · 2 = could not check."

**Location:** `scripts/crb-audit-clone.sh:23`
**Verdict:** Mostly Accurate
**Confidence:** High
**Evidence:** Accurate for the three documented paths. A `git fsck` that errors is reported as
a VOID (exit 1) while being semantically "could not check" — the script says so in its own
trace text, but the exit-code legend does not.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=— · r3=—

## Claim 17: "Belt and braces on top of the container boundary — none of the commands below trigger hooks or a fsmonitor today … safe.directory is NOT optional."

**Location:** `scripts/crb-audit-clone.sh:34-42`
**Verdict:** Verified
**Confidence:** Medium
**Evidence:** `remote`, `fsck`, `rev-list`, `merge-base` run no hooks and do not refresh the
index; `safe.directory` is required for a host-owned clone. Medium confidence: verified by
reading git's documented behaviour, not by running the container.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 18: "Symlinks are never followed and never indexed … a symlinked directory is the one way an `os.walk` could leave the clone."

**Location:** `scripts/crb-materialize.py:268-272`, `scripts/crb-harvest-artifacts.py:22-25`, `:60`
**Verdict:** Verified
**Confidence:** High
**Evidence:** `followlinks=False` plus the per-entry `is_symlink()` filters; pinned by
`test/crb-harvest-artifacts.bats` "a symlinked artifact is not harvested and not followed",
which plants both a symlinked file and a symlinked directory pointing outside the clone.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 19: "So the host does not read a used `.git` at all."

**Location:** `scripts/crb-materialize.py:22-32`; restated `run-host.sh:49-54`, `:406-411`
**Verdict:** Mostly Accurate
**Confidence:** High
**Evidence:** Holds without exception for the automated cell path — restore, harvest and audit
are all git-free on the host. It does not hold for the `--snapshot` CLI mode, whose "only on a
pristine clone" precondition is documented rather than enforced. See Claim 20.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly Accurate

## Claim 20: "Runs on a clone this script just built from the fork, before any container has seen it, which is the only reason it is safe to run host `git` here."

**Location:** `scripts/crb-materialize.py:236-237` (`scrub_object_store` docstring)
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** There are two call sites. The second is the `--snapshot` CLI mode
(`crb-materialize.py:527`), which runs `git symbolic-ref -d`, `git reflog expire` and
`git gc --prune=now` against **any pre-existing clone directory** — and `run-host.sh:415-417`
actively instructs the operator to run `--snapshot <id>` on a leftover clone when a baseline
is missing. Nothing in the code checks the pristine precondition; the `--force` guard only
prevents overwriting an existing *baseline*. This is the same shape as the R1/R2 the commit
set out to close, on a path the runner routes operators into.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection (r3 reached
the same territory at lower severity under Claim 19)

## Claim 21: "materialize()'s own fetches write both, so unless they are cleared here EVERY baseline would carry them and EVERY cell would void — clearing them is what makes their later presence evidence."

**Location:** `scripts/crb-materialize.py:229-234`; restated `:413-415`
**Verdict:** Verified
**Confidence:** High
**Evidence:** r3 reproduced `materialize()`'s clone/fetch/ref-prune sequence from scratch:
before `scrub_object_store`, `.git/FETCH_HEAD` is present and `git fsck --no-reflogs` reports
one unreachable commit; after it, both are gone. The function is load-bearing exactly as the
docstring claims.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 22: "materialize() calls it immediately after verify_containment(); the CLI mode refuses to overwrite an existing baseline without --force."

**Location:** `scripts/crb-materialize.py:293-295` (`snapshot_baseline` docstring)
**Verdict:** Verified
**Confidence:** High
**Evidence:** `materialize()` calls `snapshot_baseline` after `verify_containment` returns;
the `--snapshot` branch raises unless `--force` when `<slug>.tar` exists.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 23: "Tests: 37 new across four suites (disposable-clone, audit-clone, harvest-artifacts, egress-config)"

**Location:** commit message `197eec6`
**Verdict:** Verified
**Confidence:** High
**Evidence:** Executed by all three replicates independently: `1..37`, 37 ok, 0 not ok, exit 0.
Suite names and per-suite counts match (9 + 10 + 9 + 9).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 24: "test/crb-containment-reset.bats removed with the code it pinned, its load-bearing void cases carried into crb-audit-clone."

**Location:** commit message `197eec6`
**Verdict:** Mostly Accurate
**Confidence:** High
**Evidence:** Five of the seven void cases map cleanly onto `test/crb-audit-clone.bats`. Three
did not carry over: the **`scrub_object_store` non-vacuity case** (`grep -rn scrub_object_store
test/` returns zero hits, while Claim 21 establishes the function is still load-bearing), the
tag-outside-ancestry variant of the descent case (mechanism covered by the branch variant), and
the shallow-clone false-positive control.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate

## Claim 25: "Built once by run-host.sh with normal network, before the restricted network is created. The CLI version is still pinned, so the arm is comparable to E5/E7."

**Location:** `docker/Dockerfile.review:10-12`
**Verdict:** Verified
**Confidence:** High
**Evidence:** The `docker build` calls precede `setup_egress`; `CC_VERSION` is passed as a
build arg and asserted non-empty in the Dockerfile.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified

## Claim 26: "EXACTLY ONE ENTRY IS INTENDED … test/crb-egress-config.bats pins the count, so adding a host is a deliberate, reviewed act."

**Location:** `docker/egress-allowlist:1-8`
**Verdict:** Verified
**Confidence:** High
**Evidence:** `test/crb-egress-config.bats` "the allowlist names exactly one host, anchored"
asserts both the count and the exact anchored pattern.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified

## Claim 27: "Clones are SHALLOW (--depth, default 50) … Measured on the 5-PR pilot: 33-195 MB each."

**Location:** `scripts/crb-materialize.py:18-20`
**Verdict:** Verified
**Confidence:** High
**Evidence:** `clone_mb` values in the manifest are 33, 125, 127, 190, 195.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified

## Claim 28: "E7 learned the exact failure string the hard way (exit 0, result 'Not logged in · Please run /login', num_turns=0)."

**Location:** `run-host.sh:252-255`
**Verdict:** Verified
**Confidence:** High
**Evidence:** `runs/review-arms/e7-fable-3x/run-host.sh:87-89` carries the cited artifact.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=—

---

## Claims Requiring Attention

**Incorrect (4):** 3b "strictly more complete" · 4 "R6 dissolves" · 9b `ConnectPort` credited
with refusing plain HTTP · 20 `scrub_object_store` "only reason it is safe".
**Stale (2):** 5 `--all ~6-7 GB` · 12 "the tree reset below".
**Mostly Accurate (9):** 1, 3c, 8, 10, 11, 14, 15, 16, 19, 24.
**Unverifiable (1):** 9a non-443 CONNECT (docker absent; settleable at $0).

Claim 20 is the only one with a code shape rather than a documentation shape, and Claim 4 is
the only one that gates operation of the sweep.

---

## Verdict stability

- **Total clusters:** 28
- **Clusters where all reporting replicates agreed:** 20
- **Clusters with disagreement:** 8 — Claim 1 (Mostly Accurate / Verified / Verified), 3b
  (Incorrect / Mostly Accurate / Mostly Accurate), 3c (Unverifiable / Mostly Accurate / —),
  4 (Mostly Accurate / Verified / **Incorrect**), 8 (Mostly Accurate / Verified / —), 9a
  (— / Verified / Unverifiable), 10 (Unverifiable / Unverifiable / Mostly Accurate), 19
  (Verified / Verified / Mostly Accurate).
- **Agreement rate:** 20/28 = **71%**.

Below the ≥90% threshold that would license dropping to k=2. Two of the eight disagreements
were decisive: Claim 4 was `Verified` by one replicate and `Incorrect` by another on a fact
that gates whether the harness runs at all, and Claim 20 was surfaced by a single replicate.
Both are cases where a single sample would have published a clean result.
