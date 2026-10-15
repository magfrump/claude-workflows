Commit: f737ba71

# API Consistency Review — Q-089 A1+A2, iteration 3 (fix delta)

**Scope:** `git diff b3b37e16 f737ba71 -- devcontainer-config test` (cc-isolated.sh, cc-push.sh, cc-isolated-functions.bats, cc-push.bats), on branch `feat/q089a2b-cc-push-self-check`
**Date:** 2026-10-14
**Based on:** prior advisory reviews `docs/reviews/api-consistency-review-2026-10-14-q089a1.md` and `-q089a2.md`. This pass had no fact-check report for f737ba71.

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

Probes ran under `timeout` against a `git archive f737ba71` extract, in a `mktemp -d` under `/home/node/.claude/jobs/00bcf178/tmp/`, with `LC_ALL=C` and HOME, XDG_CONFIG_HOME, TMPDIR and CLAUDE_DEVC_CONFIG_DIR all pointed inside it. The layout was an installed copy without `install.sh`, blessed with `--bless`, and each manifest anomaly was then induced in turn. `<P>` below stands for the probe dir.

## Baseline Conventions

- **Refusal header.** A refusal starts with `ERROR: <cause> — refusing to <actions>.`, e.g. `ERROR: installed config changed since last bless — refusing to build/launch.` (`cc-isolated.sh` check_manifest, ~:343). Everything goes to stderr and the exit is 1 (decision #58 exit-code table, in both headers).
- **Continuation layout. There are two precedents.**
  - (a) In check_manifest (~:336-347), guidance lines are flush-left and commands are indented 4: `Something host-side rewrote ... re-bless:` / `    $(bless_cmd)`.
  - (b) In the PROBE FAIL blocks (~:661-680), continuation and guidance lines are indented 2 (`  not the one you blessed. Rebuild with:`) and the command comes from a helper.
- **Bless command.** `bless_cmd` prints `CLAUDE_DEVC_CONFIG_DIR=%q $0 --bless` when the variable is set, otherwise `$0 --bless`. Elsewhere, prose hints use the bare `cc-isolated` (`--list`: `run: cc-isolated --probe-only <repo>`; `--bless`: `Next: cc-isolated --probe-only <repo>`).
- **Multi-reason summaries.** `--list` joins the reasons from verify_host_tools on one line with `; ` (`launches refuse: …; …`, `cc-push refuses: …`).
- **Reason phrasing from verify_host_tools.** Each reason is a single line with the path first: `<path> changed since the last bless`, `<path> is missing or a symlink`, `no host-tool manifest at <path> (…)`, `host-tool manifest <path> is unreadable or malformed: …`.

## Name-Pattern Audit

The delta adds no flags, functions visible to callers, env vars, files or exit codes. `CC_PUSH_DIR` mirrors `CC_ISOLATED_DIR`, which the A2 review already audited. Its new public "names" are message strings, so they are audited as names here.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `ERROR: cc-push refuses to run:` | refusal header | `ERROR: host tools differ from the bless — refusing to launch, probe or register:`, `ERROR: installed config changed since last bless — refusing to build/launch.`, `--list`'s `cc-push refuses: …` | `devcontainer-config/cc-isolated.sh` (~:343, ~:752, ~:513) | Partly consistent. The wording matches `--list`'s `cc-push refuses:`. The header names the tool instead of `<cause> — refusing to <x>`, but it is accurate for every reason, which the launcher's header is not (Finding 2) |
| `host-tool manifest <m> has no single entry for <f>` | error reason | `host-tool manifest <m> is unreadable or malformed: …`, `no host-tool manifest at <m> (…)` | `devcontainer-config/cc-isolated.sh:239-246` | Consistent subject and shape. "no single entry" covers both zero entries and duplicate entries, and is slightly ambiguous (Finding 5) |
| `Review the host tools in <dir>, then re-bless (it prints what changed):` (cc-push) | guidance line | the launcher's identical line, indented 2 | `devcontainer-config/cc-isolated.sh:764` | Same words, different indent (Finding 3) |
| `    CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless` | remedy command | `bless_cmd` → `CLAUDE_DEVC_CONFIG_DIR=%q $0 --bless` | `devcontainer-config/cc-isolated.sh:323-329` | Consistent in shape and quoting (`%q`). The program word differs: bare name vs `$0` (Finding 4) |
| `(re-run install.sh, or review the tools and bless this dir)` | reason parenthetical | `(review them, then run: $(bless_cmd))` in `--list` | `devcontainer-config/cc-isolated.sh:505` | Consistent. With no bare command left in a reason, A2 F1's hazard is gone |

## Findings

#### 1. A manifest-level anomaly appears twice in the launcher refusal, and the second copy is labelled "also changed"

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:761-763` (the line itself predates this delta; the delta adds the empty-manifest path that reaches it)
**Move:** 4 (error consistency) / 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the user reading the launcher's refusal after a manifest is truncated, deleted or corrupted

Evidence (probe, a junk line appended to host-tools.sha256):
```
ERROR: host tools differ from the bless — refusing to launch, probe or register:
  host-tool manifest <P>/cfg/host-tools.sha256 is unreadable or malformed: inspect it before any bless overwrites it
  also changed (cc-push refuses until re-blessed): host-tool manifest <P>/cfg/host-tools.sha256 is unreadable or malformed: inspect it before any bless overwrites it
```
The manifest-missing case behaves the same way: `  also changed (cc-push refuses until re-blessed): no host-tool manifest at <P>/cfg/host-tools.sha256 (re-run install.sh, …)`.

The second verify_host_tools call, for cc-push.sh, repeats every manifest-level reason word for word, and labels the repeat "also changed" when nothing else changed. The other two places that combine these reasons do not do this. `--list` prints `launches refuse:` and `cc-push refuses:` as two distinct verdicts and never says "also". cc-push's own refusal prints the reason once. The delta's empty-manifest path (`[ ! -s "$m" ]`) now reaches this line too. The reader sees two "problems" where there is one, and the label is wrong for this case.

**Recommendation:** Print the `also changed` line only when `push_err` differs from `HOST_TOOLS_ERR`, or only when push_err names cc-push.sh. Either check is one line.

#### 2. The launcher's header says "host tools differ from the bless" for reasons that are not a difference

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:752` (the header predates this delta; the reasons the delta adds make the mismatch more common)
**Move:** 4 (error consistency) / 7 (asymmetry with cc-push)
**Confidence:** High
**Legibility-target:** a user deciding whether a file was tampered with or the manifest is broken

Evidence (probe, the cc-gitdir.sh entry deleted from the manifest):
```
ERROR: host tools differ from the bless — refusing to launch, probe or register:
  host-tool manifest <P>/cfg/host-tools.sha256 has no single entry for cc-gitdir.sh
```
For the same state, cc-push prints `ERROR: cc-push refuses to run:` and makes no claim about the cause.

The delta separates "the manifest is the anomaly" from "a tool changed" on purpose. The manifest comment says so: "say so rather than call every tool changed". The launcher's header still calls every case a difference. That holds for missing, empty, malformed and no-entry manifests, where nothing has been shown to differ. cc-push's header, reworded in A2 iteration 1, is accurate in all of these cases. The two refusals of one check now disagree on whether the header names a cause.

**Recommendation:** Use a cause-neutral header in the launcher, e.g. `ERROR: host-tool check failed — refusing to launch, probe or register:`. That fits the `<cause> — refusing to <x>` baseline and the existing `HOST_TOOLS_ERR` fallback text ("host-tool check failed", ~:716).

#### 3. The two refusals indent the guidance line differently

**Severity:** Minor
**Location:** `devcontainer-config/cc-push.sh:208` vs `devcontainer-config/cc-isolated.sh:764`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** a user who sees both refusals (the launcher's "also changed" line sends them to cc-push)

Precedent: flush-left guidance with a 4-space command, used in `devcontainer-config/cc-isolated.sh` check_manifest (~:343-346). Also 2-space guidance lines, used in `devcontainer-config/cc-isolated.sh` PROBE FAIL blocks (~:661-680).

Evidence (probe):
```
ERROR: cc-push refuses to run:
  host-tool manifest <P>/cfg/host-tools.sha256 has no single entry for cc-gitdir.sh
Review the host tools in <P>/cfg, then re-bless (it prints what changed):
    CLAUDE_DEVC_CONFIG_DIR=<P>/cfg cc-isolated --bless
```
versus the launcher:
```
  host-tool manifest <P>/cfg/host-tools.sha256 has no single entry for cc-gitdir.sh
  Review the host tools in <P>/cfg, then re-bless (it prints what changed):
    CLAUDE_DEVC_CONFIG_DIR=<P>/cfg cfg/cc-isolated.sh --bless
```

The brief describes the layout as shared ("per-line indent in both refusals"). The reasons do now match at 2 spaces. The guidance line uses the same text but is flush-left in cc-push and indented 2 in the launcher. Each follows one of the two existing precedents, so neither is wrong by itself. They are the same refusal for the same check, though, and differ for no stated reason. Because of the flush-left line, cc-push's block reads as reasons followed by a new paragraph. The launcher's reads as a single block.

**Recommendation:** Choose one layout. The launcher's all-indented form is the closer match to the error-plus-indented-detail layout this delta adopts. Indent cc-push's `Review the host tools …` line by 2. No test asserts the indent of either guidance line.

#### 4. The bless command's program word differs: `$0` in the launcher, bare `cc-isolated` in cc-push

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:209` vs `devcontainer-config/cc-isolated.sh:323-329`
**Move:** 2 (naming) / 7 (asymmetry)
**Confidence:** High
**Legibility-target:** a user who copies the remedy command verbatim

Precedent: bare `cc-isolated` in prose hints, used in `devcontainer-config/cc-isolated.sh` (`--list` ~:487 `run: cc-isolated --probe-only <repo>`, `--bless` ~:316 `Next: cc-isolated --probe-only <repo>`). `bless_cmd`'s `$0` is used in `devcontainer-config/cc-isolated.sh:323-329`.

Evidence: cc-push prints `    CLAUDE_DEVC_CONFIG_DIR=<P>/cfg cc-isolated --bless`. The launcher, invoked as `bash cfg/cc-isolated.sh`, prints `    CLAUDE_DEVC_CONFIG_DIR=<P>/cfg cfg/cc-isolated.sh --bless`.

cc-push cannot use `$0` here, because `$0` is cc-push. The bare name follows the existing prose precedent and works on the default install, where install.sh links `~/.local/bin/cc-isolated` (`install.sh:598`). The important part matches: both name the dir with `%q` quoting, which fixes A2 F1. The remaining gap is small. The bare name depends on PATH, and the `cc-isolated` it finds may be a different install from the one in `$CC_PUSH_DIR`. The bless still targets the named dir, since `compute_host_tools_manifest` hashes `config_dir`. A user who copies the command therefore blesses the right files even then. This is recorded, not a defect.

**Recommendation:** None required. Optionally, if `$CC_PUSH_DIR/cc-isolated.sh` exists, print that instead, so the command names the matching launcher.

#### 5. "has no single entry for X" covers two cases a reader may want told apart

**Severity:** Informational (floor; downgraded from Minor because no precedent exists)
**Location:** `devcontainer-config/cc-isolated.sh:259` and `devcontainer-config/cc-push.sh` (shared verify_host_tools block, same line)
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** a user who opens the manifest to fix it

No existing precedent in `devcontainer-config/*.sh` (grepped for `entry`, `duplicate`, `no .* for`).

The awk prints a hash only when `n == 1`, so the message covers both a missing entry and a duplicated one. "no single entry" is accurate for both, but on first reading it can mean "no entry at all". A user with a duplicated line (two blesses concatenated, a bad merge) may look for a missing line, not find one, and be confused. The test covers only the missing case.

**Recommendation:** Optional: say `has no entry, or more than one, for <f>`. The cost is one string in both copies; the parity test keeps them in step.

#### 6. Joining a manifest reason into the launcher's WARNING gives "inspect before any bless" then "re-blessed"

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:773-776`
**Move:** 4 (error tone)
**Confidence:** Medium
**Legibility-target:** the user who sees only the launch-time WARNING

Evidence (probe, the cc-push.sh entry removed): `WARNING: host-tool manifest <P>/cfg/host-tools.sha256 has no single entry for cc-push.sh — do not run cc-push until you have reviewed it and re-blessed.`

For the no-entry case this reads well. In the warning, "it" refers to the reason's subject, so for this reason "it" is the manifest. That is right. For the malformed reason, the composed line would read `… is unreadable or malformed: inspect it before any bless overwrites it — do not run cc-push until you have reviewed it and re-blessed.` That is three "it"s, but the instruction holds together: inspect, then re-bless. In the launcher this case actually never reaches the WARNING. A manifest-level anomaly also fails the launcher's own check and goes to the refusal (Finding 1). So this is about wording only.

**Recommendation:** None required.

## What Looks Good

- **A2 F1 is fixed.** No reason line carries a bare `cc-isolated --bless` any more. Both refusals end with a dir-qualified, `%q`-quoted command on its own 4-space line. That matches `bless_cmd` and check_manifest's command layout, and the cc-push test pins `CLAUDE_DEVC_CONFIG_DIR=$d cc-isolated --bless`.
- **A2 F4 is fixed.** Every reason in cc-push now sits on its own line under the ERROR line. The multi-line reason no longer spills unprefixed lines, and "Review them" became "Review the host tools in <dir>".
- **Reasons are indented the same way in both refusals,** and the reason lines are byte-identical, because the function is shared and pinned by the parity test. A test pins the launcher's per-line indent.
- **Manifest anomalies are now named as such**: empty file, unreadable file, missing or duplicate entry. Previously they showed up as "X changed since the last bless". This matches the existing `is unreadable or malformed` reason, and the user is no longer sent to a bless that would overwrite evidence.
- **No flag, exit-code or stdout/stderr change.** Everything is on stderr, and the refusal exits 1. cc-push's header documents the --help exception (A2 F5's asymmetry stays deliberate and documented).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Manifest-level reason printed twice in the launcher refusal, second copy labelled "also changed" | Minor | `cc-isolated.sh:761-763` | High |
| 2 | Launcher header "host tools differ" is wrong for manifest anomalies; cc-push's header is neutral | Minor | `cc-isolated.sh:752` | High |
| 3 | Guidance line flush-left in cc-push, indented 2 in the launcher | Minor | `cc-push.sh:208` vs `cc-isolated.sh:764` | High |
| 4 | Bless command program word: bare `cc-isolated` vs `$0` | Informational | `cc-push.sh:209` | High |
| 5 | "has no single entry" conflates missing and duplicate entries | Informational | shared verify_host_tools | Medium |
| 6 | WARNING composed with a manifest reason reads awkwardly (unreachable in practice) | Informational | `cc-isolated.sh:773-776` | Medium |

## Overall Assessment

The delta does what it set out to do. Both refusals now share one error-plus-indented-reasons-plus-command layout, the reasons are byte-identical, the remedy names the dir in both, and manifest anomalies are described as manifest anomalies. None of the findings breaks a consumer. There are no flag, exit-code or stream changes. All three Minor findings are message-shape inconsistencies, each fixable in a line or two.

Findings 1 and 2 both live in the launcher's existing refusal code, which this delta did not touch. The delta makes them easier to hit, because its new manifest reasons are exactly the cases where "differ" and "also changed" are wrong. Finding 3 is the one place where the two refusals the brief calls matching still differ.

None of these blocks the merge. Since this is the last iteration, they could go into a follow-up or be accepted as they are.

## Goal-Alignment Note

The user's goal was to review the CLI output and error conventions of cc-isolated and cc-push before merge, with the launcher and cc-push refusals consistent with each other and with existing conventions. This review judged exactly that delta. Each claim about rendered output was checked by a hermetic probe of f737ba71, not inferred from the source. On the axes the delta targets, the two refusals are consistent: header accuracy in cc-push, reason indent, a dir-qualified remedy, and the new anomaly reasons. They are not yet fully consistent on header cause-wording (F2), guidance-line indent (F3) and duplicate reasons (F1). All three are advisory Minor items. This report does not cover security or the correctness of the hashing itself, which belong to the other critics.
