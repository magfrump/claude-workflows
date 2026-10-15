Commit: 53770142

# API Consistency Review — Q-117 cc-verify spike paste (final pass, iteration 2)

**Scope:** `docs/working/spike-cc-verify-q117.md` at 53770142 (`git diff main...HEAD -- docs/working/spike-cc-verify-q117.md`). The script is byte-identical to `spike-q117.final.sh` (checked: the only diff is the shebang line the heredoc adds).
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report-cc-verify-spike.md` (iteration 2, k=3), whose findings were fixed in 53770142. This is the first API-consistency pass: iteration 1 skipped this critic.
**Surface under review:** the paste's CLI (`<checkout>`, `--clean`), its exit codes (0/1/2/130), its line grammar (`RESULT`/`CHECK`/`REFUSED`/`NOTE`/`TEARDOWN`), and the files under `~/cc-verify`. Each is compared with the host tools (`install.sh`, `cc-isolated.sh`, `cc-push.sh`) and with what the DD's proposed `cc-verify` host tool (candidate [5]) would need.

Executed in my own scratch copy of the stub harness (`/home/node/.claude/jobs/00bcf178/tmp/apic.C7yZ/`, a copy of `t1/` plus the final script). Nothing outside that directory was touched. No process is left running.

## Baseline Conventions

- **Exit status, decision log row 58** (`docs/decisions/log.md:81`): every host tool uses install.sh's codes. 0 means success. 1 means an error, or a prompt the user declined, including Ctrl-C at the prompt. 2 means bad usage. A tool may add its own codes above these: `cc-isolated` adds 3 (the exit scan found a change) and 4 (the scan could not finish). `cc-push` maps everything else onto these codes: 130 becomes `ERROR: cc-push was interrupted.` with exit 1, and any other status becomes `ERROR: cc-push stopped on an unexpected failure (status $rc).` with exit 1 (`cc-push.sh:590-601`, "the exit codes stay 0, 1 and 2"). Each tool documents its codes in its `--help` (`install.sh:97-98`, `cc-push.sh:28-34`, `cc-isolated.sh:19-30`).
- **Argument parsing:** a `while/case` loop. `-h|--help` prints usage and exits 0. An unknown flag prints `ERROR: unknown flag: …`, then the usage, then exits 2 (`cc-isolated.sh:733-751`, `cc-push.sh:241-246` `usage_die`, `install.sh:1300-1308`). A missing workspace defaults to the checkout containing `$PWD` (`cc-isolated.sh:8`, `cc-push.sh:9`).
- **Refusal style:** `ERROR: <what>` on stderr, sometimes with indented continuation lines and a statement of state: install.sh says "Nothing was installed." / "Nothing was staged or installed." (`install.sh:186-189, 1323-1327`). `cc-push`'s `die` also passes the message through `vis`.
- **Informational lines:** `NOTE: <text>`, with a colon (`cc-isolated.sh:807, 873`; `install.sh:1232, 1243`). Warnings use `WARNING: <text>` (`cc-isolated.sh:778`).
- **Env names:** `CLAUDE_DEVC_CONFIG_DIR` (default `~/.config/claude-devcontainer`) and `CLAUDE_DEVC_BIN_DIR` (default `~/.local/bin`), both honoured by install.sh (`install.sh:1310-1311`). The launcher honours the first (`cc-isolated.sh:68-70`). Tool-private state is under XDG with a `CC_*` override: `CC_PUSH_CLONES_DIR`, defaulting to `$XDG_DATA_HOME/cc-isolated/clones` (`cc-push.sh:18-20`).
- **Verdict-line grammar** (the nearest precedent, a paste-back script, not a host tool): `RESULT <id> pass|FAIL|SKIP …` (`feat/q125-cc-isolated-sandbox:docs/working/live-check-q125.sh:8, 22`). The user pastes back "every RESULT line" (`docs/working/questions-archive.md:2532`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `<checkout>` (required positional) | CLI arg | `cc-isolated [WS]`, `cc-push [checkout]` (both optional, default `$PWD`'s repo) | `devcontainer-config/cc-isolated.sh:7-8`, `cc-push.sh:7-9` | Acceptable for a paste (explicit is safer here). A tool should default it like its siblings. |
| `--clean` | CLI flag | `--bless`, `--probe-only`, `--register`, `--list` (action flags) | `devcontainer-config/cc-isolated.sh:736-740` | Consistent shape (a bare action flag). New verb; the DD names it (`dd-branch-verify-without-install.md:177`). |
| `--help` / `-h` | CLI flag | present in all three host tools | `install.sh:1304`, `cc-isolated.sh:746`, `cc-push.sh:439` | **Missing.** `--help` is read as a checkout path (F3) |
| exit 1 for usage | exit code | 2 = bad usage | `docs/decisions/log.md:81` (row 58) | **Inconsistent** (F2) |
| exit 2 = no-rotation | exit code | 2 = bad usage; tool-specific codes start at 3 (`cc-isolated` 3/4) | row 58; `cc-isolated.sh:31-33` | **Inconsistent** (F2) |
| exit 130 = interrupted | exit code | 130 → 1 with an `ERROR:` line | `cc-push.sh:597-600` | Inconsistent with cc-push. Acceptable for a paste (F2) |
| `REFUSED: <msg>` | message prefix | `ERROR: <msg>` | `cc-push.sh:236-238`, `cc-isolated.sh:748, 770`, `install.sh:168, 1322` | Inconsistent (F5) |
| `NOTE created during the run …:` | message prefix | `NOTE: <text>` | `cc-isolated.sh:807, 873`, `install.sh:1232` | Minor: no colon (F5) |
| `TEARDOWN: …` / `TEARDOWN INCOMPLETE.` | message prefix | none (closest: `WARNING:`) | `cc-isolated.sh:778` | Internally inconsistent colon use (F5) |
| `CHECK <desc>: ok\|FAIL` | verdict line | `RESULT <id> pass\|FAIL\|SKIP` | `feat/q125-cc-isolated-sandbox:docs/working/live-check-q125.sh:8` | New category. Case mixed with RESULT (F6) |
| `RESULT Q-117 pass\|fail\|no-rotation (…)` | verdict line | `RESULT <id> pass\|FAIL\|SKIP …` | same | Shape consistent; `fail` lowercase against precedent `FAIL` (F6) |
| `RESULT spike-q117 exit=<n>` | verdict line | same | same | A second shape (`exit=<n>`) in the RESULT namespace. Informational (F6) |
| `~/cc-verify/` (root) | state dir | `$XDG_DATA_HOME/cc-isolated/clones` via `CC_PUSH_CLONES_DIR`; `~/.config/claude-devcontainer` via `CLAUDE_DEVC_CONFIG_DIR` | `cc-push.sh:18-20`, `install.sh:1310` | No override variable. The DD chose it for visibility. Informational for a paste (F7) |
| `VERIFY-<TREE8>` | workspace dir | DD: `~/cc-verify/verify-<tree8>` | `docs/working/dd-branch-verify-without-install.md:176, 198` | Deliberate divergence (basename = display name), not noted (F7) |
| `stage-<TREE8>`, `src-<RUN>.git`, `snap-<RUN>-{before,after}`, `run-<RUN>.env`, `log-<RUN>.txt` | state files | none (first tool to keep per-run state) | none (searched `devcontainer-config/*.sh`) | New category. Keyed by RUN or TREE8 on a stated rule: TREE8 for what the launcher keys on. Consistent internally. |
| `CLAUDE_DEVC_CONFIG_DIR` (refused when set) | env | honoured by every host tool | `install.sh:1310`, `cc-isolated.sh:68-70` | Deliberate refusal, documented. A tool would need to honour it (F4) |
| `~/.local/bin` (hard-coded `MAIN_BIN`) | env default | `CLAUDE_DEVC_BIN_DIR` | `install.sh:1311` | Inconsistent: the override is ignored silently (F4) |

## Findings

#### F1. Exit code 2 can also mean a crashed step, not only "pool did not rotate"

**Severity:** Inconsistent
**Location:** `docs/working/spike-cc-verify-q117.md:54` (`set -euo pipefail`), `:183-200` (`on_exit` prints `$?` as is), `:291-292`, `:326-327`, `:362`; contract at `:459-463`
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High (executed)
**Legibility-target:** user reading the exit code / pasting back `RESULT spike-q117 exit=<n>`

Evidence:
```
  *) exit 1 ;;            (verdict block; only `die` and the verdict pick codes)
on_exit() {
  local rc=$? trc=0 crc=0
  ...
  echo "RESULT spike-q117 exit=$rc"
  exit "$rc"
```
```
"${G[@]}" archive --format=tar "$TREE" -- devcontainer-config global-instructions/CLAUDE.md "${HOME_DIRS[@]}" \
  | tar -x -C "$S.raw"
...
git -c core.hooksPath=/dev/null -c core.fsmonitor=false clone -q --no-local --template= -- "$SRCGIT" "$W" </dev/null
```
Doc contract (`:460-463`): "`2`: nothing failed, but the pool did not rotate within 45 min … `1`: anything else".

Several commands have no `|| die`: the archive|tar pipeline, the step-4 clone and `rev-parse`, `cp`, `mkdir`, and step 7's `docker inspect`. Under `set -e` their own exit status reaches `on_exit` unchanged. I ran it with a fake `tar` that exits 2, GNU tar's fatal-error code. The run stopped at step 2, printed no `REFUSED:` line, and ended `RESULT spike-q117 exit=2` with process status 2. That is the documented code for "nothing failed, rerun later". A git failure at step 4 would give 128, which the contract does not list. `cc-push` closes exactly this gap: its main runs in a subshell, and any status outside 0/1/2 becomes 1 with an `ERROR: … unexpected failure (status $rc)` line (`cc-push.sh:590-601`). The consumer harm is limited, because a real no-rotation also prints `RESULT Q-117 no-rotation` and the user pastes RESULT lines. Still, the exit code alone is not trustworthy, and the doc says it is.

**Recommendation:** In `on_exit`, map any `rc` other than 0, 1, 2 or 130 to 1, and print a line such as `REFUSED: step failed unexpectedly (status $rc)`. Exit 2 should come only from the verdict's `no-rotation` branch: track that with a flag set there, and let any other 2 fall to 1. Alternatively, put `|| die` on the unguarded commands. Either way, the documented table becomes closed.

#### F2. The exit-code set reuses row 58's "2 = bad usage" for a verdict and gives usage errors 1

**Severity:** Inconsistent (Minor for a one-off paste; binding for a `cc-verify` tool)
**Location:** `docs/working/spike-cc-verify-q117.md:222` (usage → `die` → 1), `:401-404` (no-rotation → 2), `:244` (`trap 'exit 130' INT TERM HUP`), contract `:459-463`
**Move:** 4 (error consistency), 6 (versioning: what the tool would inherit)
**Confidence:** High
**Legibility-target:** whoever turns the paste into `cc-verify` (DD candidate [5])

Precedent: 0/1/2 with 2 = bad usage, tool codes above 2, used in `docs/decisions/log.md:81`, `devcontainer-config/cc-isolated.sh:19-33`, `devcontainer-config/cc-push.sh:28-34, 597-600`

Evidence:
```
[ $# -eq 1 ] || die "usage: bash $V/spike-q117.sh <your host checkout of claude-workflows> | --clean"
...
  no-rotation) echo "The pool did not rotate within 45 min: rerun later (Q-117's rule)."; exit 2 ;;
```
Executed: no arguments → status 1, two arguments → 1, `--help` → 1.

Row 58 exists because `cc-push`'s 2 used to mean "declined" while `install.sh`'s meant "bad arguments". This paste brings back a third meaning for 2 ("rerun later") and moves usage to 1, so the pattern row 58 removed returns. Row 58's own escape hatch shows the consistent shape: `cc-isolated` adds 3 and 4 above the shared codes. Interruption → 130 is defensible for a paste, but `cc-push` explicitly maps 130 to 1 with an `ERROR:` line. A tool would have to choose one deliberately. Row 58 says "Revisit if a caller needs to tell declined from failed", and a distinct interrupt code is the same kind of signal. For the spike itself, the user reads the RESULT lines, so nothing breaks today.

**Recommendation:** For the paste, optionally move no-rotation to 3 and usage to 2 now, so the spike is already in the shape the tool will need: two edits plus the doc table. At minimum, record in the "cc-verify adoption" notes that the tool must use usage=2, no-rotation=3 (or another number above 4), and must decide 130 versus 1 against row 58.

#### F3. No `--help`, and any single argument is taken as the checkout

**Severity:** Minor
**Location:** `docs/working/spike-cc-verify-q117.md:204, 222, 233`
**Move:** 1, 2 (CLI flag conventions)
**Confidence:** High (executed)
**Legibility-target:** user / future tool author

Precedent: `-h|--help) usage; exit 0` and `-*) ERROR: unknown flag … exit 2` used in `devcontainer-config/cc-isolated.sh:746-748`, `devcontainer-config/install.sh:1304-1305`, `devcontainer-config/cc-push.sh:439`

Evidence: `bash spike-q117.sh --help` prints `REFUSED: --help is not inside a git repository.` and exits 1. `--clean` is recognised only as `$1`. `--clean extra` cleans and ignores `extra`. `<checkout> --clean` gives the usage refusal. The paste's last line is fixed, so the user never types these by hand. That keeps the impact Minor. A tool needs the sibling parser: a case loop, `--`, an unknown-flag error, and a help text that states the exit codes, as all three siblings' help texts do.

**Recommendation:** No change needed for the paste. For `cc-verify`, adopt cc-isolated's parser and generate usage from the header comment (`cc-isolated.sh:721-724`).

#### F4. Env overrides: `CLAUDE_DEVC_CONFIG_DIR` is refused, but `CLAUDE_DEVC_BIN_DIR` is ignored silently, so the bin-link CHECK is vacuous for non-default installs

**Severity:** Minor
**Location:** `docs/working/spike-cc-verify-q117.md:60-61, 155, 224, 230-231`; doc claim `:31`
**Move:** 7 (asymmetry), 3
**Confidence:** High (by reading; not executed)
**Legibility-target:** user with a non-default `CLAUDE_DEVC_BIN_DIR`

Precedent: both `CLAUDE_DEVC_CONFIG_DIR` and `CLAUDE_DEVC_BIN_DIR` honoured in `devcontainer-config/install.sh:1310-1311`

Evidence:
```
MAIN_BIN="$HOME/.local/bin"
...
for f in cc-isolated cc-push; do echo "$f -> $(readlink -f "$MAIN_BIN/$f" 2>/dev/null || echo absent)" >> "$d/main"; done
```
The preflight refuses an inherited `CLAUDE_DEVC_CONFIG_DIR` and gives a stated reason (`:224`). A user who installed with `CLAUDE_DEVC_BIN_DIR=~/bin` still passes the preflight, because PATH's `cc-isolated` resolves to the launcher (`:230`). Their snapshot then records `cc-isolated -> absent` before and after, and `CHECK main install untouched: ok` covers no link at all. The doc says the run compares "where `~/.local/bin/cc-isolated` and `cc-push` point" (`:31`). That is literally true but says nothing about this case. The two variables are a pair in install.sh, and the spike treats them asymmetrically.

**Recommendation:** Derive `MAIN_BIN` from the resolved PATH `cc-isolated` (`dirname "$(command -v cc-isolated)"`), or refuse when `CLAUDE_DEVC_BIN_DIR` is set, matching the config-dir rule. A `cc-verify` tool should honour both, as install.sh does, rather than refuse.

#### F5. Message prefixes: `REFUSED:` instead of the host tools' `ERROR:`, and inconsistent colons on `NOTE`/`TEARDOWN`

**Severity:** Minor
**Location:** `docs/working/spike-cc-verify-q117.md:83` (`die`), `:107, 111, 119-122, 132` (`TEARDOWN:`), `:192` (`TEARDOWN INCOMPLETE.`), `:178` (`NOTE created …:`)
**Move:** 2, 4
**Confidence:** High
**Legibility-target:** user scanning output; tool author

Precedent: `ERROR: <msg>` used in `devcontainer-config/cc-push.sh:236-238`, `devcontainer-config/cc-isolated.sh:748, 770`, `devcontainer-config/install.sh:168, 1322`; `NOTE: <text>` used in `devcontainer-config/cc-isolated.sh:807, 873`, `devcontainer-config/install.sh:1232`

Evidence: `die() { printf 'REFUSED: %s\n' "$*" >&2; exit 1; }`; `echo "NOTE created during the run and still present (…):"`; `echo "TEARDOWN: could not remove container $c"` next to `echo "TEARDOWN INCOMPLETE. Fallback: …"`.

`REFUSED:` is defensible in a paste, because the doc's grammar promises that only the script can start a line with it, and `relay` indents everything else. The tool should still say `ERROR:`, as its siblings do. The launcher's own `NOTE: blessed config …` line appears in the same output (relayed, at `:431`), right next to the spike's colon-less `NOTE created …`. Within the script, `TEARDOWN:` and `TEARDOWN INCOMPLETE.` differ. Separately, `die` does not pass through `vis`, unlike `cc-push`'s `die`. Its arguments are script-derived or `%q`-quoted, so this is consistency, not exposure.

**Recommendation:** For the tool: `ERROR:`, `NOTE:`, `WARNING:`. For the paste: optionally make it `NOTE: created during the run …` and `TEARDOWN INCOMPLETE:`. The cost is nil, and a later grep for `^NOTE:` finds both.

#### F6. Verdict casing: `RESULT Q-117 fail` is lowercase, while `CHECK … FAIL` and the Q-125 precedent use `FAIL`; `RESULT spike-q117 exit=<n>` is a second shape

**Severity:** Minor
**Location:** `docs/working/spike-cc-verify-q117.md:392-400` (verdict values `pass|fail|no-rotation`), `:162-176` (`ok|FAIL`), `:199`
**Move:** 2, 7
**Confidence:** High
**Legibility-target:** user pasting back / agent parsing the paste-back

Precedent: `RESULT <id> pass|FAIL|SKIP …` used in `feat/q125-cc-isolated-sandbox:docs/working/live-check-q125.sh:8, 22`

Evidence: `echo "RESULT Q-117 $v (tree $TREE, config $HASH)"` with `v=fail`; `echo "CHECK main install untouched: FAIL"`.

A reader or agent who greps the paste-back for `FAIL` finds failed CHECKs but misses `RESULT Q-117 fail`. The one precedent for paste-back RESULT lines uppercases the failure, and the spike's own CHECK lines do too. `RESULT spike-q117 exit=<n>` puts a key=value status where the precedent has a verdict word. The DD's H0 success criterion asks for "a `RESULT`/`pass` verdict line" (`dd-branch-verify-without-install.md:47`), which the Q-117 line meets.

**Recommendation:** Emit `FAIL` (keep `pass` and `no-rotation`), and update the doc's verdict text. Optionally rename the run line to `RESULT spike-q117 pass|FAIL (exit=<n>)`.

#### F7. Contract text drift: "Not verified #1" still describes the pre-fix image rule

**Severity:** Minor
**Location:** `docs/working/spike-cc-verify-q117.md:513` against code `:127-134` and table `:22, 494`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** user deciding whether the trap can touch their images

Evidence (`:513`): "The trap removes the image the verify container ran (if new and unused), plus any image whose tag contains `verify-<TREE8>`. The second rule assumes the devcontainer CLI tags images after the lower-cased workspace folder."
Code (`:130-132`): `case "$tags" in vsc-verify-"$T8"-*|vsc-verify-"$T8":*) ;; *) continue ;; esac` … `docker image rm "$tags"` (untag by name, no `-f`, only when the id is absent from the before-snapshot).

53770142 narrowed the rule from an unanchored substring that removed the image to an anchored `vsc-verify-<T8>` prefix that only untags. It updated the created table (`:22`) and the trap row (`:494`) but not this paragraph, which is the one a user reads about image safety. The paragraph now overstates what is deleted ("contains", "removes"), which was exactly iteration 2's Incorrect finding (2/3). The code is right; only the description is stale. Also, `:22` writes the tag as `vsc-verify-<TREE8>-…`, but the code also accepts the bare repository `vsc-verify-<T8>:<tag>`.

**Recommendation:** Reword `:513` to: "…plus any tag starting `vsc-verify-<TREE8>` whose image id is new since the before-snapshot (untagged by name, never forced)." Optionally add "or repository `vsc-verify-<TREE8>`" at `:22`.

#### F8. The paste-back list omits the lines that explain an incomplete teardown and the `--clean` output

**Severity:** Minor
**Location:** `docs/working/spike-cc-verify-q117.md:465` against `:107-135, 192, 214-215`
**Move:** 3 (consumer contract: the paste-back is the interface to the agent)
**Confidence:** Medium
**Legibility-target:** user pasting back; agent triaging

Evidence (`:465`): "**What to paste back:** the `RESULT` lines, every `CHECK` line, and the `NOTE` block if one appeared. On a refusal, the `REFUSED:` line."

On an incomplete teardown the run ends `RESULT spike-q117 exit=1`. The lines that say what is left (`TEARDOWN: could not remove volume …`, `TEARDOWN: kept image …`, `TEARDOWN INCOMPLETE. …`) are not on the list. A `--clean` run prints `cleaning run …` and `skipping malformed …` lines with no prefix and no RESULT line, so the list gives the user nothing to paste. The `:414` grammar sentence names `RESULT`, `CHECK` and `REFUSED` as the reserved prefixes. `TEARDOWN` and `NOTE` are also script-only, because `relay` indents all foreign output, but the doc does not say so.

**Recommendation:** Add "every `TEARDOWN` line" to `:465`, plus a sentence for `--clean` ("paste its whole output"). Optionally list `TEARDOWN`/`NOTE` among the reserved prefixes at `:414`.

#### F9. Files under `~/cc-verify` have no override, and the workspace name diverges from the DD's

**Severity:** Informational
**Location:** `docs/working/spike-cc-verify-q117.md:59, 274`; DD `dd-branch-verify-without-install.md:176, 198`
**Move:** 2
**Confidence:** High
**Legibility-target:** tool author

Precedent: tool-private state under `$XDG_DATA_HOME/…` with a `CC_*` override, used in `devcontainer-config/cc-push.sh:18-20` (`CC_PUSH_CLONES_DIR`)

The DD fixed `~/cc-verify` deliberately for visibility (pre-mortem 1), so the home-root location is intended, not an accident. A tool would still be the only host tool without an override variable. The DD spells the clone `~/cc-verify/verify-<tree8>`. The spike uses `VERIFY-<TREE8>` so that its basename equals the display name (`CC_PROJECT_NAME`), which is a sound choice, but the spike doc does not record it as a deviation from the DD. The per-run file names (`stage-`, `src-`, `snap-`, `run-`, `log-`) are internally consistent: keyed by TREE8 where the launcher or teardown derives the name, and by RUN otherwise.

**Recommendation:** For the tool: `CC_VERIFY_DIR` (default `~/cc-verify`), named on the `CC_PUSH_CLONES_DIR` pattern. For the spike: a one-line note that `VERIFY-` is uppercase on purpose.

## What Looks Good

- **Driving main's launcher through its public surface only.** `--register <ws> --profile android` and `--probe-only <ws>` match the documented syntax (`cc-isolated.sh:9-13`). The five `CC_*` variables for `devcontainer exec` are taken from `rebuild_hint`, so the spike adds no private coupling to the launcher.
- **`CLAUDE_DEVC_CONFIG_DIR` used as the existing seam.** The stage is just another config dir, so no new env name is invented. Refusing an inherited value is stated with its reason.
- **`--clean` matches the DD's interface** (`cc-verify --clean`, refuse-until-cleaned). Its name has the bare-action shape of `--bless`, `--list` and `--probe-only`.
- **Closed, self-attesting line grammar.** `relay` indentation means no foreign line can start with a reserved prefix. The forged-RESULT test and my reading of the relay path both hold. `RESULT Q-117 <verdict> (tree …, config …)` carries the tree id and config hash the DD's trailer needs (`Live-verified: <hash> — cc-verify of tree <id>`).
- **Exit 130 holds through a command substitution.** I tested the step-8 shape (`out="$(… | …)" || die`) under a process-group SIGINT. The `exit 130` trap wins over the `|| die`, giving status 130 and `RESULT exit=130`, with no spurious `REFUSED`.
- **Naming of created resources** reuses the launcher's own schemes (`cc-project=<PID>` label, `cc-<PID>-bashhistory|claude-config` volumes) instead of inventing parallel ones.

## Could `cc-verify` adopt this surface unchanged?

Not unchanged. The core can carry over: the action set, the `--clean` semantics, the RESULT/CHECK grammar, the `CLAUDE_DEVC_CONFIG_DIR` seam and the per-run naming. Four things must change to sit beside its siblings:

1. Exit codes: usage → 2, no-rotation above 4, and a closed code set (F1, F2).
2. A real flag parser with `--help` that documents the exit codes (F3).
3. `ERROR:`/`NOTE:` prefixes (F5).
4. Honour `CLAUDE_DEVC_CONFIG_DIR`/`CLAUDE_DEVC_BIN_DIR` rather than refuse or ignore them (F4).

It also needs the DD items the spike does not exercise: the commits-in-clone teardown guard (pre-mortem 1) and a generic `<branch>` argument in place of the pinned `EXPECT_BR`/`BRANCH_PATHS`, which are paste-specific by design.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Unguarded commands leak their own status: tar fatal → `exit=2`, the documented "no-rotation" code (executed) | Inconsistent | `spike-cc-verify-q117.md:183-200, 291-292, 326-327, 362; 459-463` | High |
| F2 | Exit set reuses row 58's 2 for a verdict; usage → 1; 130 against cc-push's 130→1 | Inconsistent (Minor for the paste) | `:222, 244, 401-404, 459-463` | High |
| F3 | No `--help`; any lone arg is a checkout; `--clean` only as `$1` | Minor | `:204, 222, 233` | High |
| F4 | `CLAUDE_DEVC_BIN_DIR` ignored, so the bin-link CHECK is vacuous for non-default installs | Minor | `:61, 155, 224, 230` | High |
| F5 | `REFUSED:` vs `ERROR:`; `NOTE`/`TEARDOWN` colon inconsistency | Minor | `:83, 107-132, 178, 192` | High |
| F6 | `fail` lowercase vs `FAIL` (CHECK lines, Q-125 precedent); `exit=<n>` second RESULT shape | Minor | `:392-400, 162-176, 199` | High |
| F7 | "Not verified #1" still describes the pre-fix image rule ("contains", "removes") | Minor | `:513` vs `:127-134` | High |
| F8 | Paste-back list omits `TEARDOWN` lines and `--clean` output | Minor | `:465, 414` | Medium |
| F9 | `~/cc-verify` has no override; `VERIFY-` vs DD's `verify-` not noted | Informational | `:59, 274` | High |

## Overall Assessment

The paste's surface is internally coherent and safe to run as is. None of these findings blocks the host run, and none reopens an iteration-1 or iteration-2 fix. All the fixes I checked hold, and the 53770142 image-rule fix is correct in code. The one finding with real contract impact is F1: the documented exit-code table is not closed. A crashed step can exit 2, which the doc defines as "nothing failed, rerun later", and I reproduced this in the harness. The RESULT lines still tell the truth, so the user is protected as long as they paste those, as the doc asks. F7 is a stale paragraph left by the last fix, and it is the paragraph that describes image deletion. Both are small edits. The rest are convention gaps against row 58 and the siblings' parser and prefix style. They are acceptable in a one-off paste but must be closed before the paste becomes the `cc-verify` host tool. The author clearly surveyed the launcher's interfaces. The host tools' exit-status and message conventions were not applied, probably because a paste was not treated as a host tool.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved to the path named at the end of this prompt, structured per your role's skill, with a `Commit: 53770142` first line."

Met: this file is at `/workspace/.claude/wt-branch-verify/docs/reviews/api-consistency-review-2026-10-15-cc-verify-spike.md`, its first line is `Commit: 53770142`, and it follows the api-consistency-reviewer structure (baseline, name-pattern audit, findings with precedent lines, what looks good, summary table, overall assessment). Each finding is tagged with Severity, Location, Evidence, Confidence and Legibility-target. Relative to the user goal ("a reviewed, safe one-paste host spike"), F1 and F7 are worth fixing before the paste is handed over. They are cheap and touch the contract the user reads. F2-F6, F8 and F9 can wait for the `cc-verify` tool.
