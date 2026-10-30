# Independent review: `fix/cc-isolated-one-workspace`

**Range reviewed:** `5a821383^..009a0503` (iteration-1 fixes, the `--help` fix, the rubric), with the whole unit `5e6e9266..009a0503` read for context · **Reviewer:** independent single agent, no sub-agents (nested agents hang in this session) · **Date:** 2026-10-15 · **Tip:** 009a0503

**Verdict: clean on Must items.** 0 Must Fix, 0 Must Address, 6 Consider. Every claim checked in the commit messages, rubric, `--help` and guide holds against the code; no probe got past the new parsing to bless, register, probe or launch on an unintended workspace or flag.

Evidence lives in `/home/node/.claude/jobs/00bcf178/tmp/one-ws-indep/`: `probe.sh` is a standalone copy of `test/cc-isolated-functions.bats`'s `setup()` (fake config dir, stubbed `devcontainer` that logs its calls, throwaway repos). It reports the exit code, the `--workspace-folder` the stub received, whether the manifest changed, and any registration written. `f7.sh` runs an installed copy with a tampered host tool. `old/` is `git archive 5e6e9266` plus the tip's test file. Every probe ran under `timeout`. No process outlived its call.

---

## 1. Fact-check

| # | Claim (source) | Verdict | Evidence |
|---|---|---|---|
| 1 | `--profile '#' --bless` ran a bless, before this unit too (5a821383, rubric A1, plan F5) | Accurate | On `old/`: `--profile '#' --bless` gave rc=0 and printed the bless output. `--profile '#' B` called `devcontainer up` on B. At the tip, both exit 2 with no devcontainer call |
| 2 | A `--profile` value starting with `#` or `-` is a usage error, exit 2 (5a821383, `--help`, guide) | Accurate | Probes `F5-profile-hash-bless`, `-dash`, `-hashword`, `-twice`: all rc=2, nothing written. bats test 18 passes |
| 3 | The zsh-note hint prints only from the `#` refusals; the two-workspace error names a pasted note or an unquoted space (C6) | Accurate | `pasted_note_error` and `two_workspaces` in `cc-isolated.sh` |
| 4 | `--help` puts each description on its own line; the guide's command reference is a table (A3) | Accurate | `--help` output checked. The table has 14 rows, matching the old block's 14 commands (the rubric's count holds) |
| 5 | The header and table layout is parsed by no test or script (rubric, inline API pass) | Accurate | `rg` outside `docs/` finds those strings only in `cc-isolated.sh` and the guide |
| 6 | install.sh comment: the note sits above the command (A2) | Accurate | `install.sh:611-625` |
| 7 | init-firewall.sh comment updated (A4) | Accurate | `init-firewall.sh:347-350` |
| 8 | `--help`: a second workspace is bad usage on both sides of `--`; before `--`, a `#` word is too; after `--`, one word, and only when none came before; `./#x` or `-- '#x'` reach such a directory (85973b7a, S1) | Accurate | Probes `F2-ws-dd-ws` and `F2-dd-two` (rc=2), `F2-dd-one` (launches B), `F2-dd-hashx-rel` (launches `#x`). bats tests 19 and 20 pass |
| 9 | Usage errors come before main's first refusal (the host-tool check) and before any action (code comment, plan F7, rubric) | Accurate | `f7.sh`, with `cc-exit-scan.sh` tampered after a bless: two workspaces, `# --bless` and `--profile # --bless` all exit 2 with the usage error. A plain launch exits 1 with the host-tool refusal. No devcontainer call in any case. **No bats test pins this order** (see K3) |
| 10 | `-- '#'` exits 1 from `resolve_workspace`, with no action (rubric) | Accurate | Probe `F2-dd-hash`: rc=1, "not a directory: #" |
| 11 | No egress profile name starts with `-` or `#` (rubric) | Accurate | `ls devcontainer-config/egress/` |
| 12 | The locale reds are six, across cc-isolated-functions, cc-push and install-host, failing on 5e6e9266 too and passing under `LC_ALL=C.UTF-8` (5a821383 Notes, C5) | Accurate | Default locale (en_US.UTF-8, not installed here): cc-isolated-functions 129, 130, 189; cc-push 28, 46; install-host 3. That is 6. Under C.UTF-8: 0 in cc-isolated-functions and 0 in cc-push; 0 of 92 in install-host. All three cc-isolated reds also fail on `old/` (5e6e9266). The cc-push and install-host reds were not re-run on 5e6e9266 |
| 13 | Every new bats case fails on 5e6e9266 (plan step 4) | Accurate | The six new tests, run against `old/`: all `not ok`. At the tip: all `ok` (`LC_ALL=C.UTF-8 bats -f ...`: 38/38 in the related filter) |
| 14 | `--bless` and `--list` still ignore a single stray positional (a54bb3b0) | Accurate | Probes `F1-bless-stray` and `F1-list-stray`: rc=0. Two positionals give rc=2 (`F1-bless-two`) |
| 15 | Guide: remaining `cmd  # note` lines now exit 2 and name the offending value (guide paragraph, override-log row) | Accurate for cc-isolated lines; imprecise for "and others" | All remaining cc-isolated lines (`devcontainer-setup.md` 48, 79-81, 114, 153, 174; `cc-isolated-usage.md` 567, 595, 629) carry notes without shell metacharacters, so the `#` refusal fires. The override row's "and others" also covers `cc-isolated-usage.md:218-220`, which are cc-push lines and fail differently (see K4) |
| 16 | The rubric's S2: pasting the whole install.sh block, an apostrophe opens a quote | Accurate | Interactive `zsh -f -i`: `HEAD's` in a note gives `quote>` and swallows the following lines |
| 17 | Premise: interactive zsh passes a trailing `# note` as words | Accurate | `zsh -f -i` with input `print -rl -- v # --bless` printed `v`, `#`, `--bless` on separate lines |

## 2. Security: bypass families F1-F7

Every probe below ran at the tip. The harness labels and results are in the run log quoted in section 1. "No action" means no devcontainer call, no manifest change and no registration written.

| Family | Probes tried | Result |
|---|---|---|
| F1: second positional | launch/`--probe-only`/`--register` × `A B`; `A '#' note`; `--bless A B` | rc=2, no action, both values named |
| F2: after `--` | `-- B` (launches B); `-- A B`, `A -- B`, `--bless -- A B` (rc=2); `-- --bless`, `-- -`, `-- --`, `-- '#'` (rc=1, "not a directory", because `resolve_workspace` uses `[ -d ]` and `git -C`, never `cd`, so `-` cannot reach `$OLDPWD`); `-- ''` (opens `$PWD`, as `cc-isolated ''` did before); `--register -- B --profile python` (rc=2, see K2) | No unintended workspace |
| F3: note words as flags | `'#' --bless`, `'#note' --bless`, `--list '#' --bless`, `'#' --register B --profile python`, `--probe-only '#' B`, `'#' --help` | rc=2 at the `#` word, before any later flag is parsed. `--help '#'` exits 0, because help comes first (harmless) |
| F4: shell syntax in a note | Not reachable by the launcher (by design). Verified the remaining cc-isolated guide notes have no metacharacters | n/a |
| F5: note consumed as a flag value | `--profile '#'`, `--profile '#python'`, `--profile --bless`, `--profile python --profile '#'`, `--profile=python` (unknown flag, rc=2), `--profile 'python,#x'` (rc=1 from `register_project`'s validation, nothing written) | Covered. `--profile` is the only flag that takes a value |
| F6: legitimate forms | The audited callers (`rebuild_hint` with `%q`, the unregistered NOTE, `live-verify-gate.sh` messages, `install.sh`, guides) each pass at most one workspace | Covered |
| F7: error after a side effect | `f7.sh` (tampered host tool) | Usage errors precede the host-tool refusal and every action |

Out-of-family observations (pre-existing, not introduced by this unit; noted, not ranked):
- `--register B --profile ../egress/python` is accepted and written verbatim, because `register_project` builds `egress/$p.txt` without rejecting `/`. The `*` glob in the unquoted `for p in $(...)` is caught by the same readability check. This needs the user to type it, and this unit does not touch it.
- `--register B` with no `--profile` registers an empty grant and re-blesses (probe `F5-register-noprofile`). This is a pre-existing grammar gap, and a pasted note cannot produce it.
- The unregistered NOTE prints `--register '$ws'` with single quotes rather than `%q`, so a path containing `'` prints a broken command. `rebuild_hint` uses `%q`.

## 3. API consistency

- **Exit code and stream:** the new errors are `ERROR: ...` on stderr, then the usage, then exit 2. This matches decision log #58, cc-push's `usage_die` and install.sh's `exit 2` on an unknown argument. Consistent.
- **Wording:** cc-push says `one checkout at a time`. cc-isolated says `two workspaces given: %q and %q. cc-isolated takes one.`, plus hint lines before the usage. The difference is deliberate (rubric C7: the brief asked for both values). The `--profile` wording extends the existing `--profile needs a value` message. Acceptable.
- **Escaping:** cc-push filters its errors through `vis`. cc-isolated now uses `%q` for new values but prints raw values in its older messages (`unknown flag: $1`, `resolve_workspace`; rubric C10). `%q` renders the commonest case as `\# is not a workspace`, which reads like a typo to a user (K1).
- **`-- '#x'` with `--register`:** the escape works only when `--` comes last (K2).

---

## 🔴 Must Fix

None.

## 🟡 Must Address

None.

## 🟢 Consider

| # | Finding | Evidence |
|---|---|---|
| K1 | The `%q` rendering prints `\# is not a workspace; it looks like a pasted comment.` The backslash is shell-quoting noise for the most common trigger, a bare `#`. Quoting it (`'#'`), or using cc-push's `vis` approach for words with no control bytes, would read better. The tests assert `\#`, so they would change too | Probe output; `pasted_note_error` |
| K2 | `cc-isolated --register -- B --profile python` reports `two workspaces given: B and --profile`. This is correct by the rule but calls a flag a workspace. The `--help` line "Name a directory called '#x' as ./#x or -- '#x'" does not say `--` must come after every flag | Probe `F2-register-dd-then-profile` |
| K3 | Plan F7 is marked "Covered", but no bats case pins usage errors before the host-tool refusal. The order is structural today; a one-line test like `f7.sh` (installed copy, tampered `cc-exit-scan.sh`, `A B` gives 2, not 1) would hold it | `rg` in `test/cc-isolated-functions.bats` finds no such case; `f7.sh` |
| K4 | The override-log row and the guide's "other blocks ... still carry them" say the remaining lines "exit 2". That holds for every cc-isolated line. The cc-push lines at `cc-isolated-usage.md:218-220` behave differently: 219's `(or ...)` gives a zsh glob error, and 220's `HEAD's` opens a `quote>` continuation that swallows the next pasted lines. Both are harmless, but outside the claim | Interactive `zsh -f -i` run |
| K5 | `pasted_note_error`'s hint says "Rerun without the note" but does not name the `./#x` / `-- '#x'` escape for a real `#` directory. The usage printed after it does | `cc-isolated.sh` `pasted_note_error` |
| K6 | The plan header still says "in review (iteration 2)"; the rubric says the loop closed at 85973b7a | `docs/working/plan-2026-10-15-cc-isolated-one-workspace.md:3` |
