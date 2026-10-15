Commit: dce5b039

# API Consistency Review: Q-089 unit A (host-only tools get their own trust manifest)

**Scope:** `git diff 4ab9a51f dce5b039` (`devcontainer-config/{cc-isolated,cc-push,install}.sh`, `test/cc-isolated-functions.bats`, `test/cc-push.bats`). Files read as of dce5b039. Unit B (6e00137b: gate trailer, `guides/devcontainer-setup.md`, decision log row 71) was read as sibling context only.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit dce5b039, 27 claims: 19 verified, 6 mostly accurate, 1 stale)
**Probes:** `timeout 30` runs of the dce5b039 scripts in `mktemp -d` dir `/home/node/.claude/jobs/00bcf178/tmp/api-q089a.ksriaC/`, with `HOME` and `CLAUDE_DEVC_CONFIG_DIR` pointed inside it. Nothing touched the real config dir, and no process was left running.

## Baseline Conventions

The consumer-facing surfaces here are two CLIs (`cc-isolated`, `cc-push`), the on-disk config dir layout, and the shell function names that tests and the unit-B gate import by sourcing `cc-isolated.sh`.

- **Exit codes** (decision log #58, restated in both headers: `cc-isolated.sh:19-31`, `cc-push.sh:29-34`): 0 success, 1 error or refusal, 2 bad usage. `cc-push` adds that `-h, --help` prints "this text" (`cc-push.sh:26`), via `usage; exit 0` (`cc-push.sh:406`).
- **Error lines**: both tools start an error line with `ERROR: ` on stderr. In cc-isolated it is inline `echo "ERROR: …" >&2` (`check_manifest` `:272`, `:279`; `main` `:649`, `:656`, `:670`). In cc-push it goes through `die()`/`usage_die()`, which print `ERROR: %s` (`cc-push.sh:203-212`). After the ERROR line come indented remedy lines, and the command to run sits on its own line indented four spaces (`check_manifest` `:280-282`).
- **Config dir files**: `<content>.sha256` beside each other: `manifest.sha256` (`manifest_path`, `:76`) and `verified-live.sha256` (`verified_path`, `:80`).
- **Function names**: `<noun>_path` names the file by what it holds (`manifest_path`, `verified_path`), `<set>_files` lists a hashed set (`enforcement_files`), `compute_<thing>` builds one (`compute_manifest`), and `check_manifest` gates on it. Everything named `verif*` is about the *live probe* receipt: `verified_path`, `verified_hash`, `is_verified_live`, `record_verified_live` (`:80-116`).
- **Globals**: script-level variables are UPPER_SNAKE (`CC_ISOLATED_DIR`, `CC_PUSH_DIR`, `GIT_EXIT_SCAN_*` in `cc-exit-scan.sh`). Locals are lower-case.
- **`--bless` / `--list` pairing**: `--bless` reports what it wrote (the manifest, its entry count, the blessed hash and the verified-live state, `:250-265`), and `--list` reads the same state back (`:417-441`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `host_tool_files` | function | `enforcement_files` | `devcontainer-config/cc-isolated.sh:128` | Consistent: `<set>_files` |
| `host_tools_path` | function | `manifest_path`, `verified_path`, `projects_dir` | `cc-isolated.sh:72-82` | Minor: the siblings name the file by what it holds, and this file holds a *manifest* of host tools. It also switches `host_tool` to `host_tools` within one family (Finding 6) |
| `compute_host_tools_manifest` | function | `compute_manifest` | `cc-isolated.sh:153` | Consistent |
| `verify_host_tools` | function | `check_manifest`; and the `verif*` family `is_verified_live`, `verified_hash`, `record_verified_live` | `cc-isolated.sh:96-116`, `:268` | Minor: the hash gate is `check_`, and `verif*` already means live-probe verification (Finding 6) |
| `host-tools.sha256` | on-disk file | `manifest.sha256`, `verified-live.sha256` | `cc-isolated.sh:76-82` | Consistent: kebab-case `<content>.sha256` beside the others |
| `CC_ISOLATED_DIR` | global | `CC_PUSH_DIR` (added in the same diff), `GIT_EXIT_SCAN_CONTAINER_WS` | `cc-exit-scan.sh:119-795` | Consistent |
| `HOST_TOOLS_ERR` / `host_tools_err` | global (one per script) | each other; `CC_PUSH_DIR` | `cc-isolated.sh:623`, `cc-push.sh:176` | Informational: the same role is spelled two ways in two scripts. Each script is internally fine, since cc-push's is used once at top level |
| `ERROR: … — refusing to run the session-exit scan's code.` | error message | `ERROR: installed config changed since last bless — refusing to build/launch.` | `cc-isolated.sh:279` | Consistent: same `ERROR: <what> — refusing to <what>` shape |
| `cc-push: refusing to run: …` | error message | `ERROR: %s` (`die`, `usage_die`) | `cc-push.sh:203-212` | Inconsistent prefix (Finding 3) |
| `… changed since the last bless` | error message | `… changed since last bless` | `cc-isolated.sh:279` | Consistent (the wording differs by one article) |
| `no host-tool manifest at $m (…)` | error message | `ERROR: no blessed manifest at $manifest` | `cc-isolated.sh:272` | Consistent wording. The ERROR prefix is added by each caller |

## Findings

#### 1. cc-push's refusal runs before argument parsing, so `--help` and bad usage exit 1, which the header contract and cc-isolated both contradict

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-push.sh:175-178` (vs `:26`, `:29-34`, `:406`; and `cc-isolated.sh:654-661`)
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** a script or person calling `cc-push --help` / `cc-push --bogus` and reading the exit status the header documents

Evidence (probe, cc-push.sh tampered after a bless):
```
--- cc-push bad flag, cc-push tampered
cc-push: refusing to run: …/cfg/cc-push.sh changed since the last bless
rc=1
--- cc-push --help, tampered
cc-push: refusing to run: …/cfg/cc-push.sh changed since the last bless
rc=1
```
The header promises `-h, --help       this text.` and `2 bad usage (an unknown flag, a flag without its value, two checkouts).` The added test also asserts the 1 for `--help` (`test/cc-push.bats:370-371`: `run bash "$d/cc-push.sh" --help` / `[ "$status" -eq 1 ]`). The sibling entry point does the opposite. In cc-isolated the refusal at `:661` comes after the parse loop, so `--help` gives rc 0 and `--bogus` gives rc 2 there (fact-check Claim 11b, `$L/probe.out`). The two tools share one check, `verify_host_tools`, byte for byte, but they rank refusal against usage differently. There is a reason for cc-push's order: its `usage()` and parser are in the file being checked, so running them would run the unverified file. Reading cc-push's own header, though, is the code that has to be trusted at that point anyway, since bash has already parsed the script up to line 176. Whatever the reason, the header never states the exception.

**Recommendation:** Keep the order, which is defensible because nothing past line 176 should run unverified. Document it in the header's exit-code block: "1 … including a host-tool check that fails before any option is read (`--help` and usage errors included; decision log row 71)". Add one line under "WHAT IT REFUSES BEFORE THE FETCH" too. Alternatively, make cc-isolated match, but answering `--help` first there is harmless and already tested.

#### 2. `--list` (the one diagnostic left open during a refusal) does not report host-tool state, and `--bless` does not report writing it

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-isolated.sh:417-441` (`list_projects`, unchanged), `:250-265` (`bless_manifest`)
**Move:** 7 (asymmetry: write without read)
**Confidence:** High
**Legibility-target:** the user whose launch was just refused, running `cc-isolated --list` to see what state they are in

Evidence (probe, cc-exit-scan.sh tampered after a bless):
```
--- list under tamper
Blessed config 09cca9576c8e1a18 — verified live: NO (run: cc-isolated --probe-only <repo>)

No projects registered (all run with the base egress profile).
rc=0
```
`bless_manifest` gained `compute_host_tools_manifest > "$(host_tools_path)"` but goes on printing only `Blessed $(manifest_path) ($(wc -l < "$(manifest_path)") entries):` and its contents. The refusal path exempts `--list` (`:661`: `[ "$action" != "list" ]`), and `--list` is the documented status view: `cc-isolated --list   # registered projects, blessed config, verified?` (`:15`). That makes it the command a refused user reaches for, and on a verified config it would read "verified live: yes" while every launch is refused. Before this diff the bless/list pair reported the same state symmetrically.

**Recommendation:** In `list_projects`, add one line: `Host tools: ok`, or `Host tools: <HOST_TOOLS_ERR> (re-bless after review)`. `HOST_TOOLS_ERR` is already computed at load time. In `bless_manifest`, add `Blessed $(host_tools_path) (3 entries)`. Both are additive to human-readable output and break no consumer. No test parses `--list` beyond the hash line; `grep -rn "\-\-list" test/` confirms which ones read it.

#### 3. cc-push's refusal line uses a `cc-push:` prefix where every other cc-push error uses `ERROR:`

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-push.sh:177`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** a user scanning stderr (or a wrapper grepping `^ERROR:`) for cc-push failures

Precedent: `printf 'ERROR: %s\n' "$*" | vis >&2` used in `devcontainer-config/cc-push.sh:203-212` (`die`, `usage_die`); `echo "ERROR: …" >&2` used in `devcontainer-config/cc-isolated.sh:662` for the same condition

Evidence: `echo "cc-push: refusing to run: $host_tools_err" >&2`. In this diff the same `verify_host_tools` message reaches the user as `ERROR: <msg> — refusing to run the session-exit scan's code.` from the launcher, but as `cc-push: refusing to run: <msg>` from cc-push. `die` is defined after line 177, which explains why it is not called here. It does not explain dropping the prefix.

**Recommendation:** `echo "ERROR: refusing to run: $host_tools_err" >&2`, plus a remedy line in the launcher's style (`  Review … then:` / `    cc-isolated --bless`), so the two refusals read alike. The test at `test/cc-push.bats:365` matches `*"refusing to run"*`, so it still passes.

#### 4. A failed `--bless` now half-commits: host-tools.sha256 is re-blessed before the boundary manifest fails; a missing host tool gives a bare sha256sum error

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:209-213`, `:252`
**Move:** 4 (error consistency), 9 (safety semantics of a write)
**Confidence:** High
**Legibility-target:** the user running `--bless` (or install.sh, which runs it) who sees exit 1 and assumes nothing was blessed

Evidence (probes):
```
# host tool missing
rc=1
sha256sum: cc-gitdir.sh: No such file or directory
host-tools.sha256: (2 lines: cc-exit-scan.sh, cc-push.sh)
# boundary file missing (after restoring the host tool)
ERROR: enforcement file missing: cc-sni-proxy.py
rc=1
  0 …/manifest.sha256
  3 …/host-tools.sha256   (freshly re-blessed)
```
`compute_manifest` checks each file and prints `ERROR: enforcement file missing: $f` (`:172`). `compute_host_tools_manifest` passes the list straight to `sha256sum`. Because the host-tool manifest is written first, a bless that exits 1 on a boundary problem has already re-blessed the host tools. Both outcomes fail closed: a partial `host-tools.sha256` refuses the missing tool, and the empty `manifest.sha256` (truncated by the `>` redirection, which is pre-existing behaviour) fails `check_manifest`. So this is a contract-legibility issue, not a hole.

**Recommendation:** Give `compute_host_tools_manifest` the same per-file `ERROR: host tool missing: $f` guard. Compute both manifests into variables or temp files before writing either, so a failed `--bless` changes nothing. The atomicity part is optional, but it makes "exit 1 = nothing blessed" true.

#### 5. Refusal text does not fit every path that prints it: "no rebuild or probe is needed" on a missing manifest, and "review cc-exit-scan.sh, cc-gitdir.sh" before a bless that also blesses cc-push.sh

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:661-667`
**Move:** 4 (error messages helpful and consistent)
**Confidence:** High
**Legibility-target:** the user following the printed remedy

Evidence:
```
echo "  Review the host tools in $CC_ISOLATED_DIR (cc-exit-scan.sh, cc-gitdir.sh), then:" >&2
echo "    cc-isolated --bless" >&2
echo "  A host-tool change does not alter the blessed config: no rebuild or probe is needed." >&2
```
The fact-check (Claim 12, mostly accurate) already notes that the last line also prints for `no host-tool manifest at …`, where nothing has changed. That is the first-run case after an upgrade that copied files without install.sh. The second line asks for a review of two files, but `bless_manifest` hashes all of `host_tool_files`, so a changed `cc-push.sh` gets blessed by the same command without being named. cc-push.sh does not stop a launch on its own (probe: with only cc-push.sh tampered, `--probe-only` went on to the `devcontainer CLI not found` check). The existing `check_manifest` remedy points at the whole dir (`diff -r $(config_dir) …`), so the narrower list is a regression in what the remedy covers.

**Recommendation:** Name all three (`$(host_tool_files | paste -sd, -)`), or say "the host tools (cc-exit-scan.sh, cc-gitdir.sh, cc-push.sh: --bless blesses all three)". Print the "no rebuild or probe" line only when `HOST_TOOLS_ERR` is a "changed since" message, or reword it to "Re-blessing host tools does not alter the blessed config: …", which is true in both cases.

#### 6. `verify_host_tools` and `host_tools_path` break the naming grain of the functions they sit beside

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:199-223` (and the copy at `cc-push.sh:144`)
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** a future editor of cc-isolated.sh, and the unit-B gate and tests that source it by name

Precedent: `check_manifest` (hash gate) and `manifest_path`/`verified_path` (file named by content) used in `devcontainer-config/cc-isolated.sh:76-82`, `:268`; `verif*` = live-probe receipt in `is_verified_live`, `verified_hash`, `record_verified_live`, `verified_path` (`cc-isolated.sh:80-116`)

Evidence: `host_tool_files() {`, `host_tools_path() {`, `verify_host_tools() {`. In a file where `verified` means "a live probe passed", `verify_host_tools` reads as a probe of the host tools, which is exactly the thing row 71 says cannot exist. `host_tools_path` reads as the tools' directory, not their manifest. The family also mixes `host_tool_` and `host_tools_`. The functions are new and their only callers are this diff, the gate test in unit B, and `test/cc-isolated-functions.bats`, so renaming them is still cheap.

**Recommendation:** `check_host_tools` (it parallels `check_manifest`) and `host_tools_manifest_path` (it parallels `compute_host_tools_manifest`). Optional; if the names stay, add a comment saying `verify_` here is a hash check, not live verification. The byte-for-byte test (`test/cc-isolated-functions.bats:307-314`) keys on the `# --- verify_host_tools` marker, so a rename has to update the markers, the test, unit B's decision log row 71 and `guides/devcontainer-setup.md`.

#### 7. The user guide and both tool headers are silent on the new refusal and the new file

**Severity:** Minor
**Location:** `guides/cc-isolated-usage.md:44-75` ("What a launch does, in order", "Exit status"), `:236-239` (cc-push exit codes), `:822-826`; `devcontainer-config/cc-isolated.sh:1-31`; `devcontainer-config/cc-push.sh:29-90`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a user reading the usage guide or `--help` to learn why a launch or push refused

Evidence: the guide's launch sequence step 3 says `Check the installed config against the blessed trust manifest (refuses if anything host-side rewrote the boundary)`, with no host-tool step before it. The gate paragraph says `a git commit that includes any manifest-hashed file under devcontainer-config/ is blocked unless its message carries a Live-verified: trailer`, and host tools now carry `Host-tool-tested:`. `git diff --stat 4ab9a51f 6e00137b -- guides/cc-isolated-usage.md` is empty, so unit B does not cover this. Unit B updates `guides/devcontainer-setup.md` (the maintainer guide), not this one. The cc-push header's refusal list ("WHAT IT REFUSES BEFORE THE FETCH") has no entry for its own self-check. The stale `cc-exit-scan.sh`/`cc-gitdir.sh` headers (fact-check Claim 1) belong to the same drift.

**Recommendation:** Add a step 0 to the guide's launch sequence ("check the host tools it sources against `host-tools.sha256`; on a change refuse all but `--bless`/`--list`, and a re-bless is enough") and a sentence on `Host-tool-tested:` to the gate paragraph. Add a one-line refusal entry to the cc-push header (it covers Finding 1 as well) and fix the two stale headers.

#### 8. One-time verified-live reset on upgrade

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:128-137` (three entries removed from `enforcement_files`)
**Move:** 6 (versioning impact)
**Confidence:** High
**Legibility-target:** the user running install.sh with this change

Evidence: the diff removes `echo "cc-exit-scan.sh"`, `echo "cc-gitdir.sh"`, `echo "cc-push.sh"` from `enforcement_files`. `blessed_hash` is derived from `manifest.sha256`, so the first install of this change produces a new blessed hash with no verified-live receipt. The next launch rebuilds and probes even though no boundary file changed in behaviour. That cost is expected, and the change pays it once. It is still the opposite of what row 71 promises for host-tool changes, so a user may be surprised. (Separately, cc-isolated.sh's own edit invalidates the receipt anyway, so the extra cost is nil.)

**Recommendation:** Mention it in the commit or merge note ("the first install re-probes once: the boundary manifest lost three entries"). No code change.

## What Looks Good

- **One check, two copies, pinned.** `verify_host_tools` is duplicated deliberately (cc-push cannot source cc-isolated.sh without running it) and fenced by `# --- verify_host_tools` markers. A test compares the two copies byte for byte (`test/cc-isolated-functions.bats:307-314`). That keeps the two entry points' message wording identical.
- **Exit codes stay inside decision log #58.** Both refusals exit 1 ("an error, including a launch refused…"), and no new code was invented. `--bless`/`--list` exemptions on the launcher match the existing `devcontainer CLI not found` gate's exemptions exactly (`:661` vs `:669`).
- **The launcher's message follows `check_manifest`'s shape**: an `ERROR: <what> — refusing to <what>.` line, an indented review instruction, and the command on its own four-space-indented line.
- **The file layout extends the existing pattern**: `host-tools.sha256` beside `manifest.sha256` and `verified-live.sha256`, all `<content>.sha256` in `config_dir`. `compute_host_tools_manifest` and `host_tool_files` match `compute_manifest` and `enforcement_files`.
- **No silent opt-out.** A dir with `manifest.sha256`, or the config dir itself, without `host-tools.sha256` is refused, not treated as a repo checkout. Both tests cover it.
- **The PAYLOAD-coverage test was widened, not weakened**: the union must cover PAYLOAD, the sets must be disjoint, the host list must be exactly three, and no `COPY` source may be a host tool.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | cc-push refusal precedes parsing: `--help` and bad usage exit 1, against its header and cc-isolated | Inconsistent | `cc-push.sh:175-178` | High |
| 2 | `--list` and `--bless` output omit host-tool state | Inconsistent | `cc-isolated.sh:250-265`, `:417-441` | High |
| 3 | `cc-push:` prefix where cc-push uses `ERROR:` | Inconsistent | `cc-push.sh:177` | High |
| 4 | A failed `--bless` re-blesses host tools first; a missing host tool gives a raw sha256sum error | Minor | `cc-isolated.sh:209-213`, `:252` | High |
| 5 | Refusal remedy text: "no rebuild" on a missing manifest; review list omits cc-push.sh | Minor | `cc-isolated.sh:661-667` | High |
| 6 | `verify_host_tools` / `host_tools_path` names against `check_manifest` / `manifest_path` | Minor | `cc-isolated.sh:199-223` | Medium |
| 7 | Usage guide and tool headers silent on the host-tool refusal and the new trailer | Minor | `guides/cc-isolated-usage.md:44-75,822-826`; both headers | High |
| 8 | First install resets verified-live once | Informational | `cc-isolated.sh:128-137` | High |

## Overall Assessment

The change fits the codebase's conventions well where they matter most. Exit codes stay within decision log #58, the new file and the functions that compute it follow the `<content>.sha256` and `compute_*`/`*_files` patterns, and the launcher's refusal reads like `check_manifest`'s. Nothing breaks an existing consumer: the only surfaces that change behaviour are new refusals, and they fail closed. The issues are about legibility, and all can be fixed in place. Three are real inconsistencies. The two entry points rank the refusal against `--help`/usage differently, and cc-push's header does not say so (1). The refusal leaves `--list` open as the diagnostic, but `--list` cannot see the host-tool state (2). cc-push's refusal drops its `ERROR:` prefix (3). The rest are wording, naming and documentation (4-7), most of them small edits. None needs a design change. Findings 1 and 7 can share one header edit.

## Goal-Alignment Note

The goal is for host-tool changes to stop costing a rebuild and probe while still being checked before they run. Unit A delivers that. A cc-push-only change no longer blocks a launch (probe), a host-tool edit leaves `blessed_hash` alone (test at `test/cc-isolated-functions.bats:253`), and both entry points check before `source`. The findings are about whether a user who hits the new gate can tell *what* happened and *what to do* from the tools' own surfaces (stderr prefix, `--help`, `--list`, the usage guide). The answer is mostly yes: the stderr message is right on the launcher. `--list` and cc-push's header are the gaps. Fixing 1-3 before merge would make the new gate as legible as the `check_manifest` gate it sits beside. 4-8 can follow in this loop or be queued.
