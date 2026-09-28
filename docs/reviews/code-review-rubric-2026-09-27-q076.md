Commit: 623ca02

# Code Review Rubric: Q-076 (cc-isolated exit scan and cc-push)

**Scope:** `git diff main...integrate/q076`, which merges branch `feat/q076-git-exit-scan` (tip d2e9931).
- New: `devcontainer-config/cc-push.sh`, `cc-exit-scan.sh` (extracted from `cc-isolated.sh`) and `cc-gitdir.sh`.
- Changed: `cc-isolated.sh`, `install.sh`, `hooks/live-verify-gate.sh`, `guides/cc-isolated-usage.md`, `guides/devcontainer-setup.md`, decision log row 58, and tests.

**Status:** 0 🔴 · 0 🟡 open · 🟢 items deferred or documented, each recorded in the override log. **Mergeable.** Single-sample review; absence of findings is not an attestation. **Not live-verified:** every enforcement-file commit carries `Live-verified: no`; see Q-084.

## How this review ran
- **Combined-branch rounds** (Q-076 was reviewed with Q-077, Q-078 and Q-080 until the loop cap):
  - Fact-check k=3 at ce6bee6 (`iter1-*`): the key-list design was bypassed.
  - Fact-check k=3 at 02d14b0 (`iter2-*`): the redesign was still incomplete, so the user chose "Tripwire + clone helper".
  - Fact-check k=3 at a42e37f (iteration 3): cc-push fetched the wrong repository and had other defects.
  - At the cap the user chose "Split, then finish".
- **Q-076's own review:**
  - Fact-check k=3 at 61d801c: `q076-code-fact-check-report-r1..r3.md`.
  - Critics (opus): `q076-security-review-2026-09-27.md`, `q076-architecture-review-2026-09-27.md`, `q076-performance-review-2026-09-27.md`, `q076-api-consistency-review-2026-09-27.md`.
- **Fixes:** f511cc1 (extract the scan), 9133e23 (git-dir validity, `--strict`), 41622c0 (cc-push), 6fc7b5a (cc-isolated), bfe8292 (docs).
- **Confirming pass on bfe8292:** `q076-security-review-2026-09-27-confirm.md` (mergeable; new Lows N1 and N3 were fixed in 7870e09) and `q076-code-fact-check-report-confirm.md` (one Incorrect header line, fixed in d2e9931).
- **Classifier stops:** safety classifiers stopped several reviewers and one implementer from building adversarial fixtures. Where that happened, reports mark the claim as read-only analysis, and the tests check refusals and command lines rather than working exfiltration.
- **Tests at 623ca02:** `bats test/cc-isolated-functions.bats test/cc-push.bats` 205/205; `test/install-host.bats` 92/92 in a clean run. Earlier full-suite runs failed a different single `install-host` test each time (T83, T6). Each passed when run alone; the cause was stray probe processes from review agents, which trip install.sh's agent-process guard.

## 🔴 Must Fix
None open.

| ID | Finding | Source | Status |
|---|---|---|---|
| R1 | cc-push fell back to a repository laid out at the checkout root (invalid `.git`, root `commondir`, alternates, bare layout) and pushed another host repo's history | q076 fact-check r1 C1; security H1 | ✅ 9133e23: fetch `"$co/.git"` with `git-upload-pack --strict`; refuse unless `gitdir_valid .git`; refuse if the root `looks_like_gitdir` |
| R2 | The exit scan returned 0 (clean) on the same route | fact-check r1 C9; security H2 | ✅ 9133e23: the scan records `.git` validity and root layout, and a change or an invalid `.git` is a finding; 6fc7b5a: launch refused on an already-invalid state |

## 🟡 Must Address
| ID | Finding | Source | Status |
|---|---|---|---|
| A1 | Check-then-fetch race while the container runs | security M3; fact-check r3 C3b | ✅ 41622c0: refuse while a container for the checkout runs, or docker is missing or not answering; `--allow-running` warns |
| A2 | Every branch copied to host disk (300 MB no-op) | performance 1 | ✅ 41622c0: single-branch fetch |
| A3 | Seven partial answers to "which git dir does git use" | architecture 2 | 🟢 Partly: `cc-gitdir.sh` is shared; the scan still reads `commondir`'s first line itself (confirm N4) |
| A4 | Scan inline in a ~1500-line launcher | architecture 1 | ✅ f511cc1: extracted to `cc-exit-scan.sh` (user decision) |
| A5 | Host tools' exit codes disagreed | api F1/F2 | ✅ 41622c0, 6fc7b5a; decision log 58 (user decision: match install.sh) |
| A6 | Host-only tools sit in the enforcement manifest | architecture 3 | 🟢 Deferred by user → Q-083 |

## 🟢 Consider
| ID | Finding | Status |
|---|---|---|
| C1 | No minimum git version (security L4) | ✅ 41622c0; the version list is unverified offline → Q-084 |
| C2 | Size cap skipped at the first reads of `.git`/`commondir` (perf 2) | ✅ 9133e23 |
| C3 | Raw stderr, `--` handling, partial clones, Ctrl-C=130 (fact-check r3, api F5–F8) | ✅ 41622c0 |
| C4 | Two copies of the limits list (architecture 4) | ✅ bfe8292: the guide is the single list |
| C5 | PATH lookups could run a program the session wrote (confirm N1) | ✅ 7870e09 |
| C6 | Snapshots differ but the diff is empty, returning 0 (confirm N3) | ✅ 7870e09: returns 2 |
| C7 | Header's exit-status line (confirm fact-check) | ✅ d2e9931 |
| D1 | With `--yes` and no `--branch`, HEAD picks the branch (confirm N2) | Documented limit (override log) |
| D2 | A bare-layout directory not named `.git` in the working tree is not walked (fact-check r3 C10a) | Documented limit (override log) |
| D3 | Scan cost: ~2–4 s per snapshot, ~29 ms per embedded repo; one unlistable dir blocks the scan (perf 3, 4) | Documented limit (override log) |
| D4 | cc-push reads the checkout via upload-pack; safety depends on git's handling of a hostile repo (security L4) | Documented limit |
| D5 | `gitdir_valid` is stricter than git in three places (refuses more) | Accepted; errs toward refusing |
| D6 | Locale warning makes some tests fail under an uninstalled `LC_ALL` (confirm N5) | Environmental; pass under C.UTF-8 |

## Considered overrides
No earlier override row matches these files.

## 🧩 Composition check
The discovery-fallback fragments (fact-check r1 C1/C9, security H1/H2, architecture 2, fact-check r3 C10a) share one root: every tool inspected `<checkout>/.git`, while git's own discovery can fall back to the checkout root. The composed fix is 9133e23's shared validity predicate plus `--strict`. No other multi-source cluster qualified.

## Not verified
- No live container: the docker check was exercised only through a test stub, and there has been no real `cc-push` to GitHub (Q-084).
- Git versions other than 2.39.5; the May 2024 fixed-release list (Q-084).
- Completeness of the guide's "Known routes it does not see" list.
