# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q086 (branch `review/q086`)
**Scope:** full branch `main...HEAD`: `devcontainer-config/Dockerfile`, commit messages 1ef3090 / 577bef7 / ed28f76, `review/q086` override-log rows, Confirmed Good rows of `docs/reviews/q086-code-review-rubric-2026-09-28.md`
**Commit:** ed28f76
**Replication:** k=1 (final confirming pass, decision 031)
**Checked:** 2026-09-28
**Total claims checked:** 22
**Summary:** 17 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). One class is relevant: specific measured values quoted from an artifact set that doesn't contain them (entries at lines 28 and 30). Claim 4 is checked against that class and does not match it.

Execution provenance for every `executed` claim below:
- Command (run under `bash -c`, in a fresh `mktemp -d` dir holding `t.bats` with 2 tests and `u.bats` with 1 test): `LC_ALL=C timeout 60 bats <args>` for args `--jobs 2 t.bats u.bats`, `--jobs 2 t.bats`, `--jobs 1 t.bats u.bats`, `--jobs 2 --no-parallelize-across-files t.bats u.bats`.
- cwd: `/tmp/tmp.Jdt74rHVUt`. Timestamp: 2026-09-28T21:44:08Z. Exit codes: 1, 1, 0, 0. Output is in `docs/reviews/execution-logs/q086-bats-jobs-probe-final.log`.
- Environment: Bats 1.8.2, `parallel on PATH: none`. The temp dir was removed afterwards, and `pgrep -u $(id -u) -a bats` found no leftover process.
- A first attempt under zsh passed each argument string as a single word, so bats rejected all four with "Bad command line option". The log file was overwritten by the bash re-run above.

---

## Claim 1a: "`bats --jobs N` with N>1 needs it to run test files concurrently"

**Location:** `devcontainer-config/Dockerfile:4-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers bats 1.8.2 (the sandbox's bookworm build). Without `parallel`, `--jobs N>1` aborts unless `--no-parallelize-across-files` is set, and the across-file fan-out calls `parallel`. Does not establish that `--jobs 2` also aborts on a single file (it does — see below; the comment's "test files" wording does not cover that case) or how a future bats version behaves.

The whole header block was read (`Dockerfile:1-9`). The gate is:

```bash
# /usr/libexec/bats-core/bats-exec-suite:99-104
if [[ "$num_jobs" != 1 ]]; then
  if ! type -p parallel >/dev/null && [[ -z "$bats_no_parallelize_across_files" ]]; then
    abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"
    exit 1
  fi
```

The across-file fan-out is the only `parallel` call site:

```bash
# /usr/libexec/bats-core/bats-exec-suite:415,420
if [[ "$num_jobs" -gt 1 ]] && [[ -z "$bats_no_parallelize_across_files" ]]; then
  parallel --keep-order --jobs "$num_jobs" bats-exec-file ... ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
```

(excerpt: lines 416-419 are comments, read; the if block continues past 420 with an else branch, read)

Within-file parallelism uses bats' own semaphore rather than `parallel`: `bats-exec-file:294-296` calls `bats_run_tests_in_parallel` when `num_jobs != 1`. The probe results:
- `--jobs 2 t.bats u.bats` → `Error: Cannot execute "2" jobs without GNU parallel`, exit 1
- `--jobs 1` → exit 0
- `--jobs 2 --no-parallelize-across-files` → 3 tests ok, exit 0

`--jobs 2 t.bats` on a single file also exits 1, so the requirement is set by the flag, not by the number of files. This matches the comment's purpose (running files concurrently), but a reader might wrongly assume a one-file `--jobs` run works without `parallel`.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-104`, `/usr/libexec/bats-core/bats-exec-suite:415-420`, `/usr/libexec/bats-core/bats-exec-file:294-296`, `docs/reviews/execution-logs/q086-bats-jobs-probe-final.log`

---

## Claim 1b: "bats' Debian package only Recommends it"

**Location:** `devcontainer-config/Dockerfile:5`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the installed bats 1.8.2-1 package metadata in the sandbox, which is built from the current image. Does not establish the metadata of whatever bats version apt resolves at the next rebuild (network needed).

Command: `dpkg -s bats | grep -E 'Package|Version|Depends|Recommends'`, cwd `/workspace/.claude/wt-q086`, 2026-09-28T21:47:11Z. The dpkg exit code is not recorded: the log's `exit=` line is blank because the wrapper shell was zsh, where `PIPESTATUS` is not set. dpkg did print the package record. Output (appended to the final probe log): `Package: bats` / `Version: 1.8.2-1` / `Recommends: parallel`. No `Depends:` line names parallel.

**Evidence:** `docs/reviews/execution-logs/q086-bats-jobs-probe-final.log` (dpkg section), `/var/lib/dpkg/status`

---

## Claim 1c: "the install below uses --no-install-recommends"

**Location:** `devcontainer-config/Dockerfile:6`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the base apt RUN, where bats and parallel are installed. Does not establish anything about other apt RUNs later in the file.

```dockerfile
# devcontainer-config/Dockerfile:22
RUN apt-get update && apt-get install -y --no-install-recommends \
```

**Evidence:** `devcontainer-config/Dockerfile:22-46`

---

## Claim 2: the added `parallel \` line sits inside the base apt RUN, keeps the continuation valid, and the RUN still ends with the apt-lists cleanup

**Location:** `devcontainer-config/Dockerfile:43`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the textual structure of RUN `:22-46`: every package line ends in `\`, and the chain ends in the cleanup. Does not establish that the image builds or that `parallel` resolves from bookworm's apt (no Docker, no network; host check at rebuild).

The whole RUN instruction was read:

```dockerfile
# devcontainer-config/Dockerfile:41-46
  vim \
  bats \
  parallel \
  ripgrep \
  shellcheck \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
```

Lines 23-45 are all `  <pkg> \`, which gives a continuous continuation from `:22` to `:46`.

**Evidence:** `devcontainer-config/Dockerfile:22-46`

---

## Claim 3: "bats --jobs needs GNU parallel." (1ef3090 message)

**Location:** commit 1ef3090 message body, line 1
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers bats 1.8.2. Only `--jobs N>1` without `--no-parallelize-across-files` needs it. Does not re-open the settled override (A2).

Settled finding A2 (override-log row `docs/reviews/override-log.md:81`); this pass has no new evidence. The probe confirms it again: `--jobs 1` exits 0 and `--jobs 2 --no-parallelize-across-files` exits 0 without `parallel`. The precise wording is in `Dockerfile:4-6` (Claim 1a).

**Evidence:** `docs/reviews/execution-logs/q086-bats-jobs-probe-final.log`, `/usr/libexec/bats-core/bats-exec-suite:99-104`

---

## Claim 4: "The full suite runs serially in 742 s on a 16-core machine" (1ef3090)

**Location:** commit 1ef3090 message body, lines 1-2
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers two things: the figure traces to a checked-in measurement, and this machine has 16 cores. Does not establish a fresh re-measurement (a full-suite run of ~12 min was not repeated), or that the recorded run was serial on this same machine.

`docs/working/proposal-2026-09-27-smaller-review-units.md:111` (in the /workspace main checkout) says: "- **Totals:** 2,129 tests in **742 s wall** (12.4 min)." `nproc` prints `16`. Compared against the hallucination-pattern class "measured value not in the artifact set": no match, because the value is in the artifact set.

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:111`, `nproc` output

---

## Claim 5: "the user's parallel --version answer (20210822) matches Ubuntu 22.04's package, not bookworm's (20221122)" (1ef3090 Notes)

**Location:** commit 1ef3090 message, Notes
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers nothing beyond noting the claim. Does not establish either distribution's package version.

Settled finding C1 (`docs/reviews/override-log.md:82`); there is no new evidence. `parallel` is not installed and `/var/lib/apt/lists` is empty (paraphrased — no quote available because the claim is about absent package data: `command -v parallel` returned rc=1). Host check: `apt-cache policy parallel` on bookworm, or `parallel --version` in the rebuilt image.

**Evidence:** `docs/reviews/override-log.md:82`

---

## Claim 6: "Live-verified: no — package-list change only" (1ef3090 trailer)

**Location:** commit 1ef3090 message, Live-verified trailer
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the file set and size of 1ef3090's diff. Does not establish the follow-up host verification it promises.

`git show --stat 1ef3090` gives `devcontainer-config/Dockerfile | 1 +`, a single insertion (the `parallel \` line).

**Evidence:** `git show --stat 1ef3090`, `devcontainer-config/Dockerfile:43`

---

## Claim 7: A1 description — header "now names parallel and why: `bats --jobs N` with N>1 needs it … bats' Debian package only Recommends it while the base install uses --no-install-recommends" (577bef7)

**Location:** commit 577bef7 message body, A1 paragraph
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the correspondence between the paragraph and `Dockerfile:4-6`. Does not re-verify the bats behaviour itself; Claims 1a-1c do that.

The header at `Dockerfile:4-6` carries exactly those three clauses (quoted in Claims 1a-1c). `git show --stat 577bef7` shows `devcontainer-config/Dockerfile | 3 +`.

**Evidence:** `devcontainer-config/Dockerfile:4-6`, `git show --stat 577bef7`

---

## Claim 8: "verified by running bats 1.8.2: only --jobs N>1 across files needs it; --jobs 1 and --no-parallelize-across-files run without it" (577bef7)

**Location:** commit 577bef7 message body, A2 paragraph
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers bats 1.8.2 without `parallel`, with "across files" read as "without `--no-parallelize-across-files`". Does not establish that a one-file `--jobs 2` run succeeds; it aborts too, consistent with the flag-based reading.

Probe exits: `--jobs 1` → 0, `--jobs 2 --no-parallelize-across-files` → 0, `--jobs 2` (1 or 2 files) → 1.

**Evidence:** `docs/reviews/execution-logs/q086-bats-jobs-probe-final.log`, `/usr/libexec/bats-core/bats-exec-suite:99-104`

---

## Claim 9: "seven override-log rows for the declined findings (A2, C1-C6)" and "Did not amend 1ef3090" (577bef7)

**Location:** commit 577bef7 message body and Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the override-log rows added by 577bef7 and 1ef3090's presence as an ancestor. Does not establish the content accuracy of each row (see Claim 13).

`git show 577bef7 -- docs/reviews/override-log.md` adds exactly seven `review/q086` rows, with finding prefixes `A2:`, `C1:`, `C2:`, `C3:`, `C4:`, `C5:`, `C6:`. `git merge-base --is-ancestor 1ef3090 ed28f76` succeeds.

**Evidence:** `docs/reviews/override-log.md:81-87`

---

## Claim 10: "the list's older gaps (dnsmasq-base, uv, poppler-utils, JDK, Rust) are deferred as C6" (577bef7 Notes)

**Location:** commit 577bef7 message, Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers two things: the header list still omits those five, and row C6 records them. Does not establish that the five are the list's only gaps.

The header's local-change bullets are `decision 015` (bats, ripgrep, shellcheck), `Q-086` (parallel), and `decision 016` (egress profiles) (`Dockerfile:3-8`). None names dnsmasq-base, uv, poppler-utils, a JDK or Rust. Row `override-log.md:87` names all five.

**Evidence:** `devcontainer-config/Dockerfile:1-9`, `docs/reviews/override-log.md:87`

---

## Claim 11: "the image build is unchanged apart from the layer text" (577bef7 Live-verified trailer)

**Location:** commit 577bef7 message, Live-verified trailer
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the fact that the 577bef7 Dockerfile delta is comment-only. Does not re-open the settled override (B1).

Settled finding B1 (`docs/reviews/override-log.md:80`); no new evidence. A `#` comment line enters no layer. The build is fully unchanged; only the file hash and the re-bless change.

**Evidence:** `devcontainer-config/Dockerfile:4-6`, `docs/reviews/override-log.md:80`

---

## Claim 12: ed28f76 message — "override-log rows C3 and C6 now cite … (base apt RUN :22-46, header list :1-9)"; "B1 … acknowledged with an override-log row"; "Adds the iteration-2 fact-check report and probe log, and updates the rubric to iteration 2"; "all critics gated off on the comment-only iteration-2 delta"

**Location:** commit ed28f76 message body and Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers every factual clause of the ed28f76 message. Does not establish the iteration-2 report's own accuracy.

- Row C3 now reads `devcontainer-config/Dockerfile:22-46`, base apt RUN (`override-log.md:84`).
- Row C6 now reads `devcontainer-config/Dockerfile:1-9` (`override-log.md:87`). These ranges match the file (Claims 1c and 10).
- The B1 row is at `override-log.md:80`.
- `git show --stat ed28f76` lists `q086-bats-jobs-probe-iter2.log`, `q086-code-fact-check-report-iter2.md`, `override-log.md` (+3/-2), and `q086-code-review-rubric-2026-09-28.md` (16 lines changed).
- The rubric's Skipped table lists api-consistency (both iterations) plus security, performance and dependency-upgrade as "Iteration 2 only". That is every critic.

**Evidence:** `docs/reviews/override-log.md:80,84,87`, `docs/reviews/q086-code-review-rubric-2026-09-28.md` (Skipped Core Critics table), `git show --stat ed28f76`

---

## Claim 13: the `review/q086` override-log rows' cited locations resolve at ed28f76

**Location:** `docs/reviews/override-log.md:80-87`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every `path:line` and symbol cited in the eight rows. Does not re-adjudicate the deferred or won't-fix decisions.

| Row | Cited location | What it is at ed28f76 |
|---|---|---|
| C2 | `bats-exec-suite:420` | `parallel --keep-order --jobs "$num_jobs" ... 2>&1`, with no `--will-cite` (quoted in Claim 1a) |
| C3 | `Dockerfile:22-46` | the base apt RUN (Claim 2) |
| C4 | `Dockerfile:43` | `  parallel \` |
| C5 | `bats-exec-file:294-296` | `if [[ "$num_jobs" != 1 && "${BATS_NO_PARALLELIZE_WITHIN_FILE-False}" == False ]]; then … bats_run_tests_in_parallel …` |
| C5 | `install.sh` `procs_in_checkout` | `devcontainer-config/install.sh:1165: procs_in_checkout() {` |
| C6 | `Dockerfile:1-9` | the header block |

Rows A2, B1 and C1 cite commits rather than lines; 1ef3090 and 577bef7 both exist on the branch.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:420`, `/usr/libexec/bats-core/bats-exec-file:294-296`, `devcontainer-config/Dockerfile:1-9`, `devcontainer-config/Dockerfile:22-46`, `devcontainer-config/install.sh:1165`

---

## Claim 14: row C2's "`run-tests.sh` already pins `C.UTF-8` when the locale is missing" (rubric C2 text)

**Location:** `docs/reviews/q086-code-review-rubric-2026-09-28.md` (Consider table, C2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the pin in `scripts/run-tests.sh`. Does not establish whether GNU parallel's Perl locale warnings are silenced by `C.UTF-8`.

```bash
# scripts/run-tests.sh:127-132
ambient_locale="${LC_ALL:-${LANG:-}}"
if ! locale_installed "$ambient_locale"; then
  ...
  locale_installed C.UTF-8 && pinned=C.UTF-8
  ...
  echo "Locale $ambient_locale is not installed; running with LC_ALL=$pinned"
```

(the excerpt elides lines 129 and 131, which were read; the block continues past 132, also read)

**Evidence:** `scripts/run-tests.sh:74-78`, `scripts/run-tests.sh:124-132`

---

## Submitted Claims

## Claim 15: "Without parallel, bats 1.8.2 `--jobs 2` aborts and `--jobs 1` runs, so the package is what the planned `--jobs` needs"

**Submitted by:** rubric ✅ Confirmed Good row 1 (code-fact-check)
**Location:** `/usr/libexec/bats-core/bats-exec-suite:100-101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the asserted bats behaviour and the quoted abort string. Does not establish the accuracy of the row's cited execution log (Claim 16).

The quoted string matches `bats-exec-suite:101`: `abort "Cannot execute \"${num_jobs}\" jobs without GNU parallel"`. The final probe shows `--jobs 2` → exit 1 and `--jobs 1` → exit 0.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:99-104`, `docs/reviews/execution-logs/q086-bats-jobs-probe-final.log`

---

## Claim 16: Confirmed Good row 1's evidence — "FC claim 2 (executed, `execution-logs/q086-bats-jobs-probe.log`)"

**Submitted by:** rubric ✅ Confirmed Good row 1 (code-fact-check)
**Location:** `docs/reviews/execution-logs/q086-bats-jobs-probe.log`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the cited log contains. Does not change the row's verdict on the fact, which Claim 15 verifies.

The cited log shows the abort but prints the wrong per-step exit code:

```
# docs/reviews/execution-logs/q086-bats-jobs-probe.log (body lines, in order)
=== bats --jobs 2 t.bats
Error: Cannot execute "2" jobs without GNU parallel
exit=0
...
exit-code bats --jobs 2: 1
```

The rubric's own iteration-2 pass note says this log is superseded by `q086-bats-jobs-probe-iter2.log`. The Confirmed Good row still cites the superseded log. It should cite `q086-bats-jobs-probe-iter2.log` or `q086-bats-jobs-probe-final.log`. This fixes the citation only; the fact stands.

**Evidence:** `docs/reviews/execution-logs/q086-bats-jobs-probe.log`, `docs/reviews/q086-code-review-rubric-2026-09-28.md` (iteration-2 pass notes; Confirmed Good row 1)

---

## Claim 17: "`hooks/live-verify-gate.sh:73` enforcement regex includes `Dockerfile`"

**Submitted by:** rubric ✅ Confirmed Good row 2 (code-fact-check)
**Location:** `hooks/live-verify-gate.sh:73`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex membership. Does not establish the gate's comment-only escape behaviour for 577bef7.

```bash
# hooks/live-verify-gate.sh:73
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|...|install\.sh$|egress/)'
```

(the regex is elided mid-line; the full line was read)

**Evidence:** `hooks/live-verify-gate.sh:70-74`

---

## Claim 18: "shipped by install.sh"

**Submitted by:** rubric ✅ Confirmed Good row 2 (code-fact-check)
**Location:** `devcontainer-config/install.sh:110`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers membership in PAYLOAD. Does not establish the copy and bless steps end to end.

```bash
# devcontainer-config/install.sh:110
PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress claude-home)
```

**Evidence:** `devcontainer-config/install.sh:110`

---

## Claim 19: "a changed blessed hash rebuilds the container"

**Submitted by:** rubric ✅ Confirmed Good row 2 (code-fact-check)
**Location:** `devcontainer-config/cc-isolated.sh:705-708`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers three things: the Dockerfile is in `enforcement_files` (it is hashed), and a mismatched `/etc/cc-config-hash` triggers `--remove-existing-container`. Does not establish whether the rebuild reuses cached apt layers, or behaviour when `devcontainer exec` fails.

```bash
# devcontainer-config/cc-isolated.sh:705-708
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

`enforcement_files()` echoes `"Dockerfile"` (`cc-isolated.sh:130`). `container_config_matches` compares `/etc/cc-config-hash` against `CC_CONFIG_HASH` (`cc-isolated.sh:420-424`).

**Evidence:** `devcontainer-config/cc-isolated.sh:126-130`, `devcontainer-config/cc-isolated.sh:420-424`, `devcontainer-config/cc-isolated.sh:643-644`, `devcontainer-config/cc-isolated.sh:705-708`

---

## Claim 20: rubric composition-check / A1 locations `Dockerfile:1-6` + `:40`

**Location:** `docs/reviews/q086-code-review-rubric-2026-09-28.md` (A1 row; Composition check)
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the line numbers as they stand at ed28f76. Does not fault the iteration-1 record, which was correct at 1ef3090.

These were the iteration-1 (1ef3090) positions. At ed28f76 the header is `:1-9` and `parallel` is at `:43` (`Dockerfile:43` — `  parallel \`). The B2/B3 fixes updated the override-log rows but not these rubric cells. The rubric is a historical iteration record, so this matters little. If the final rubric re-cites these locations, it should use `:1-9` / `:43`.

**Evidence:** `devcontainer-config/Dockerfile:1-9`, `devcontainer-config/Dockerfile:43`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 3** (commit 1ef3090): "bats --jobs needs GNU parallel" is imprecise. Already settled as A2; no new evidence.
- **Claim 11** (commit 577bef7 trailer): "unchanged apart from the layer text" — a comment enters no layer. Already settled as B1; no new evidence.
- **Claim 16** (rubric Confirmed Good row 1): cites the superseded iteration-1 log, which prints `exit=0` after the abort. Point it at `q086-bats-jobs-probe-iter2.log` or `-final.log`. New, citation-only.
- **Claim 20** (rubric A1 / composition check): `Dockerfile:1-6` / `:40` are iteration-1 positions; at ed28f76 they are `:1-9` / `:43`. New, historical-record only.

### Unverifiable
- **Claim 5** (commit 1ef3090 Notes): parallel package versions for Ubuntu 22.04 and bookworm. Needs network or the rebuilt image. Already settled as C1.

---

## Goal-Alignment Note

- **Answered:** all five requested checks.
  1. Header clauses: Verified. The probe was re-run and a new edge was found: a one-file `--jobs 2` also aborts. It is recorded in the Scope residue, not as a defect.
  2. The RUN structure is valid.
  3. All three commit messages were verdicted; A2, B1 and C1 are unchanged and settled.
  4. Every override-log location resolves at ed28f76.
  5. Both Confirmed Good rows: the facts are Verified, and one evidence citation points at the superseded log.
- **Out of scope:** Image build and package resolution (no Docker, no network). Re-measuring the 742 s full-suite time. The duplicate-commit escalation (1ef3090 / bb9982f), per the brief.
- **Escalate:** None blocking. Claims 16 and 20 are for-author touch-ups to the rubric, not code findings, and there is no red. The 22 claim sections (1a, 1b, 1c, 2-20) break down as: 17 Verified (1a, 1b, 1c, 2, 4, 6, 7, 8, 9, 10, 12, 13, 14, 15, 17, 18, 19), 4 Mostly accurate (3, 11, 16, 20), 1 Unverifiable (5).

<!-- Stage 2.5 merge: appended from q086-code-fact-check-submitted-claims.md (submitting critic: security-reviewer) -->

## Submitted Claims (Stage 2.5 — security-reviewer endorsements)

## Claim 21: "Adding `parallel` does not widen node's root path. The only sudo grant is a bare, env-reset invocation of `init-firewall.sh`, and no root-run script in `devcontainer-config/` invokes `parallel`, `sem` or `niceload`."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/Dockerfile:528`, `devcontainer-config/devcontainer.json:141`
**Type:** Security / configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (sudo listing, word-boundary grep) + static (Dockerfile, devcontainer.json, init-firewall.sh read)
**Scope:** Covers the sudoers grant written at build (Dockerfile:528-529, whole RUN instruction read), the live sudo policy in this sandbox (a build of the current image), every lifecycle command in `devcontainer.json`, and every script in `devcontainer-config/` including `init-firewall.sh` and the programs it runs as root. Does not cover the rebuilt image (cannot be built here), setuid binaries shipped by the base image, or build-time `RUN` steps (these run as root but do not invoke `parallel` either — grep below).
**Legibility-target:** security-reviewer's "What Looks Good" endorsement; the orchestrator's rubric.

Evidence, per root-run path:

1. **Sudoers.** The Dockerfile's only grant (Dockerfile:528, inside the RUN at 519-529):
   ```
   printf '%s\n' 'Defaults:node env_reset, !setenv' 'node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""' > /etc/sudoers.d/node-firewall && \
   ```
   Executed `sudo -n -l` as `node` (uid 1000) in this sandbox: `(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""`, Defaults `env_reset, … secure_path=…, env_reset, !setenv`. `/etc/sudoers.d/` holds only `README` and `node-firewall`. The trailing `""` restricts the grant to a no-argument invocation.
2. **Lifecycle commands.** `devcontainer.json:141`: `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh"`. The only sudo is the bare firewall call; `link-claude-home.sh` runs as `node`. No `postCreate`/`onCreate`/`updateContent`/`initializeCommand` exists (grep). The image has no `ENTRYPOINT`/`CMD` and finishes with `USER node` (Dockerfile:531).
3. **init-firewall.sh's own invocations.** It pins `PATH` to `/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin` (line 38; `CC_FIREWALL_PATH` is stripped by env_reset). Its root-run programs are iptables, ipset, dig, curl, runuser, dnsmasq and `cc-sni-proxy.py` (comment at lines 32-33, `SNI_PROXY_BIN` at 619). `rg -wn "parallel|sem|niceload"` over `init-firewall.sh cc-sni-proxy.py link-claude-home.sh devcontainer.json install.sh cc-*.sh` returned no matches (rc=1). The Dockerfile's only `parallel` hits are the header comment (line 4) and the package list (line 43).

`parallel` lands in `/usr/bin` (root-owned). Nothing runs it as root, and sudo's env_reset strips `$PARALLEL`, so node's config cannot reach a root process. The claim holds for the current source. The rebuilt image's sudoers is produced by the same unchanged line, so the claim should carry over, but that could not be observed here.

**Evidence:** `devcontainer-config/Dockerfile:502-531`, `devcontainer-config/devcontainer.json:141-142`, `devcontainer-config/init-firewall.sh:25-38,619`, `sudo -n -l` output, `ls /etc/sudoers.d/`

---

## Claim 22: "The capabilities `parallel` gives node (spawning commands, remote exec over ssh, config from `$PARALLEL`/`~/.parallel`) were already available to node through binaries in the current image."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/Dockerfile:43`
**Type:** Security / capability equivalence
**Verdict:** Mostly accurate
**Confidence:** High (for the current image); rebuilt image not testable
**Verification mode:** executed (`command -v`, `perl -e system`, `ssh -V`, `dpkg -S`, run as `node` in this sandbox)
**Scope:** Covers the binaries on node's PATH in the current image (the sandbox is a build of it). Does not cover the rebuilt image. Does not check whether egress rules permit any ssh destination, which bounds the practical reach of ssh for both `ssh` and `parallel`.
**Legibility-target:** security-reviewer's "What Looks Good" endorsement; the orchestrator's rubric.

Executed as `uid=1000(node)`:

- `command -v`: `perl` → `/usr/bin/perl` (perl-base), `ssh` → `/usr/bin/ssh` (openssh-client, `OpenSSH_9.2p1 Debian-2+deb12u10`), `xargs` → `/usr/bin/xargs` (findutils), `bash`, `sh`, `nohup` and `setsid` are all present. `parallel`, `sem` and `niceload` are MISSING, as the shared block expects.
- `timeout 5 perl -e 'system("true")'` → `perl system ok`. GNU parallel is a Perl script, so every command it can spawn, node can already spawn through the same interpreter. Concurrency is already available through `xargs -P` and bash `&`, and remote exec through `/usr/bin/ssh` directly.
- `openssh-client` is not in the Dockerfile's own apt list (grep for `openssh`/`ssh-client` found nothing), so it comes from the `node:22` base image. It is still "in the current image", as the claim says.

Why this is Mostly accurate rather than Verified: the "config from `$PARALLEL`/`~/.parallel`" part is equivalent in kind, not literally "already available". No existing binary reads those paths. The relevant fact is that node already controls equivalent inputs (`~/.bashrc`, `BASH_ENV`, `PERL5OPT`, `~/.ssh/config`, all node-writable or node-settable), and a node-owned `~/.parallel` only affects `parallel` runs by node (Claim 21: none run as root). Suggested tightening: "…config from `$PARALLEL`/`~/.parallel` only influences node's own runs, as node-controlled `~/.bashrc`/`PERL5OPT`/`~/.ssh/config` already do." `~/.ssh` does not exist in the sandbox, which does not affect the capability.

**Evidence:** executed output above; `devcontainer-config/Dockerfile:14` (`FROM node:22`), `:20-46` (apt RUN, read in full)

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 22** (`devcontainer-config/Dockerfile:43`): the spawn/ssh parts are verified. The `$PARALLEL`/`~/.parallel` config part is equivalent in kind, not literally pre-existing, so reword it to say it only affects node's own runs.

### Unverifiable
- None. Both claims were checked against the current image. The rebuilt image needs a host check (it cannot be built here), but neither verdict depends on it beyond the unchanged sudoers line.

---

## Goal-Alignment Note

- **Answered:** both submitted security-reviewer endorsements were verdicted as claims 21-22. Claim 21 is Verified: the one sudo grant is bare, env-reset `init-firewall.sh`, and no root-run path invokes `parallel`/`sem`/`niceload`. Claim 22 is Mostly accurate: the config sub-clause is overstated as "already available".
- **Out of scope:** no fresh claims were harvested from the diff. The settled findings (A2, B1, C1-C6) were not revisited. Base-image setuid binaries and egress reachability over ssh were not checked.
- **Escalate:** none. Rebuilt-image behaviour remains a host check, consistent with C1/C3.

