Commit: 61d801c

# Architecture Review — feat/q076-git-exit-scan (Q-076: exit scan + cc-push)

**Scope:** `git diff main...feat/q076-git-exit-scan` at 61d801c. In scope: `devcontainer-config/cc-isolated.sh` (exit-scan block), `devcontainer-config/cc-push.sh` (new module), `devcontainer-config/install.sh` (PAYLOAD / link), `hooks/live-verify-gate.sh` (enforcement regex), `guides/cc-isolated-usage.md` (tripwire contract). Tests read for the invariants they pin, but not reviewed as production code.
**Date:** 2026-09-27
**Based on:** `docs/reviews/q076-code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` (all at 61d801c). I did not re-verify behaviour those reports documented.
**Method:** I read everything at 61d801c in a scratch clone (`scratchpad/q076rev-arch/repo`). I read in full `cc-push.sh`, the whole scan block `cc-isolated.sh:550-1300`, `main`'s scan call sites (`:1384-1400`, `:1455-1472`), `enforcement_files` / `compute_manifest` / `check_manifest` (`:100-210`), and the two sync tests (`test/cc-isolated-functions.bats:823-845`, `test/hooks/live-verify-gate.bats:110-133`). I ran no probes: every executed result cited below comes from the fact-check reports.

**Trigger categories:** module structure (new shipped module `cc-push.sh`; an ~800-line subsystem added to `cc-isolated.sh`), public API (new CLI `cc-push` and its exit codes 0/1/2; new launcher exit codes 3/4), cross-cutting (the trust manifest `enforcement_files`, the install PAYLOAD, and the live-verify commit gate). The review proceeds.

**Trust-boundary cross-reference:** the activation condition is technically met, because `docs/reviews/security-review-2026-09-27.md` exists. Its Trust Boundary Map (Commit: `795ff71`) covers the Q-077 auto-approve hook (B1–B4), and none of its boundaries coincide with any module in this diff. That security review predates this diff and covers other code, so no labels are cited. Findings 2 and 3 do touch trust boundaries (container-written `.git` → host git; blessed config → launch). Their `Security implication:` notes are for the human to weigh in a combined review. They are not security findings.

## Dependency Map

```
install.sh ──PAYLOAD──► $DEST/{cc-isolated.sh, cc-push.sh, …}  ──ln──► $BIN_DIR/{cc-isolated, cc-push}
                                   │
cc-isolated.sh
  ├─ launcher/boundary (config_dir, enforcement_files ⊇ {cc-isolated.sh, cc-push.sh},
  │   compute/check_manifest, resolve_workspace [runs git rev-parse], probe_boundary, main)
  └─ exit scan (:550-1295): logical_workspace*, scan_git_dirs, _snap_* (20 helpers sharing
      git_exec_snapshot's locals), git_exec_snapshot, scan_vis, scan_diff, git_exit_scan,
      scan_interrupted   (*logical_workspace sits at :231 among the launcher helpers; its only caller is the scan)
        └─ names cc-push only in message text ("cc-push $ws") — no code dependency
cc-push.sh (standalone; sources nothing): find_checkout, check_checkout, ngit/hgit, vis, main
hooks/live-verify-gate.sh: hand-written regex ⊇ enforcement_files   (pinned: live-verify-gate.bats:110)
test: PAYLOAD ⊆ enforcement_files                                   (pinned: cc-isolated-functions.bats:823)
```

Dependencies run in the right direction. The guarantee component (cc-push) does not depend on the tripwire (the scan). The scan depends on cc-push only as a name in its advice text. install.sh and the gate depend on `enforcement_files` through lists that tests pin together. No cycles. The pressure points are responsibility placement (Finding 1), a primitive both modules need and neither owns (Finding 2), and how the trust pipeline classifies host-only tools (Finding 3).

## Findings

#### 1. The exit scan is a second subsystem living inside the launcher, and the stated reason for keeping it inline is weaker than the cost

**Severity:** Coupling
**Location:** `devcontainer-config/cc-isolated.sh:641-643` (SIZE rationale); block `:550-1295`
**Move:** 2 (responsibility boundaries), 3 (module boundary)
**Confidence:** High
**Legibility-target:** the `SIZE.` comment and anyone deciding where the next scan fix goes

Evidence:
```
# SIZE. This block brings cc-isolated.sh to about 1480 lines. It stays inline because
# install.sh ships a fixed PAYLOAD list and the trust manifest hashes each file;
# a sourced helper would need both to change.
```
`cc-isolated.sh` is 1477 lines, and 799 of them are new. The launcher's job is the container boundary: bless, manifest, build, probe, exec. The scan answers a different question: which host-git exec surfaces changed. It changes when git grows new exec surfaces, or when fact-check rounds find new routes. That has already happened four times on this branch (37cae85, d9a895d, f35381f, 61d801c). The boundary code changes for other reasons. Each scan fix now edits the file that holds `check_manifest`. That drags in the live-verify gate (Finding 3) and a 2059-line test file shared with the launcher.

The rationale's premise has been tested, by this same diff. Adding `cc-push.sh` as a shipped file took one PAYLOAD token (`install.sh:110`), one `echo` in `enforcement_files` (`cc-isolated.sh:116`) and one regex alternative (`live-verify-gate.sh:73`). Two tests pin those three edits and go red if one is forgotten (`cc-isolated-functions.bats:823`, `live-verify-gate.bats:110`). A sourced scan file needs the same three edits and no `chmod` or `ln`. The seam is already clean. The scan's public surface is `git_exec_snapshot`, `git_exit_scan`, `scan_interrupted`, `scan_vis`, `logical_workspace` and `GIT_EXIT_SCAN_KEYS_RE`. `main` touches nothing else. Everything behind it is `_snap_*`-prefixed and private by convention.

**Recommendation:** extract `:550-1295` plus `logical_workspace` into `devcontainer-config/cc-exit-scan.sh`. Add it to PAYLOAD, `enforcement_files` and the gate regex. Source it with `source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/cc-exit-scan.sh"`: the bin entry is a symlink, and `config_dir` is wrong under tests. Split the scan's ~900 lines of bats into their own file. Replace the SIZE comment with a pointer to the new file. Do this before the next scan fix rather than as part of one: it is a mechanical move, and reviewing it alone keeps it cheap. Settle Finding 3 first or together, so the new file lands in the right trust category.

#### 2. "Which git dir will host git actually use" has no owner: five partial reimplementations, and both modules fail on the same git behaviour

**Severity:** Coupling
**Location:** `devcontainer-config/cc-push.sh:109-117` (`find_checkout`), `:122-159` (`check_checkout`); `devcontainer-config/cc-isolated.sh:648-673` (`scan_git_dirs`), `:1032-1046` (`_snap_dotgit_target`), `:1051-1063` (`_snap_nested`), `:1174-1182` (`.git`-named embedded search); `:211-224` (`resolve_workspace`)
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High (shared root cause executed in r1 Claims 1 and 9); Medium (the recommended shape)
**Legibility-target:** whoever fixes r1 Claim 1 / Claim 9, so the fix lands once

Both modules keep one invariant: they run no git in the checkout. Both therefore have to re-derive git's repository-discovery rules from file reads. Neither owns that derivation, and each module carries its own partial version:

- `cc-push.find_checkout`: the nearest directory holding any `.git` entry. It does not check that the entry is valid.
- `cc-push.check_checkout`: requires `$co/.git` to be a real directory with no commondir, alternates, links or includes. It never checks that git will *accept* it as a git dir.
- `cc-isolated.scan_git_dirs` and `_snap_dotgit_target`: the same `gitdir:`-line parsing twice in one file, with different base-path resolution (`$ws/` vs `${p%/*}/`).
- `_snap_nested`: its own heuristic (`HEAD` next to `objects/`, or `commondir`).
- The embedded search finds git dirs only by the name `.git` (`-name .git`, `:1182`).
- `resolve_workspace`: real git discovery (`git rev-parse --show-toplevel`), so the launcher holds a sixth answer that may disagree with the scan's.

The fact-check reports show the cost. When `.git` is made invalid, git falls back to the checkout root. Evidence in r1: Claim 1 (cc-push pushed another repo's private commit, executed) and Claim 9 (the scan returned 0 while a planted hook ran, executed). r3 Claim 10(a) adds a bare-layout git dir inside the working tree that is not named `.git`. All three are one gap: nothing implements git's own validity test (setup.c `is_git_directory`: a valid `HEAD`, an `objects/` dir, a `refs/` dir, with `commondir` taken into account). Left as is, each fix lands twice and drifts. r1's suggested cc-push fix (run `git rev-parse --git-dir` in the checkout) would break the "no git in the checkout" invariant both modules document.

**Recommendation:** define one file-read predicate, `gitdir_valid <dir>`, that mirrors `is_git_directory`. Use it for:
- (a) cc-push: refuse unless `$co/.git` passes, which removes the root fallback because git's first candidate is then valid;
- (b) the scan: record the validity of the resolved `.git` as an `F` record, so invalidation becomes a finding, and fail closed when it is invalid at exit;
- (c) the scan's tree walk: find git dirs by `HEAD` plus validity instead of by the name `.git`, which covers r3 10(a).

Share it in one of two ways. The first is a tiny `cc-gitdir.sh` that both source. cc-push is currently self-contained, so this adds a load-path dependency and another PAYLOAD/manifest/gate entry. The second is to duplicate the ~15 lines in both files, with a bats parity test that runs both copies against one fixture set. The parity test is the cheaper default. Prefer the shared file if Finding 1's extraction happens, because the scan file would then be the natural home. Pointing cc-push's fetch at `"$co/.git"` does not replace this: git also tries suffixed candidates such as `<path>.git`. That is [assumed] from memory of `enter_repo` and not verified here.
**Security implication:** this moves where the "container-written `.git` → host git / upload-pack" crossing is validated, from name-based checks to a validity check. Security review should confirm the predicate matches git 2.39's discovery exactly.

#### 3. The trust pipeline treats host-only tools as container-boundary files, so they inherit a live-verification rule no live probe can meet

**Severity:** Coupling
**Location:** `devcontainer-config/cc-isolated.sh:108-116` (`enforcement_files`), `:189-205` (`check_manifest`); `hooks/live-verify-gate.sh:70-73`; `test/cc-isolated-functions.bats:823-837`
**Move:** 7 (coupling), 4 (layer: host tooling vs container boundary)
**Confidence:** Medium
**Legibility-target:** the `enforcement_files` header comment and decision log row 45

Evidence:
```
  echo "cc-isolated.sh"
  echo "cc-push.sh"
```
and the commit trailer on c3d9223: `Live-verified: no — … cc-push touches no container, but cc-push.sh is now an enforcement file`.

cc-push became an "enforcement file" because the PAYLOAD ⊆ `enforcement_files` test requires every shipped file to be hashed. That test's rationale is that an installed file nobody hashed is a boundary artefact nobody blessed, which treats *shipped* and *boundary* as the same thing. Decision log row 45 defines the gate's trailer as a receipt of the live boundary probe, and says `git log --grep 'Live-verified: no'` is the debt list. `probe_boundary` can never exercise cc-push or the exit scan, since both run on the host after or outside the container. So all 7 commits on this branch carry `Live-verified: no`, and so will every future edit to either. Those entries are not debt anyone can pay down, and they dilute the list. Enforcement is also on the wrong entry point: `check_manifest` runs only in `cc-isolated`'s `main`. A modified `cc-push.sh` therefore blocks every *launch* until re-bless, while `cc-push` itself runs without checking anything.

**Recommendation:** split the category. Keep a `host_tool_files` list (cc-push, and the extracted scan from Finding 1), hashed if you want tamper evidence. Gate its commits with a distinct trailer (e.g. `Host-verified:`) or exempt it from `Live-verified`. Widen the sync test to PAYLOAD ⊆ enforcement ∪ host_tools, both lists pinned. Record the choice in `docs/decisions/log.md`: it amends row 45's scope. If cc-push's own integrity matters, check it where cc-push runs, not in the launcher.
**Security implication:** this changes what the bless covers, which is the blessed config → launch boundary. Moving cc-push out narrows the manifest. Decide together with the security review whether a host tool's integrity belongs in the container-config manifest at all.

#### 4. LIMITS is kept in two hand-maintained copies that have already drifted

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:619-639`; `guides/cc-isolated-usage.md:~258-297` ("Known routes it does not see")
**Move:** 2 (responsibility for the tripwire contract)
**Confidence:** High
**Legibility-target:** the scan's contract, meaning what a clean exit does *not* mean

The code comment says `LIMITS (also in guides/cc-isolated-usage.md)`, but the two copies differ:
- The guide has a "Host programs pointed at the checkout" bullet that the code lacks.
- The code's tool list has `dirname` and `rm`, which the guide's lacks (r3 Claim 8).
- Neither copy has the `.git`-invalidation route (r1 Claim 10) or the non-`.git` bare git dir (r3 Claim 10(a)).

The tripwire-vs-guarantee boundary is the scan's whole contract. Two sources for it means the next fact-check round has to update both.

**Recommendation:** make the guide the single source. Cut the code comment to the three or four routes a maintainer must keep in mind while editing, plus a pointer to the guide, or add a drift test like `test/sandbox-tool-map-drift.bats`. Add the r1 and r3 routes to the guide either way, unless Finding 2 closes them first.

#### 5. `_snap_*` helpers talk through bash dynamic scoping of ~10 caller locals

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:675-680` (the convention), `:1153-1157` (the locals)
**Move:** 7 (content coupling)
**Confidence:** High
**Legibility-target:** maintainers of the scan helpers

```
# The _snap_* helpers below run inside git_exec_snapshot and share its locals
# (bash dynamic scoping): _snap (the records), _snap_seen (walked dirs), _snap_ws, …
```
No helper can be called or tested on its own, and a helper that forgets a `local` silently writes the caller's state. The comment documents this honestly and it is contained behind one entry point, so it is acceptable for bash at this size. It does mean the helpers move as one unit, which Finding 1's extraction respects. It also means Finding 2's predicate should be a pure function that reads no `_snap_*` state.

**Recommendation:** keep the pattern, but write any new shared primitive (Finding 2) as a pure function. If the scan keeps growing, pass `_snap_seen` / `_snap_tmp` explicitly to the recursive walkers first.

#### 6. The tripwire/guarantee split is expressed consistently. The guarantee half is the one r1 broke

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:1236-1239`, `:1467-1471`; `cc-push.sh:45-54`; guide `:57-59`, `:232-234`
**Move:** 2
**Confidence:** High
**Legibility-target:** the user deciding what to rely on

On the tripwire side, the code and the guide agree. `git_exit_scan` documents "0 is not 'safe'", a clean scan passes claude's own status through (`0) exit "$rc"`), and every non-zero path and both guide sections send the user to cc-push. Structurally, the scan's value is the undo list and the alert about other host programs. The push decision is the same at 0, 3 and 4: use cc-push. The guarantee lives in cc-push, whose header states a refusal-set guarantee (`Otherwise upload-pack could fetch history from another repository … Run cc-push on the main checkout`). That is the claim r1 Claim 1 falsified, and r3 Claim 3b qualifies it: it holds only while nothing writes `.git`, and the cc-push section never says to `docker stop` first.

**Recommendation:** after Finding 2, restate cc-push's guarantee with both of its preconditions: (1) a valid `.git`, as `gitdir_valid` defines it; (2) the container stopped, or nothing writing to the checkout. This keeps the guarantee component's contract as precise as the tripwire's. Keep cc-push free of any dependency on a clean scan.

## What Looks Good

- **The guarantee does not depend on the tripwire.** cc-push sources nothing and never consults the scan, so a scan gap cannot weaken the push path. The scan names cc-push only in text.
- **The three hand-maintained lists are pinned in both directions.** The PAYLOAD ⊆ `enforcement_files` test, the `enforcement_files` ⊆ gate-regex test (which sources the real function), and the Dockerfile-COPY ⊆ PAYLOAD test together mean a missed edit goes red. The gate regex is hand-written but not unguarded (route: code-fact-check, r1 Claim 16 / r3 Claim 12).
- **The scan has a narrow, clean public surface** (six names used by `main`, with private `_snap_` helpers behind them). That is why Finding 1 is cheap to act on.
- **cc-push's I/O discipline is centralised:** `ngit`/`hgit` force hooks and fsmonitor off, `vis`/`say`/`die`/`run_vis` are the only output paths, and the exit-code clamp sits in one guard (`:299-307`). Future edits have one place to go.
- **Records, not key lists.** The snapshot hashes files and uses `GIT_EXIT_SCAN_KEYS_RE` only to label report lines, so git adding a new exec key does not force a scan change. That is the right extension point.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Exit scan inline in the launcher; the SIZE rationale is disproved by cc-push's own 3-edit, test-pinned onboarding | Coupling | `cc-isolated.sh:641-643`, `:550-1295` | High |
| 2 | No owner for "which git dir will git use"; 5–6 partial reimplementations; cc-push and the scan fail on the same discovery fallback | Coupling | `cc-push.sh:109-159`; `cc-isolated.sh:648-673,1032-1063,1182,211-224` | High / Medium (shape) |
| 3 | Host-only tools classified as boundary "enforcement files": permanent `Live-verified: no`, and integrity checked at the wrong entry point | Coupling | `cc-isolated.sh:108-116,189-205`; `live-verify-gate.sh:73` | Medium |
| 4 | LIMITS duplicated in code and guide, already drifted | Minor | `cc-isolated.sh:619-639`; guide "Known routes" | High |
| 5 | `_snap_*` share caller locals through dynamic scoping | Minor | `cc-isolated.sh:675-680,1153-1157` | High |
| 6 | Tripwire/guarantee split consistent; cc-push's guarantee needs its preconditions stated | Informational | `cc-push.sh:45-54`; `cc-isolated.sh:1236-1239` | High |

Rubric mapping: 1–3 🟡 Must Address; 4–6 🟢 Consider. No Structural (🔴) findings: dependency direction is correct and there are no cycles.

## Overall Assessment

The change keeps the system's structure sound where it matters most. The component that must be right (cc-push) stands alone, and the tripwire only advises. The shipping and trust lists stay mechanically in sync. The issues can be fixed in place and do not call for a restructure. The most important one is Finding 2. Both new components chose, correctly, to run no git in the checkout, which obliges them to reimplement git's discovery, and neither owns that reimplementation. The two executed bypasses in r1 are the same missing primitive seen from each side. Fix it as one shared predicate (or two parity-tested copies), not as two separate patches. To the brief's explicit question: yes, extract the scan into its own shipped file. The PAYLOAD/manifest argument for keeping it inline costs three test-pinned edits, as cc-push showed. Settle Finding 3 (which trust category host-only tools belong to) at the same time, so the extracted file does not inherit a live-verify requirement it can never meet.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to /workspace/docs/reviews/q076-architecture-review-2026-09-27.md, structured per the architecture-review skill, with a Goal-Alignment Note.
- **Answered:**
  - Scan extraction: yes, Finding 1, with the file name, public surface, sourcing mechanism and cost.
  - cc-push / scan duplication and whether to share a module: Finding 2. Share a validity predicate, not the walkers; a parity test is the cheaper default and a shared file is right if the scan is extracted. It is tied to r1's discovery-fallback finding.
  - Tripwire vs guarantee in code and guide: Findings 4 and 6.
  - Coupling to install.sh, the trust manifest and the gate regex: Finding 3, plus What Looks Good. The regex is test-pinned; the category is the problem.
  - Closed iteration-3 items were not re-reported.
- **Out of scope:** exploitability and severity of the bypasses (security critic and fact-check own those). Whether git 2.39's `enter_repo` tries `<path>.git` suffixes: [assumed], not run. Test-suite quality. I ran no probes; executed evidence is r1/r3's.
- **Escalate:**
  - Finding 3 amends decision log row 45's scope (what "enforcement file" and `Live-verified` mean). That is a user decision, not a mechanical fix.
  - Finding 2's predicate moves where a trust crossing is validated. It needs security sign-off that it matches git's discovery exactly.
  - No Q-076 security review with a Trust Boundary Map existed at review time, so the boundary cross-reference could not be done.
