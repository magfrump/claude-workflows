# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q086 (branch `review/q086` vs `main`)
**Scope:** branch diff `main...HEAD` (`devcontainer-config/Dockerfile`, one added line) plus the commit message of 1ef3090 and the Dockerfile header comment enclosing the changed apt list
**Commit:** 1ef3090
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-28
**Total claims checked:** 11
**Summary:** 7 verified, 1 mostly accurate, 1 stale, 0 incorrect, 2 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read first. None of the claims below matches a logged pattern.

Sandbox caveat: no network egress, no Docker, `parallel` not installed, `/var/lib/apt/lists` empty. Anything needing a package index or a built image is marked Unverifiable.

---

## Claim 1a: "Local changes: - decision 015: added bats, ripgrep, shellcheck (this repo's test suite and SI loop)"

**Location:** `devcontainer-config/Dockerfile:2-3`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only the literal statement that bats, ripgrep and shellcheck are local additions for the test suite. It does not establish that the "Local changes" list is complete (see Claim 1b), and it does not establish that `parallel` is covered by this line.

The three packages are in the base apt list:

```dockerfile
# devcontainer-config/Dockerfile:39-42
  bats \
  parallel \
  ripgrep \
  shellcheck \
```
(excerpt ends :42; the enclosing RUN instruction runs :19-43 and ends `&& apt-get clean && rm -rf /var/lib/apt/lists/*` — read)

The line claims nothing false. `parallel` (:40) now sits between bats and ripgrep with no rationale comment. It serves the same purpose (the test suite), but the header line does not name it.

**Evidence:** `devcontainer-config/Dockerfile:1-10`, `devcontainer-config/Dockerfile:19-43`

---

## Claim 1b: The header's "Local changes:" list (decisions 015 and 016 only) enumerates this file's local changes vs upstream

**Location:** `devcontainer-config/Dockerfile:1-6`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the header list names every local addition made in this file. It does not establish which packages upstream's reference Dockerfile ships (no egress to check anthropics/claude-code). The gap existed before this commit; this commit adds one more unlisted item and does not create the problem.

The header lists two items:

```dockerfile
# devcontainer-config/Dockerfile:2-5
# (anthropics/claude-code .devcontainer). Local changes:
#   - decision 015: added bats, ripgrep, shellcheck (this repo's test suite and SI loop)
#   - decision 016: egress profiles baked in; the profile is written root-owned to
#     /etc/cc-egress-profile so an in-container agent cannot widen its own allowlist.
```

Later additions in the same file, each with its own decision citation, are missing from the list:

```dockerfile
# devcontainer-config/Dockerfile:48
# every firewall run (decision log #40: the filtering resolver that closes
```
```dockerfile
# devcontainer-config/Dockerfile:92
# uv — the Python toolchain (decision log #18).
```
```dockerfile
# devcontainer-config/Dockerfile:199
# Android toolchain — JDK 17 + a baked SDK (decision log #19).
```
```dockerfile
# devcontainer-config/Dockerfile:254
# Rust toolchain — rustup + a pinned stable, root-owned (decision log #21).
```

Poppler-utils (:180-197) is also unlisted. Most of those later blocks carry their own rationale comments. `parallel` (:40) is the one addition with no rationale comment in the file and no entry in the header list, so a reader of the file alone cannot tell why it is there.

**Evidence:** `devcontainer-config/Dockerfile:1-6`, `devcontainer-config/Dockerfile:34`, `devcontainer-config/Dockerfile:45-50`, `devcontainer-config/Dockerfile:92`, `devcontainer-config/Dockerfile:180-197`, `devcontainer-config/Dockerfile:199`, `devcontainer-config/Dockerfile:254`

---

## Claim 2: "bats --jobs needs GNU parallel."

**Location:** commit 1ef3090 message, body line 1
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers bats 1.8.2 as installed here (the same Debian package the image installs). Tested with `--jobs 1`, `--jobs 2`, and `--jobs 2 --no-parallelize-across-files`. It does not establish the behaviour of other bats versions, or of the Q-090 run-tests.sh change that has not been written yet.

The mechanism is right for suite-level (across-file) parallelism, which is what Q-090 wants. The claim leaves out a qualifier: the abort fires only when `--jobs` is not 1 and across-file parallelism is still on.

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-107
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
    exit 1
  fi
  # shellcheck source=lib/bats-core/semaphore.bash
  source "${BATS_ROOT}/lib/bats-core/semaphore.bash"
  bats_semaphore_setup
fi
```

`parallel` is invoked only on the across-files path:

```bash
# /usr/libexec/bats-core/bats-exec-suite:415-421
if [[ "$num_jobs" -gt 1 ]] && [[ -z "$bats_no_parallelize_across_files" ]]; then
  ...
  parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
else
```
(excerpt ends :421; the `else` branch continues with a serial `for filename` loop — read)

Within-file parallelism uses bats' own semaphore (`bats-exec-file` sources `semaphore.bash` and calls `bats_semaphore_run`), not GNU parallel. Execution confirmed all three cases with `parallel` absent: `bats --jobs 2 t.bats` → `Error: Cannot execute "2" jobs without GNU parallel`, exit 1; `bats --jobs 1 t.bats` → passes, exit 0; `bats --jobs 2 --no-parallelize-across-files t.bats` → passes, exit 0.

A more precise wording: "bats --jobs N>1 needs GNU parallel to run test files in parallel; within-file parallelism (`--no-parallelize-across-files`) does not."

Execution provenance: commands `bats --jobs 2 t.bats`, `bats --jobs 1 t.bats`, and `bats --jobs 2 --no-parallelize-across-files t.bats`, each under `timeout 60`. They ran in a throwaway `mktemp -d` dir under /tmp (removed afterwards) on a trivial `@test a { true; }` file. Exit codes were 1, 0, 0. Timestamp 2026-09-28T21:23:16Z.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-107`, `/usr/libexec/bats-core/bats-exec-suite:415-421`, `/usr/libexec/bats-core/bats-exec-file:234-257`, `/usr/libexec/bats-core/bats:54`, docs/reviews/execution-logs/q086-bats-jobs-probe.log

---

## Claim 3: "The full suite runs serially in 742 s on a 16-core machine"

**Location:** commit 1ef3090 message, body lines 1-2
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the recorded measurement (main 2bf5979, 2026-09-28, `bats -T`, serial). It does not establish that the number reproduces at HEAD, which was not re-run per the brief, and it does not establish the machine's core count beyond the doc's own statement and this sandbox's `nproc` of 16.

The measurement is recorded:

```markdown
# docs/working/proposal-2026-09-27-smaller-review-units.md:109-111
Full suite on `main` 2bf5979: `bats -T` on all 122 files, serial, 2026-09-28. Machine: 16 cores, bats 1.8.2, no GNU `parallel`.

- **Totals:** 2,129 tests in **742 s wall** (12.4 min). The per-test times sum to 10.1 min.
```

`nproc` in this sandbox returns `16`, which is consistent. The same figure appears in the Q-086 entry at `docs/working/questions.md:212`.

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:109-115`, `docs/working/questions.md:212`

---

## Claim 4: "a --jobs option in run-tests.sh follows once the rebuilt image has it."

**Location:** commit 1ef3090 message, body lines 2-3
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers (a) that run-tests.sh has no `--jobs` today and (b) that a tracked follow-up exists. The follow-up (Q-090) is on the `answers-2026-09-28` branch (48bca90), not on this branch's base (6405e43). The verdict does not establish that Q-090 will be on `main` when this item merges.

`grep -n jobs scripts/run-tests.sh` returns no matches (paraphrased — no quote available because the claim covers absence of code: zero grep hits in the 375-line file). The follow-up is tracked on 48bca90:

```markdown
# git show 48bca90:docs/working/questions.md (Q-090 entry)
When `parallel` is present in the image (Q-084 step 4 prints a version), add `--jobs N` to `scripts/run-tests.sh` (suite-level `bats --jobs`, serial when `parallel` is missing) and measure the full-suite wall time against the 742 s serial baseline.
```

`grep -c Q-090 docs/working/questions.md` on this branch returns 0.

**Evidence:** `scripts/run-tests.sh:1-375`, `git show 48bca90:docs/working/questions.md` (Q-090 at :152), `docs/working/questions.md:215-218` (Q-086 Interim line on this branch)

---

## Claim 5: "the user's parallel --version answer (20210822)"

**Location:** commit 1ef3090 message, Notes line
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the answer is recorded in the repo. It does not establish where the user ran the command.

```markdown
# git show 48bca90 — docs/working/questions-archive.md (Q-086)
**Answered 2026-09-28:** `GNU parallel 20210822`. That is Ubuntu 22.04's version (bookworm ships 20221122), so it most likely ran on the host, not in the image.
```

That text is not on this branch. On this branch, Q-086 is still `**Status:** OPEN` (`docs/working/questions.md:209-210`).

**Evidence:** `git show 48bca90` (questions-archive.md hunk), `docs/working/questions.md:209-218`

---

## Claim 6: "matches Ubuntu 22.04's package, not bookworm's (20221122)"

**Location:** commit 1ef3090 message, Notes line
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only the attempt to establish the two distro package versions offline. It does not establish either version, and it does not establish the inference "so it was most likely run on the host."

Nothing offline establishes these versions. `apt-cache policy parallel` returns `Installed: (none)` / `Candidate: (none)` with an empty version table. `/var/lib/apt/lists` holds only `lock` and `partial`. There is no `/usr/share/doc/parallel` and no cached .deb (paraphrased — no quote available because the claim covers absence: empty apt index and no package files). The only in-repo source for "20221122" and "Ubuntu 22.04" is the same agent-written note in 48bca90, which is not independent evidence.

A host check could settle it:
`docker run --rm debian:bookworm sh -c 'apt-get update -qq && apt-cache policy parallel'` and
`docker run --rm ubuntu:22.04 sh -c 'apt-get update -qq && apt-cache policy parallel'`.

**Evidence:** `apt-cache policy parallel` (empty), `/var/lib/apt/lists/` (empty), `git show 48bca90` (only in-repo source)

---

## Claim 7: GNU parallel is not currently in the image ("this commit is what puts parallel in the image" — the premise half)

**Location:** commit 1ef3090 message, Notes line
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the Dockerfile on `main` naming no `parallel` package. It does not establish that no other installed package pulls `parallel` in as a dependency, since that needs a package index.

`git show main:devcontainer-config/Dockerfile | grep -c parallel` returns `0` (paraphrased — no quote available because the claim covers absence of a package name). The sandbox is the same bookworm base with bats 1.8.2 and has no `parallel` on PATH (`type -p parallel` empty; see the execution log in Claim 2). The base apt RUN uses `--no-install-recommends` (`devcontainer-config/Dockerfile:19`), which makes a Recommends-driven install unlikely.

**Evidence:** `devcontainer-config/Dockerfile:19` (main), docs/reviews/execution-logs/q086-bats-jobs-probe.log

---

## Claim 8: "this commit is what puts parallel in the image"

**Location:** commit 1ef3090 message, Notes line; `devcontainer-config/Dockerfile:40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the added line is inside the base apt-get install RUN and would install the package named `parallel`. It does not establish that bookworm's archive has a package named `parallel` or that the build succeeds. That needs a build with egress, which is Q-084 step 4.

```dockerfile
# devcontainer-config/Dockerfile:19-20
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
```
(excerpt ends :20; the RUN continues through :43 and includes `parallel \` at :40 — read)

This is the only `parallel` occurrence in the Dockerfile. The RUN instruction's text changed, so Docker's layer cache misses for this layer on the next build (paraphrased — no quote available because this is Docker cache semantics, not repo code).

**Evidence:** `devcontainer-config/Dockerfile:19-43`

---

## Claim 9: "Live-verified: no — package-list change only; the next install.sh re-bless and image rebuild, then `parallel --version` inside cc-isolated, verifies it"

**Location:** commit 1ef3090 message, trailer
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that (a) the diff is only a package-list line, (b) the Dockerfile is a gated enforcement file that needs this trailer, (c) install.sh re-blesses, and (d) the launcher rebuilds when the blessed hash changes. It does not establish that devcontainer CLI's rebuild re-runs the apt layer rather than reusing a cached image, beyond the layer-text change in Claim 8. It also does not establish that a user will actually run the check.

(a) The branch diff is one added line, `+  parallel \` (paraphrased — no quote available because the full diff is in the review brief, not a repo file).

(b) The gate treats the Dockerfile as an enforcement file:

```bash
# hooks/live-verify-gate.sh:73
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh|install\.sh$|egress/)'
```

The launcher hashes it:

```bash
# devcontainer-config/cc-isolated.sh:126-130
enforcement_files() {
  local cfg
  cfg="$(config_dir)"
  echo "devcontainer.json"
  echo "Dockerfile"
```
(excerpt ends :130; the function continues to :155 listing the other boundary files and globs — read)

(c) install.sh ships the file and blesses:

```bash
# devcontainer-config/install.sh:110
PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress claude-home)
```
```bash
# devcontainer-config/install.sh:606
  CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless
```

(d) The launcher bakes the hash and rebuilds when it changes:

```bash
# devcontainer-config/cc-isolated.sh:703-707
  # re-blessed since this one was built, it is running the previous boundary;
  # recreate it (the ~/.claude volume and the repo are unaffected).
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
```
(excerpt ends :707; the enclosing main() continues with the probe/re-assert logic — read to :720)

`--probe-only` always rebuilds (`devcontainer up --remove-existing-container`, `cc-isolated.sh:693-696`). The hash reaches the image through `CC_CONFIG_HASH` (`devcontainer.json:54`, `Dockerfile:481`, `Dockerfile:523`).

**Evidence:** `hooks/live-verify-gate.sh:13-37`, `hooks/live-verify-gate.sh:73-74`, `devcontainer-config/cc-isolated.sh:116-155`, `devcontainer-config/cc-isolated.sh:640-707`, `devcontainer-config/install.sh:110`, `devcontainer-config/install.sh:606`, `devcontainer-config/devcontainer.json:54`, `devcontainer-config/Dockerfile:481-523`

---

## Claim 10: GNU parallel's citation notice would not pollute `bats --jobs` output non-interactively

**Location:** brief item 7 (implicit in the plan to use `bats --jobs` in run-tests.sh); `/usr/libexec/bats-core/bats-exec-suite:420`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only the bats side of the invocation. It does not establish when GNU parallel prints its citation notice, or whether Debian's package changes that. No parallel source or documentation is present offline.

The bats side is known. bats sends parallel's stderr into its own stdout pipe:

```bash
# /usr/libexec/bats-core/bats-exec-suite:420
  parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
```

No `--will-cite` flag is passed. So parallel's stderr is never a terminal under bats, and any notice parallel does print would be mixed into the TAP stream. Whether it prints depends on parallel's own tty check and on Debian patching, and neither can be checked offline. To settle it, in the rebuilt image run `bats --jobs 2 test/<any>.bats | cat` and grep the output for `cite`. Alternatively, read `parallel`'s `citation_notice` logic in the installed `/usr/bin/parallel`.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:415-421`; `/usr/bin/parallel` absent in sandbox

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- **Claim 1b** (`devcontainer-config/Dockerfile:1-6`): the header's "Local changes" list names only decisions 015/016, and later additions (dnsmasq-base #40, uv #18, poppler-utils, JDK/SDK #19, Rust #21) are missing. `parallel` is now also unlisted and is the only addition with no rationale comment anywhere in the file. This predates the commit. A one-line comment or header entry for `parallel` (Q-086) would close this commit's share of it.

### Mostly Accurate
- **Claim 2** (commit message): "bats --jobs needs GNU parallel" should say it is needed for `--jobs N>1` across files. `--jobs 1` and `--jobs N --no-parallelize-across-files` run without it (executed).

### Unverifiable
- **Claim 6** (commit message Notes): parallel 20210822 = Ubuntu 22.04 and bookworm = 20221122 needs an index lookup: `docker run --rm debian:bookworm sh -c 'apt-get update -qq && apt-cache policy parallel'` (and the same on `ubuntu:22.04`).
- **Claim 10** (bats-exec-suite:420): whether parallel's citation notice appears in `bats --jobs` output needs the rebuilt image: `bats --jobs 2 test/<file>.bats | cat | grep -i cite`.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to `/workspace/.claude/wt-q086/docs/reviews/q086-code-fact-check-report.md` in the code-fact-check schema, with `**Commit:** 1ef3090` and `**Replication:** k=1 (loop pass, decision 031)` in the header, every claim tagged with a Legibility-target, and a Goal-Alignment Note at the end.
- Answered: yes. All 7 brief items were verdicted (item 6 was split into 1a/1b, and item 3 into 5/6/7/8).
- Out of scope: running the full suite (brief forbids it); building the image and any package-index lookup (no Docker, no egress).
- Escalate: (1) the answers commit 48bca90 names **bb9982f** as the commit that adds `parallel` ("bb9982f adds `parallel` to the Dockerfile's base apt list", in questions-archive and the Q-084 paste). This review unit is **1ef3090**, a separate commit with the same subject. If 1ef3090 is what lands on main, those references point at a commit that is not on main. Reconcile when merging. (2) Q-090, the follow-up the commit message promises, exists only on `answers-2026-09-28`, not on this branch's base 6405e43.
- Decisions I made: I counted the header-list gap as Stale (a pre-existing gap) rather than Incorrect, because the listed line itself is true. I verdicted Claim 3 Verified against the recorded measurement without re-running it. I wrote one execution log under `docs/reviews/execution-logs/` as the skill's provenance rule requires (the brief said "report file only"; the log is the skill-required evidence attachment).
