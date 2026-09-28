Commit: 1ef3090

## Dependency Upgrade Evaluation: Debian `parallel` (GNU parallel) — absent → bookworm archive version (unpinned)

Review unit: Q-086, branch `review/q086` vs `main`, worktree `/workspace/.claude/wt-q086`. The change adds one package name to the base `apt-get install` list of `devcontainer-config/Dockerfile`. It is a new dependency, not a version bump, so the skill's "breaking changes between versions" analysis is recast as "what the new package changes for the image and its consumers".

### Summary
**Recommendation:** Upgrade now (approve the addition), with one documentation follow-up (D1) and one advisory for Q-090 (D3).
**Breaking change impact:** None. No existing code calls `parallel`. bats only uses it when `--jobs N>1` is passed without `--no-parallelize-across-files`, and nothing in the repo passes `--jobs` today (fact-check Claim 4).
**Estimated effort:** minutes (one line; the rebuild is the existing install.sh re-bless path).
**Risk:** Low
**Audit state:** Unverified. No advisory database or package index is reachable offline (`/var/lib/apt/lists` empty, fact-check Claim 6). Whatever bookworm ships at build time is what lands; it tracks Debian security updates like every other package in this list.

### Motivation
bats 1.8.2's suite runner aborts on `--jobs N>1` across files when GNU parallel is missing (fact-check Claim 2, executed: `bats --jobs 2 t.bats` → `Cannot execute "2" jobs without GNU parallel`, exit 1). The serial full suite takes 742 s on 16 cores (Claim 3). The package exists so Q-090 can add `--jobs` to `scripts/run-tests.sh`. The motive is concrete and measured, not "staying current".

Worth recording: Debian's own `bats` package already declares the dependency.

```
$ dpkg -s bats | grep -i -E 'depends|recommends|suggests'
Recommends: parallel
```

The image does not get it because the base RUN uses `--no-install-recommends` (`devcontainer-config/Dockerfile:19`). So this commit restores bats' own recommended pairing rather than introducing an unusual dependency. The bats Debian changelog also says which `parallel` it means:

```
# zcat /usr/share/doc/bats/changelog.Debian.gz (lines 94-97)
  * Needs GNU's (not moreutils) parallel command line tool.
    Added to B-Depends (for tests) and Recommends.
    ATM no proper sensing is done, so parallel runs might fail if there is
    no GNU parallel. See https://github.com/bats-core/bats-core/issues/240
```

Debian package `parallel` is the GNU one; `moreutils` (which ships a different `parallel` binary) is not in the Dockerfile (`grep -n moreutils devcontainer-config/Dockerfile` → no match). No conflict.

### Breaking Changes That Affect This Project

No breaking changes affect this project's usage. No script, hook or test invokes `parallel` directly (`grep -rn parallel test/*.bats scripts/run-tests.sh guides/devcontainer-setup.md` matched only workflow-name strings such as `parallel-worktrees`, not the binary).

### Breaking Changes That Don't Affect This Project
- bats behaviour with `--jobs 1` or with `--no-parallelize-across-files` is unchanged whether or not `parallel` is installed (fact-check Claim 2, executed).
- Serial `bats` runs (all current runs) never reach the `parallel` branch in `bats-exec-suite:415-421`.

### Transitive Effects
- **Runtime:** GNU parallel is a Perl program. `perl` 5.36 is already present on this bookworm base (`/usr/bin/perl`, `perl -v` → v5.36.0 in the sandbox). Its exact Depends list and installed size need the package index: Unverified.
- **Version compatibility with bats 1.8.2:** bats calls `parallel --keep-order --jobs "$num_jobs" bats-exec-file ... ::: ...` (`bats-exec-suite:420`). Those are long-standing GNU parallel options. Whether bookworm's build accepts them unchanged cannot be checked without the binary: Unverified, but Debian ships bats 1.8.2 and `parallel` from the same release and bats Recommends it, which is inferred evidence that they are tested together.
- **Pinning convention:** consistent. None of the ~20 packages in the base apt list carries a version pin (`devcontainer-config/Dockerfile:19-43`). Pins in the file (`ARG ..._VERSION` / `_SHA256`) apply only to toolchains fetched outside apt (git-delta, uv, shfmt, Android, Rust, .NET, zsh-in-docker, elan). An unpinned `parallel` matches how bats, ripgrep and shellcheck are installed.
- **Tests pinning the apt list:** none found. `grep -rln Dockerfile test/` piped into a grep for `ripgrep|apt-get|shellcheck` returned no match, so no test asserts the package list and none needs updating.
- **Layer cache:** the RUN text changed, so the next build re-runs this apt layer (fact-check Claim 8). Expected and harmless.

### Findings

**D1 — The addition has no rationale in the file or the decision log, unlike its precedents**
- **Severity:** Low (documentation; non-blocking)
- **Location:** `devcontainer-config/Dockerfile:1-5`, `devcontainer-config/Dockerfile:40`
- **Evidence:**
  ```dockerfile
  # devcontainer-config/Dockerfile:2-3
  # (anthropics/claude-code .devcontainer). Local changes:
  #   - decision 015: added bats, ripgrep, shellcheck (this repo's test suite and SI loop)
  ```
  (excerpt ends :3; the header continues to :10 with the decision-016 line and node:22 note — read)
  ```dockerfile
  # devcontainer-config/Dockerfile:39-41
    bats \
    parallel \
    ripgrep \
  ```
  (excerpt ends :41; the RUN continues to :43 — read)
  The nearest precedent, poppler-utils, got a decision-log row:
  ```
  # docs/decisions/log.md:75 (row 52, excerpt)
  | 52 | 2026-09-17 | **A `scholar` egress profile for academic literature, plus `pdftotext` in the shared image.** ...
  ```
- **Why it matters:** the header says "Keep this file minimal-diff against upstream", and its "Local changes" list is how a refresh against upstream tells local additions from upstream ones. A bare `parallel \` with no comment is the one addition a future refresher cannot attribute. The pre-existing staleness of the header list is fact-check Claim 1b; this finding is only about this commit's share.
- **Fix (either is enough):** extend the header line to `added bats, parallel, ripgrep, shellcheck (this repo's test suite and SI loop; parallel for bats --jobs, Q-086)`, or add a one-line comment above the RUN. A decision-log row is optional; the change is sub-threshold (single clear answer, trivially reversible), so the header line is the proportionate fix.
- **Confidence:** High
- **Legibility-target:** for-author

**D2 — `guides/devcontainer-setup.md` does not need updating**
- **Severity:** None (coverage note)
- **Location:** `guides/devcontainer-setup.md:227`
- **Evidence:**
  ```markdown
  # guides/devcontainer-setup.md:227
  - **Tests:** `bats test/` green inside the container.
  ```
- The guide does not enumerate the image's apt packages; it names `bats` and `shellcheck` only as commands in its test-layer tables (:255, :268-269). Nothing there becomes false or incomplete. Decision 015 also does not list packages beyond "`bats test/` green inside" (`docs/decisions/015-cc-process-isolation-docker-devcontainer.md:56`). No doc change needed beyond D1.
- **Confidence:** High
- **Legibility-target:** for-orchestrator-synthesis

**D3 — Advisory for Q-090: parallel's stderr is merged into bats' output, so anything it prints lands in the TAP stream**
- **Severity:** Low (advisory; affects the follow-up, not this diff)
- **Location:** `/usr/libexec/bats-core/bats-exec-suite:420`
- **Evidence:**
  ```bash
  # /usr/libexec/bats-core/bats-exec-suite:420
    parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
  ```
  (single-line excerpt inside the `if` at :415-421; the `else` branch is the serial loop — read)
- Two sources of stray stderr:
  1. **Citation notice.** bats passes no `--will-cite`. Whether GNU parallel prints its notice when stderr is not a tty, and whether Debian patches that, needs the binary or its docs: Unverifiable offline (same as fact-check Claim 10). If it does print, the fix belongs in Q-090 (for example `mkdir -p ~/.parallel && touch ~/.parallel/will-cite` in the image or runner, or `PARALLEL=--will-cite` in the environment; both are Unverified until checked against the installed version).
  2. **Perl locale warnings.** parallel is Perl, and Perl warns on stderr when the ambient locale is not installed. In this sandbox (same bookworm base, `LC_ALL=en_US.UTF-8`, `locale -a` lists only `C`, `C.utf8`, `POSIX`):
     ```
     $ LC_ALL=en_US.UTF-8 perl -e 'print "x\n"' 2>&1 | head -3
     perl: warning: Setting locale failed.
     perl: warning: Please check that your locale settings:
     	LANGUAGE = "en_US:en",
     $ LC_ALL=C.UTF-8 perl -e 'print "ok\n"' 2>&1
     ok
     ```
     Run in a `mktemp -d` dir, 2026-09-28, under `timeout 10`, dir removed afterwards. `scripts/run-tests.sh:127-132` already pins `LC_ALL=C.UTF-8` when the ambient locale is missing, so runs through the runner are covered. A bare `bats --jobs` in the image would get the warnings mixed into its output. Whether the built image has the same locale gap as this sandbox is inferred, not observed.
- **Suggested check once the image is rebuilt (Q-084 step 4 / Q-090):** `bats --jobs 2 test/<any>.bats 2>&1 | grep -i -E 'cite|locale'` should print nothing, both through `scripts/run-tests.sh` and bare.
- **Confidence:** Medium (bats side and Perl locale behaviour observed; parallel's own notice behaviour unverifiable)
- **Legibility-target:** for-author

**D4 — Licence: no concern for an internal dev image (from memory, not verified)**
- **Severity:** None
- **Location:** `devcontainer-config/Dockerfile:40`
- **Evidence:** GNU parallel's licence cannot be read offline (no `/usr/share/doc/parallel`). From memory it is GPL-3+, which is `[unverified — submitted as claim]`, route: code-fact-check / host check (`docker run --rm debian:bookworm sh -c 'apt-get update -qq && apt-get install -y parallel && grep -m1 License /usr/share/doc/parallel/copyright'`). The image already ships GPL-3+ tools installed the same way:
  ```
  # /usr/share/doc/shellcheck/copyright (first License line)
  License: GPL-3+
  ```
  The image is built locally from a Dockerfile and not redistributed, and `parallel` is invoked as a separate program, never linked. GPL obligations attach to distribution, so there is no licence issue for this use. The citation request is an academic courtesy enforced only by the notice (D3), not a licence term (also from memory; unverified).
- **Confidence:** Medium
- **Legibility-target:** for-orchestrator-synthesis

**D5 — Maintenance**
- **Severity:** None
- **Location:** `devcontainer-config/Dockerfile:40`
- GNU parallel is a long-lived GNU project with monthly releases, packaged in Debian main (inferred from its availability as a plain apt name and bats' Recommends on it; current release cadence and bookworm's security-support status need the web: Unverifiable). It follows the image's rebuild cycle like every other unpinned apt package, so no extra maintenance burden.
- **Confidence:** Medium
- **Legibility-target:** for-orchestrator-synthesis

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `bats --jobs 2 t.bats` (parallel absent) | 1 | 2026-09-28T21:23:16Z | fact-check Claim 2; `docs/reviews/execution-logs/q086-bats-jobs-probe.log` |
| `bats --jobs 1 t.bats`, `bats --jobs 2 --no-parallelize-across-files t.bats` | 0, 0 | 2026-09-28T21:23:16Z | fact-check Claim 2 |
| `apt-cache policy parallel` | 0 (empty candidate) | 2026-09-28 | fact-check Claim 6 |
| `dpkg -s bats \| grep -i -E 'depends\|recommends\|suggests'` | 0 | 2026-09-28, cwd `/workspace/.claude/wt-q086`, 1ef3090 | verbatim inline: `Recommends: parallel` |
| `LC_ALL=en_US.UTF-8 perl -e 'print "x\n"'` / `LC_ALL=C.UTF-8 perl -e ...` | 0 / 0 | 2026-09-28, mktemp dir | verbatim inline in D3 |
| `grep -n moreutils devcontainer-config/Dockerfile` | 1 (no match) | 2026-09-28, 1ef3090 | verbatim: no output |
| `docker build` of the image; `parallel --version` inside cc-isolated | — | — | Unverified — recommended pre-merge check (Q-084 step 4; needs Docker + egress) |
| `bats --jobs 2 test/<file>.bats 2>&1 \| grep -i -E 'cite\|locale'` in the rebuilt image | — | — | Unverified — recommended check before Q-090 lands |
| Licence / Depends of bookworm `parallel` | — | — | Unverified — recommended pre-merge check |

### Risk Factors
- **Build failure if the package name did not resolve.** Low: `parallel` is the name bats' own Recommends uses on this same Debian release. Confirmed only by the rebuild.
- **Output pollution under `bats --jobs`** (D3). Affects Q-090, not this commit. Mostly covered by the runner's locale pin; the citation notice is unverified.
- **Image size:** a small Perl script package on a base that already has Perl. Exact size Unverified.

### Rollback Plan (precondition — complete before starting Migration Plan)

**Exact rollback commands:**
```
git -C /workspace revert 1ef3090          # or the merge commit that lands it
# ship the reverted Dockerfile and re-bless (the existing path):
devcontainer-config/install.sh
# next cc-isolated launch sees the changed blessed hash and runs
#   devcontainer up --remove-existing-container ...  (cc-isolated.sh:703-707)
```

**Verification step:** inside the rebuilt container, `type -p parallel` prints nothing and `bats test/<any-fast>.bats` still passes serially. Because nothing calls `parallel` until Q-090, rollback cannot break a current consumer; if Q-090 has landed, its runner must fall back to serial when `parallel` is missing (Q-090's own text says it will).

**Rehearsal status:** [ ] Not rehearsed. It needs Docker and egress, which this sandbox lacks. The rollback is a one-line revert through the same install/rebuild path the forward change uses, so it is exercised by the forward rebuild.

### Migration Plan
1. Apply D1 (one header or comment line naming `parallel` and Q-086).
2. Merge; run `install.sh` to re-bless; relaunch cc-isolated so it rebuilds.
3. Inside the container: `parallel --version` (Q-084 step 4) and `bats --jobs 2 test/<any>.bats 2>&1 | grep -i -E 'cite|locale'` (expect no match).
4. Then Q-090 adds `--jobs` to `scripts/run-tests.sh`, keeping the serial fallback when `type -p parallel` is empty.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q086/docs/reviews/q086-dependency-upgrade-review-2026-09-28.md, structured per the dependency-upgrade skill.
- Answered: yes
- Out of scope: building the image, package-index lookups, licence and version facts needing the web (all marked Unverified); the design of Q-090's `--jobs` option beyond the stderr advisory.
- Escalate: (1) D3's citation-notice and locale checks should be attached to Q-090 / Q-084 step 4, since they only surface in the rebuilt image. (2) Fact-check's escalation stands: 48bca90's archive text names bb9982f as the commit adding `parallel`, but this unit is 1ef3090; reconcile at merge.
- Decisions I made: treated a new package as a "none → archive version" upgrade in the skill template; did not re-run command outcomes the fact-check report already covered and cited its claim ids instead; ran only read-only probes (`dpkg -s`, `grep`, a two-line `perl` locale check), all under `timeout` or instant, nothing left running.
