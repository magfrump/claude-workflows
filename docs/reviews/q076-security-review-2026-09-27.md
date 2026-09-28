Commit: 61d801c

# Security Review — Q-076 (branch feat/q076-git-exit-scan)

**Scope:** branch diff `main...feat/q076-git-exit-scan` @ 61d801c — `devcontainer-config/cc-push.sh` (new), `devcontainer-config/cc-isolated.sh` (exit scan), `devcontainer-config/install.sh`, `hooks/live-verify-gate.sh`, `guides/cc-isolated-usage.md`, `test/{cc-push,cc-isolated-functions,install-host}.bats`.
**Date:** 2026-09-27
**Based on:** `docs/reviews/q076-code-fact-check-report-{r1,r2,r3}.md` (r1 = adversarial/executed; r2 = static, adversarial probing stopped by a safety classifier; r3 = executed, found the check→fetch race). This review consumes their verdicts; it does not re-verify documented behavior. Two of my own probes (logs `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-sec/p1.log`, `p2.log`, git 2.39.5) independently reproduced r1's exfil with a simpler layout and validated the minimal fix.
**User goal:** Get a trustworthy design-level review of Q-076 before merging it into main (solo repo, local merge).

This is a *defensive* security tool whose threat model is a prompt-injected agent that fully controls the bind-mounted checkout including `.git`, trying to (a) get code executed on the host via host git / cc-push, or (b) exfiltrate another host repo's history via cc-push. The review evaluates whether the design holds against that adversary.

---

## Trust Boundary Map

```
B1 (new): container-written .git tree  → cc-push file tests (check_checkout) → host git upload-pack (reads objects/refs/config, as you, with your keys)
B2 (new): container-written .git tree  → cc-isolated exit scan (snapshot diff) → host operator's decision to run git in the checkout
B3 (new): container-written branch/commit/git-message text → vis / scan_vis byte filter → host terminal
B4:       host global/system git config → scan includes-evaluation & cc-push -c overrides → host git behavior
B5:       cc-push.sh file on disk       → install.sh PAYLOAD + trust manifest + live-verify-gate → next cc-isolated launch
```

**Input-source classification (per sink class):**

```
S1: $co/.git contents (config, HEAD, commondir, alternates, hooks, symlinks, refs, objects)
      — runtime-mutable by the adversary (owns the bind mount)
      — UNTRUSTED for exec sinks (host git run in checkout), fetch/read sinks (upload-pack object reach), and HTML/terminal sinks
S2: checkout path $co and branch names
      — runtime-mutable — UNTRUSTED for terminal sink (vis-filtered) and path-construction sink
S3: host ~/.gitconfig / system config
      — deploy-time (operator's own machine) — trusted for availability; the scan reads it read-only with --no-includes
S4: --remote URL (operator-supplied on host CLI, stored only in the clone)
      — deploy-time — trusted; never read from the checkout
S5: cc-push.sh / cc-isolated.sh on disk
      — deploy-time, integrity-gated by the manifest — trusted only while the gate holds (B5)
```

The whole change is one trust boundary restated three ways: **git's repository-discovery and config machinery treats the container-controlled `.git` tree (S1) as instructions, and both cc-push and the exit scan try to bound what that machinery will reach using host-side file tests rather than git's own discovery result.** The design is sound in shape (keep host git out of the checkout; fetch into a bare host-only clone; snapshot-diff the exec surface) but has a structural gap where the file tests and git's actual discovery disagree.

---

## Findings

#### cc-push exfiltrates another host repository by promoting the checkout root (or a nested path) to the git dir

**Severity:** High
**Location:** `devcontainer-config/cc-push.sh:122-159` (`check_checkout`), fetch at `:233-234`
**Boundary:** B1
**Move:** #2 (implicit sanitization assumption), #11 (enumerate bypasses)
**Confidence:** High (executed, git 2.39.5)

`check_checkout` inspects only paths under `$co/.git`, and the fetch is `git ... fetch ... "$co"` — a *directory* argument, not `$co/.git`. Git resolves a local fetch path via `enter_repo`, which, when `$co/.git` is not a usable git dir, falls back to treating `$co` itself (or a discoverable ancestor/nested layout) as the repository. The adversary owns `.git`, so it can invalidate it (e.g. remove `.git/HEAD`) and lay a bare-repo layout at the checkout root whose object reach points at another repo — none of it under `$co/.git`, so every `check_checkout` guard passes. upload-pack then serves the other repo's objects and cc-push previews and pushes them.

r1 demonstrated this with `objects/info/alternates` at the root; my probe P1 reproduced it with a strictly simpler layout — a `commondir` file at the root naming another repo's `.git`, plus a hand-written `HEAD`, no alternates at all — and cc-push exited 0 with `UPSTREAM: OTHER-PRIVATE` landing on the fake origin. This shows the finding is not specific to any one root file the guards happen to enumerate: **the guard set is an allow-by-omission denylist over `$co/.git`, while git's discovery operates over `$co`.** Any root layout git will discover defeats it. This directly falsifies the header guarantee (`cc-push.sh:53-54`) "Otherwise upload-pack could fetch history from another repository you can read and cc-push would offer it for push … AND SO IS REFUSED."

**Recommendation (minimal correct fix — validated by probe P2):** Do not try to enumerate root layouts. Instead (1) fetch from `"$co/.git"` explicitly rather than `"$co"`, and (2) pass `--upload-pack='git-upload-pack --strict'` on the fetch and the `ls-remote --symref`. `--strict` makes upload-pack refuse to serve a path that is not itself a proper git dir, so the enter_repo fallback cannot fire. In P2, `--strict` on `"$co/.git"` **refused** the root-commondir escape (layout B) and a `.git.git` sibling (layout D), while the normal checkout fetched fine. Note that fetching `"$co/.git"` **without** `--strict` was still defeated by a `.git/.git` gitfile (P2 layout C → served OTHER), so the path change alone is insufficient — `--strict` is load-bearing. Belt-and-suspenders: also refuse when `$co/.git` fails a plain `[ -d ]`/valid-gitdir file test (an invalid `.git` is itself the signal of an attack and should `die`, not silently fetch the root).

---

#### Exit scan returns a clean exit 0 when the checkout root is promoted to the git dir

**Severity:** High
**Location:** `devcontainer-config/cc-isolated.sh:648-660` (`scan_git_dirs`), embedded-repo search `:1224-1225`
**Boundary:** B2
**Move:** #2, #3 (error path — the fail-*open* variant)
**Confidence:** High (executed, git 2.39.5 — r1 probe p2)

The exit-scan counterpart of the finding above, and the more dangerous of the two because it converts a **clean exit 0 into a false-safe signal**. `scan_git_dirs` locates the git dir as `$ws/.git`, requiring it to be a directory with a readable config (`:648-660`). The adversary removes `$ws/.git/HEAD` (leaving `.git/config`, so the scan still resolves `.git`, finds no *exec-relevant* change — HEAD/refs/objects are not part of the recorded exec surface — and reports clean) and lays the checkout root out as a bare repo with a `pre-push` hook. Host git, finding `.git` invalid, ascends and treats the root as the git dir; the scan never examines the root as a git dir (its embedded-repo search is `find ... -mindepth 2 -name .git`, and the root git dir has no `.git` entry). r1's probe: `git_exit_scan` returned 0, `git rev-parse --git-dir` in the checkout returned `.`, and a host `git push` ran the planted hook.

This is worse than the cc-push finding because the exit scan is the tripwire the operator is told to trust when deciding whether the checkout is safe to touch with host git at all — and this route is **not** in the LIMITS comment (`:626-651`) or the guide's "Known routes it does not see" list. A `.git` that resolves but whose HEAD/refs were tampered is treated as benign.

**Recommendation:** Resolve the git dir the way git *will*, not the way the scan assumes. Run a hooks-off, fsmonitor-off `git rev-parse --git-dir` / `--show-toplevel` from inside the checkout (this runs no hook — it is repository discovery, not an operation on the tree) and treat any divergence from `<ws>/.git`, or an invalid/HEAD-less `<ws>/.git`, as a finding (exit 3), not a clean pass. Add HEAD to the recorded surface so root-HEAD removal is itself a tripwire.

---

#### check_checkout and the fetch are not atomic; a live container can plant in the window

**Severity:** Medium
**Location:** `devcontainer-config/cc-push.sh:188` (check) → `:233-234` (fetch)
**Boundary:** B1
**Move:** #4 (time-of-check to time-of-use)
**Confidence:** Medium (r3, static; TOCTOU by construction)

`check_checkout` runs once at `:188`; the fetch that actually invokes upload-pack is at `:233-234`, after `ngit init`, three `hgit config` calls, and the marker write. Nothing re-checks `.git`. The guide itself states that the container keeps running after `claude` exits and "a process the session left behind can plant after the scan; only a stopped container (`docker stop`) cannot" — but the cc-push section never tells the operator to stop the container before running cc-push. A background process in a still-running container can therefore add, after `:188`, exactly one of the items cc-push refuses (e.g. `objects/info/alternates`), and upload-pack reads it. This is a real window, though it requires the adversary to have left a running process and to win a short race.

**Recommendation:** Document and enforce "stop the container (`docker stop`) before running cc-push" in the cc-push section of the guide (not only in the exit-scan section). Optionally re-run `check_checkout` immediately before the fetch, or better, adopt the `--strict` upload-pack fix above, which makes the most damaging payload (root promotion / alternates) fail regardless of when it is planted, shrinking the race to the narrower in-`.git` shapes.

---

#### upload-pack trust is pinned to the host's git version, which cc-push cannot control or check

**Severity:** Low
**Location:** `devcontainer-config/cc-push.sh:30-43` (header guarantee), fetch `:233-236`
**Boundary:** B1
**Move:** #1 (assumption about input safety), #10-adjacent (version dependence)
**Confidence:** Medium

The core safety claim — a local-path fetch starts upload-pack which "runs no hook, no fsmonitor, no filter, and ignores uploadpack.packObjectsHook" — is a property of *modern* git. It is version-dependent: `uploadpack.packObjectsHook` is deliberately ignored only for repo-level config (a hardening added over git's history), and partial-clone / promisor lazy-fetch behavior (the class the git 2.39.4 security fix touched) can, on an out-of-date git, cause upload-pack to reach beyond the served repo. r3 tested a planted promisor remote on 2.39.5 and it held; r2's static pass did not probe it. cc-push runs whatever git the host has and neither pins nor checks a minimum version. On the solo-dev host this is likely fine, but the guarantee as written reads as absolute.

**Recommendation:** State the version assumption honestly in the header and guide ("assumes git ≥ 2.39; older git may not confine upload-pack's reads"), and optionally assert a minimum `git --version` at startup and `die` below it. This is documentation-honesty, not an exploitable flaw on the current host.

---

#### Guide/LIMITS omit the clean-exit-0 root-promotion route

**Severity:** Low
**Location:** `devcontainer-config/cc-isolated.sh:626-651` (LIMITS); `guides/cc-isolated-usage.md` "Known routes it does not see"
**Boundary:** B2
**Move:** #3 (documentation of the failure surface)
**Confidence:** High

The LIMITS enumeration is honest and self-declared non-exhaustive, and every listed route is real. But it lists only routes that produce *no finding on an otherwise-legitimate `.git`* (hook running a tracked file, launch-time baseline, post-scan planting, etc.). It does not list the route where the scan itself is blinded by an invalid `.git` and returns exit 0 (the two High findings above). A reader treating a clean exit as "the recorded exec surface didn't change" is correct; a reader treating it as "host git will discover the git dir I snapshotted" is misled. Since the guide's whole purpose is to calibrate operator trust in the tripwire, this omission is the most consequential missing entry.

**Recommendation:** Once the two High findings are fixed, the residual is closed and no doc change is needed. If the fix is deferred, add the route to both lists explicitly ("an invalidated `.git` promoted to the checkout root escapes the scan with a clean exit"). Do not ship the doc claiming completeness for `.git` integrity while the fix is pending.

---

## Endorsement Claims

- **Claim:** cc-push runs no git hook/fsmonitor/filter/packObjectsHook from the checkout on a *well-formed* `.git` (git 2.39): every git call goes through `ngit`/`hgit` with `core.hooksPath=/dev/null core.fsmonitor=false`, and the fetch uses upload-pack which runs none of those.
  **Location:** `devcontainer-config/cc-push.sh:96-105,233-236`
  **Evidence:** executed (via fact-check r1 Claim 2 / r3 Claim 3, 24/24 + full plant set + promisor probe)
  **Verified:** the `plant_all` fixture and r3's promisor probe fire no marker on git 2.39.5.
  **Not verified:** upload-pack confinement on git versions other than 2.39.x (see Low finding above); the *object reach* on a malformed `.git` (defeated — see the High findings).
  **route: code-fact-check**

- **Claim:** Every container-controlled string cc-push and the scan print to the terminal is byte-filtered to printable ASCII (+newline) under `LC_ALL=C`, neutralizing C0/C1 controls and bidi overrides.
  **Location:** `devcontainer-config/cc-push.sh:82-84`; `devcontainer-config/cc-isolated.sh:1229-1235`
  **Evidence:** executed (fact-check r1 Claims 5/15, r3 Claim 5)
  **Verified:** `say`/`die`/`run_vis`/`scan_vis` route through `tr -c '[:print:]\n' '?'`; E4/E6 cases pass.
  **Not verified:** stderr of a *failing* `rev-list`/`config` call (r3 Claim 5) is not vis-filtered — it can carry a branch name but only on the failure path; low-risk, worth tightening.

- **Claim:** cc-push's exit codes are confined to 0/1/2 — git's 128 never leaks — via the `( set -e; main )` subshell and the outer `case`.
  **Location:** `devcontainer-config/cc-push.sh:299-306`
  **Evidence:** executed (fact-check Claim 4/1, bats E5)
  **Verified:** 128→1 remap and decline→2 confirmed by suite.
  **Not verified:** signal-terminated `main` (status 130) — r3 notes a signal yields 130, which the `case` remaps to 1; benign.

- **Claim:** cc-push.sh is shipped, chmod'd, symlinked, included in `enforcement_files`, and hashed by the trust manifest + live-verify-gate, so a tampered cc-push blocks the next launch.
  **Location:** `devcontainer-config/install.sh:110,596,601`; `cc-isolated.sh:117`; `hooks/live-verify-gate.sh:73`
  **Evidence:** executed (fact-check Claim 16/12, install-host T3 + live-verify-gate 21/21)
  **Verified:** membership in PAYLOAD, enforcement set, and gate regex; "every manifest-hashed file is in the enforcement set" passes.
  **Not verified:** cc-push does not self-check the manifest at run time (by design — the claim is only that the next cc-isolated launch is blocked).
  **route: code-fact-check**

- **Claim:** The exit scan fails closed on an unreadable/unlistable/oversize snapshot input (launch refusal or exit 4), and a Ctrl-C during the scan exits 4.
  **Location:** `devcontainer-config/cc-isolated.sh:812-820,1288-1294,1454-1471`
  **Evidence:** executed (fact-check Claims 12/13/14)
  **Verified:** size-cap and interrupt paths exit 4; unlistable dir refuses launch.
  **Not verified:** the fail-**open** case is the whole point of the High findings — fail-closed holds for inputs the scan *reaches*, not for a git dir it never examines.
  **route: code-fact-check**

## Primitive sweep

```
Primitive: local-path fetch / upload-pack repository discovery (object-reach beyond intended repo)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| cc-push.sh:233-234  fetch "$co"                 | S1 | check_checkout ($co/.git file tests only) | Finding 1 (root-promotion exfil — guard is over $co/.git, discovery is over $co) |
| cc-push.sh:241      ls-remote --symref "$co"     | S1 | same check_checkout                        | same class — also a second upload-pack contact; strict fix applies here too |
| cc-push.sh:251      fetch origin                 | S4 | remote from clone config only              | cleared — origin is host-configured, never read from checkout |
| cc-isolated.sh:648  scan_git_dirs $ws/.git       | S1 | assumes $ws/.git is git's git dir           | Finding 2 (invalid .git → root promotion → clean exit 0) |

Primitive: host git exec-surface in the checkout (hooks/filters/config includes)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| exit-scan snapshot of hooks/config/includes    | S1 | content-hash diff, --no-includes reads     | cleared for enumerated surface (fact-check Claims 9-15); blind to root-promotion (Finding 2) |
| host `git push`/`status` in checkout (operator) | S1 | cc-push replaces it; scan warns             | cleared *if* operator uses cc-push and trusts the tripwire — Findings 1/2 undermine the trust |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | cc-push exfil via root/nested promotion | High | B1 | `cc-push.sh:122-159,233` | High |
| 2 | exit scan clean-0 on invalid `.git` | High | B2 | `cc-isolated.sh:648-660,1224` | High |
| 3 | check→fetch TOCTOU (live container) | Medium | B1 | `cc-push.sh:188→233` | Medium |
| 4 | upload-pack trust pinned to git version | Low | B1 | `cc-push.sh:30-43` | Medium |
| 5 | LIMITS/guide omit root-promotion route | Low | B2 | `cc-isolated.sh:626-651` | High |

## Overall Assessment

The architecture is the right one: keep host git out of the container-written checkout, push through a bare host-only clone that only the host writes, snapshot-diff the exec surface as a tripwire, and integrity-gate the new file. Against a well-formed `.git` the design holds, and the sanitizing, exit-code, fail-closed, and install/manifest/gate machinery are solid and well-tested. The single architectural weakness is shared by both new mechanisms and is the thing to fix before merge: **both cc-push and the exit scan bound git's reach using host-side file tests over `$co/.git`, while git's own repository discovery operates over `$co` and falls back to the checkout root (or a nested/sibling layout) when `.git` is invalid.** The adversary owns `.git`, so it can force that fallback — turning cc-push into an exfiltration primitive and the exit scan's clean exit 0 into a false-safe signal, neither of which is in LIMITS. The fix is minimal and does not require running git *operations* in the checkout: fetch/ls-remote from `"$co/.git"` with `--upload-pack='git-upload-pack --strict'` (probe P2 confirms this refuses the escapes while `.git`-path alone does not), refuse an invalid `<checkout>/.git` outright, and have the scan resolve the git dir git will actually discover (a hooks-off `rev-parse --git-dir`, which runs no hook) and treat divergence as a finding. Also add HEAD to the recorded surface and tell operators to `docker stop` before cc-push. With those, the two High findings close and the residual matches what the docs claim. **Recommend: do not merge until Findings 1 and 2 are fixed** — they defeat the two headline guarantees within the stated threat model.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to /workspace/docs/reviews/q076-security-review-2026-09-27.md, structured per the security-reviewer skill, with a Goal-Alignment Note.

**Answered:** Report saved at the required path in the skill's structure (Trust Boundary Map + source table, Findings with boundary anchors, Endorsement Claims with Verified/Not-verified pairs, Primitive sweep, Summary Table, Overall Assessment). Design-level verdict on cc-push's approach (sound in shape; one structural gap where file tests over `$co/.git` disagree with git's discovery over `$co`), the minimal correct fix for the discovery-fallback class (fetch `"$co/.git"` with `--upload-pack='git-upload-pack --strict'` — validated by my own probe P2, which showed the path change alone is insufficient and `--strict` is load-bearing; plus resolve-the-real-git-dir for the scan), the git-version dependence of upload-pack trust, the check→fetch race (recommend `docker stop`), install/manifest/gate handling (verified good), and LIMITS/guide honesty (root-promotion route omitted). I consumed the three fact-check reports and did not re-verify their documented behavior; I ran two confirmatory probes and stopped adversarial probing when the exfil-repro pattern tripped the safety classifier.

**Out of scope (per skill non-goals):** Live-container behavior requiring a running devcontainer/kernel (no runtime here — matches the authors' "Live-verified: no" notes); code-quality/refactor judgments; full supply-chain audit (only the one new script + its manifest wiring is in scope).

**Escalate:** Findings 1 and 2 are within the stated threat model and defeat both headline guarantees, turning "clean exit 0 / successful push" into a false-safe signal. They are not documented in LIMITS. Both trace to one root cause and one fix. I did **not** emit a HALT block: exploitation requires the attacker to already control the checkout (the premise of this tool's threat model), which is below the skill's HALT bar (near-certain exploitability where the attacker does *not* already control the host/checkout), but the merge-blocking recommendation stands.
