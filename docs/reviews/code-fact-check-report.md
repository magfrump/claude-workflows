# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-copyinstall (branch `ans/copy-install`)
**Scope:** diff `712c626..d0fdd04`: README.md, devcontainer-config/install.sh, docs/decisions/035-install-sh-gating.md, docs/decisions/037-bare-host-copy-install.md, guides/README.md, guides/bare-host-hook-wiring.md, test/install-host.bats, test/link-claude-home-wiring.bats, and the commit messages of 1514518, dcf4a6d, 6793b79 and d0fdd04 (union of the three replicates' scopes; docs/working and pre-mortem/architecture files were context only)
**Checked:** 2026-09-23
**Total claims checked:** 36
**Summary:** 22 verified, 9 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable
**Commit:** d0fdd04
**Replication:** k=3

Merged from `code-fact-check-report-r1.md`, `-r2.md` and `-r3.md` (all headed `Commit: d0fdd04`) by most-severe-wins, per `skills/code-review/SKILL.md` "Merging replicate verdicts". No claim, evidence or verdict was added in the merge. Each replicate's execution logs live in its own directory:

- r1: `docs/reviews/execution-logs/cfc-copy-install-r1-d0fdd04/` (`bats-head.txt`, `bats-old.txt`, `suites-summary.txt`, `run-tests-fast.txt`, `exp-E1-E5-E6-E7.txt`, `exp-E2-E4.txt`, `exp-E8-E9.txt`; drivers `exp.sh`, `run-suites.sh`, `run-fast.sh` copied alongside)
- r2: `docs/reviews/execution-logs/copy-install-r2/` (`install-host-head.log`, `install-host-old.log`, `cc-isolated.log`, `link-wiring.log`, `hooks.log`, `experiments.log`, `compare-1514518.log`, `run-tests-fast.log`)
- r3: `docs/reviews/execution-logs/cfc-copy-install-r3/` (`probe.txt`, `probe9.txt`, `head-*.txt`, `dcf4a6d-install-host.txt`, `exits.txt`; drivers `probe.sh`, `probe9.sh`, `run-suites.sh`)

All three replicates report hermetic runs: HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and TMPDIR pointed into scratch, and CLAUDECODE was unset for the child. None ran against the real `~/.claude`, `~/.config` or `~/.local`. None matched a logged hallucination pattern. r3 records a scratchpad collision with a sibling replicate; see Escalations.

Compound-claim convention: where one replicate split a sentence and another verdicted it whole, the merged report carries one claim per sub-claim. The whole-sentence replicate's verdict appears on every row, marked `(compound)`, and most-severe-wins applies per row.

---

## Claim 1: "Destination: $CLAUDE_HOME_DIR, else $CLAUDE_CONFIG_DIR, else ~/.claude; the review names which variable chose it." (README: "`~/.claude` (or `$CLAUDE_CONFIG_DIR` if you set it)")

**Location:** `README.md:19`, `devcontainer-config/install.sh:281-284`, `devcontainer-config/install.sh:307`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the precedence and the `Destination: … (chosen by …)` line; the README omits `CLAUDE_HOME_DIR` precedence, harmless for users who don't set it; does not establish that Claude Code itself reads `$CLAUDE_CONFIG_DIR` as its config root.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "The README omits `CLAUDE_HOME_DIR` precedence, which is harmless for users who don't set it. Does not establish that Claude Code itself reads `$CLAUDE_CONFIG_DIR` as its config root."

(r1) `if [ -n "${CLAUDE_HOME_DIR:-}" ]; then dest="$CLAUDE_HOME_DIR"; label='$CLAUDE_HOME_DIR'` / `elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; …` (`devcontainer-config/install.sh:281-282`). T24 passes: CLAUDE_CONFIG_DIR chooses the destination, and HOME/.claude stays absent.

**Evidence:** `devcontainer-config/install.sh:281-284`, `devcontainer-config/install.sh:307`; r1 `bats-head.txt` (T24)

---

## Claim 2: "The `~/.claude` target only installs for a human at a terminal." (also install.sh --help: "It only installs for a human at a terminal who read the diff.")

**Location:** `README.md:21-22`, `devcontainer-config/install.sh:42-43`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether a non-human process can clear the skip rules and install; does not establish whether the host's sandbox `denyWrite ~/.claude` would stop such a run on the user's machine (Claim 27).
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "It does not establish 'only installs for a human'. A process that supplies a pty and unsets CLAUDECODE installs … the README's own wording is 'for a human at a terminal', which the code cannot check." · r3: "it does not establish that 'only for a human' holds against an agent that fakes a pty and drops `CLAUDECODE` (Claim 5c shows it does not, as 037 itself says)." · r1: "A reader relying on 'only a human can install' would not add the sandbox backstop." · r1 (escalation): see Escalations E1.

(r1) The guard is a TTY check plus a CLAUDECODE check (`devcontainer-config/install.sh:297`, `:301`: `if [ -n "${CLAUDECODE:-}" ]; then` / `if [ ! -t 0 ]; then`). An agent's Bash tool can defeat both. E5 ran from this agent session with no TTY (`[outside: not-tty]`). Under `script -qec 'env -u CLAUDECODE bash -c …' /dev/null` it printed `stdin-is-tty` and `CLAUDECODE=unset`. The hermetic suite is itself the proof. Every y-path test (T6, T7, T9, T10, T11, T13, T18, T24) was run from inside an agent session through `run_pty`, and each one installed:

```bash
# test/install-host.bats:104-108 (run_pty)
run_pty() {
  local input="$1"; shift
  run bash -c 'set -o pipefail; printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$input" "$*"
}
```

The code comment at install.sh:290-292 ("Neither check stops an agent that sets out to fake a terminal … They stop the accidental run") and decision 037 ("The check stops accidents, not intent") both state the real property. The README and `--help` state it as an absolute, which contradicts both.

**Evidence:** `README.md:21-22`; `devcontainer-config/install.sh:42-43`, `devcontainer-config/install.sh:290-304`; `docs/decisions/037-bare-host-copy-install.md:50`; `test/install-host.bats:104-108`; r1 `exp-E1-E5-E6-E7.txt` (E5), `bats-head.txt`

---

## Claim 3: "It is skipped with `--yes`, from a script with no TTY, and inside a Claude Code session."

**Location:** `README.md:22-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three skip triggers (`--yes`, a non-TTY stdin, CLAUDECODE set), each tested with a pty where relevant; does not establish that a TTY or CLAUDECODE check distinguishes a human from an agent (Claim 2).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: the skip triggers do not establish "only for a human"; a pty plus `env -u CLAUDECODE` installs (see Claim 2).

(r1) The three checks run first in `install_claude_home`, before any read:

```bash
# devcontainer-config/install.sh:293-304
  if [ "$ASSUME_YES" = "--yes" ]; then
    echo "Skipped host target (~/.claude): it never installs with --yes. ..."
    return 0
  fi
  if [ -n "${CLAUDECODE:-}" ]; then
    ...
    return 0
  fi
  if [ ! -t 0 ]; then
    ...
    return 0
  fi
```

T1–T4 and T22 pass at HEAD. T4 is `--yes` in a pty, and T22 is CLAUDECODE=1 in a pty. E1 reproduces the non-TTY and `--yes` skip lines. r2 (T1–T4, T22) and r3 (P1a, P1c, P2) also executed these and got the same result.

**Evidence:** `devcontainer-config/install.sh:293-304`; `test/install-host.bats` T1–T4, T22; r1 `bats-head.txt`, `exp-E1-E5-E6-E7.txt`; r2 `install-host-head.log`; r3 `probe.txt` (P1a, P1c, P2)

---

## Claim 4: "Its `~/.claude` review lists every symlink it will replace (`REPLACE symlink … with a copy`) and every file in those directories that the repo doesn't have (`MOVE to backup`). Check any line marked `WIRED in settings` …"

**Location:** `README.md:26-29`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the review's pre-pass for top-level links, per-file links and foreign files, including a foreign skill directory; does not establish that the review completes when an install-owned directory holds a dangling symlink, which it does not.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "Does not establish: that foreign *empty* directories are listed (the pre-pass finds only `-type f -o -type l`, so an empty foreign dir moves without a line); WIRED detection for foreign files in hooks subdirectories (it matches `hooks/$(basename "$f")`, so `hooks/lib/x.sh` is looked up as `hooks/x.sh`)" · r1: dangling *top-level* links (moved checkout) produce REPLACE lines and a full additive diff, not an abort (E3c) · r2: "It does not establish that the review can always be completed: a dangling link aborts it"; a foreign skill that is a symlinked directory prints both `REPLACE symlink` and `MOVE to backup` (E2) · r3: "The error names `hooks` but not the dangling path … The README gives them no guidance for that." · r3: "The review also mislabels foreign per-file links (see Claim 7)" (merged Claim 16).

(r3) The listing is real. In P3 the review printed a `REPLACE symlink` line for each of the six top-level links and each per-file hook link. It printed `MOVE to backup (not in the repo)` for `mine.sh`, `foreignlink.sh` and `dangling.sh`, with `<-- WIRED in settings` on `mine.sh`. The same P3 run then aborted before the prompt, because `diff -ruN` exits 2 on a dangling symlink nested inside an owned directory:

```
diff: …/p3/home/.claude/hooks/dangling.sh: No such file or directory
ERROR: could not diff payload item 'hooks' (diff exit 2).
       The review diff is incomplete, so nothing was installed.
[exit=1]
```

The abort comes from `review_diff`'s `*)` branch (`devcontainer-config/install.sh:149-151`), which `install_claude_home` calls at `:372`. A migrating user with one stale per-file link cannot complete the migration until they find it and delete it by hand. A dangling *top-level* link does not abort. In P9 a dangling `CLAUDE.md` reviewed as `REPLACE symlink`, installed, and was moved to the backup, because `-N` treats an unreadable top-level operand as absent. r2's E2b reproduced the nested-dangling abort independently.

**Evidence:** `README.md:26-29`; `devcontainer-config/install.sh:145-151`, `devcontainer-config/install.sh:345-374`; r3 `probe.txt` (P3), `probe9.txt` (P9); r2 `experiments.log` (E2, E2b); r1 `bats-head.txt` (T5, T13, T20), `exp-E2-E4.txt` (E3, E3c)

---

## Claim 5: "Everything replaced, including the old links, is moved to `~/.claude/.claude-workflows-backup/<UTC stamp>/`."

**Location:** `README.md:31-32`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a run that reaches the swap: links are moved as links (T6) and foreign files are moved (T13); does not cover two paths migrating users can hit: (1) a dangling symlink inside an owned directory aborts the review, so nothing is moved and the run exits 1; (2) a `mv` failing partway through the backup step leaves the destination partly emptied (Claim 18).
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: "or that the stamp dir is always exactly `<UTC stamp>` (a same-second rerun gets `<stamp>.<pid>`, Claim 12)" · r3: "It does not establish the state after a failure between move-aside and swap-in (see Claim 10)." · r2: "All nine per-file hooks from the old README still exist at d0fdd04 (`compare-1514518.log`), so the user's current links should not be dangling." · r2 (escalation): see Escalations E3.

(r2) The statement holds when an install completes. T6 checks `[ -L "$bk/skills" ]`, `[ -L "$bk/CLAUDE.md" ]` and `[ -L "$bk/hooks/h.sh" ]`. But the review diff runs `diff -ruN` over each owned directory:

```bash
# devcontainer-config/install.sh:145-151
    diff -ruN "$dest/$item" "$src/$item" || rc=$?
    case "$rc" in
      0) ;;
      1) changed=1 ;;
      *) echo "ERROR: could not diff payload item '$item' (diff exit $rc)." >&2
         echo "       The review diff is incomplete, so nothing was installed." >&2
         exit 1 ;;
```

In E2b the destination held a dangling per-file link, `hooks/old.sh -> gone.sh`. The pre-pass printed `REPLACE symlink …/hooks/old.sh` and `MOVE to backup …/hooks/old.sh`. Then diff printed `diff: …/hooks/old.sh: No such file or directory` and `ERROR: could not diff payload item 'hooks' (diff exit 2)`. Nothing was installed. The migration paragraph does not mention this case.

**Evidence:** `devcontainer-config/install.sh:133-155`, `devcontainer-config/install.sh:372-374`; r2 `experiments.log` (E2b), `compare-1514518.log`; r1 `bats-head.txt` (T6); r3 `head-install-host.txt` (ok 6), `probe9.txt`

---

## Claim 6: "Your `settings.json`, memory, projects and logs are never touched."

**Location:** `README.md:32-33`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven install-owned names moving to the backup and the untouched host-state paths on a successful install; does not establish the state after a failure between move-aside and swap-in (Claim 19).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2: settings.json, settings.local.json, projects, memory, logs and .credentials(.json) byte-identical after a y (T7) · r3: "It does not establish the state after a failure between move-aside and swap-in."

(r3) Only the seven names are moved (`devcontainer-config/install.sh:423-427`: `for name in "${CLAUDE_HOME_NAMES[@]}"; do … mv "$dest/$name" "$backup/$name"`). Apart from those, the installer writes only `.cw-new.*`, the backup and `.claude-workflows-manifest` (`:398-399`, `:418`, `:441-447`). T6 ("links backed up as links") and T7 ("user state in the destination is byte-identical after an install") pass at HEAD.

**Evidence:** `devcontainer-config/install.sh:398-447`; r3 `head-install-host.txt` (ok 6, ok 7); r1 `bats-head.txt` (T7); r2 `install-host-head.log` (T7)

---

## Claim 7: "Target 2 is SKIPPED, with a message and no effect on the exit status … Exit status: 0 no target declined; 1 a target was declined, or an error; 2 bad arguments."

**Location:** `devcontainer-config/install.sh:40-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the documented exit codes and skip behavior on the tested paths: T1 exits 1, T3 and T4 exit 0, T15 exits 2, T17 and T19 exit 1, and T12, T14, T16 and T21 exit 1 on error; does not establish exit 1 for every error path, e.g. a `set -e` death in step 2 (E4 exited non-zero, but the log does not capture the exact code).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Does not establish the exit status when `cc-isolated.sh --bless` fails (not exercised, since it is a stub)"; r1's E9 printed `INSTALL_EXIT=1` after a mid-install failure · r2: E4 exit code "not captured" · r3: `-h` exits 0 (P1e); "It does not establish exit codes on other error paths."

(r2) `exit "$DECLINED"` at `devcontainer-config/install.sh:464` is the normal exit. `host_refuse` and the copy and diff failures `exit 1`, and the argument loop does `exit 2` (`install.sh:58`). The tests listed in Scope pass. (r1) `install.sh:461-464` reads `DECLINED=0` / `install_devcontainer` / `install_claude_home` / `exit "$DECLINED"`, and the skip branches `return 0` without setting DECLINED.

**Evidence:** `devcontainer-config/install.sh:40-61`, `devcontainer-config/install.sh:461-464`; r2 `install-host-head.log`; r1 `bats-head.txt`, `exp-E8-E9.txt`; r3 `probe.txt` (P1a, P1c, P1e, P2)

---

## Claim 8: "exit 2 for an unknown argument is the only observable change, and only for invalid input." (commit 1514518 Notes)

**Location:** `devcontainer-config/install.sh:53-61` (commit 1514518)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers argument handling old vs new, and line-by-line equivalence of the refactored devcontainer flow at 1514518 (`git diff 712c626 1514518`: diff, prompt, copy, chmod, link and bless code moved into functions unchanged); does not establish anything about the later 6793b79 changes (Claims 9 and 13).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2: `--yes extra` used to install and now exits 2; it falls under "unknown argument" but was a working invocation before · r2: "The same commit body's first paragraph describes `-h/--help`, so only the Notes line is imprecise." · r2: "It does not establish identical behavior for inputs outside those four."

(r1) The old code was `ASSUME_YES="${1:-}"`, so any argument other than `--yes` fell through to the normal prompting run. The new loop:

```bash
# devcontainer-config/install.sh:54-61
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) ASSUME_YES="--yes" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
```

`-h/--help` is a second observable change. In E8, OLD `-h` assembled the payload and started the review (`Canonical (repo): …`), and NEW `-h` prints `Usage:` and exits 0 without doing anything. r2 (`compare-1514518.log`: old `--help` gave prompt + `rc=1`, new gave usage + `rc=0`) and r3 (P1d/P1e) got the same result. More precise wording: "unknown arguments exit 2, and -h/--help print usage; both only for arguments the old script ignored."

**Evidence:** `devcontainer-config/install.sh:53-61`; `712c626:devcontainer-config/install.sh` (`ASSUME_YES="${1:-}"`); r1 `exp-E8-E9.txt` (E8); r2 `compare-1514518.log`; r3 `probe.txt` (P1d, P1e)

---

## Claim 9: "The line keeps its old wording, and the run still exits 1 because something was declined." (with "a decline ends this target, not the run; the host target is still offered")

**Location:** `devcontainer-config/install.sh:192-195`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the devcontainer decline message and the exit code for a declined run; does not establish anything about a caller that matches the whole line exactly (none in the repo's tests; `test/cc-isolated-functions.bats:640` does a substring match).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "none found in `test/`; T1 matches it as a substring" · r2: "It does not establish that output-matching callers are unaffected … A substring match still passes; an exact line match does not." · r2: the continuation part holds (T5 and T17 reach the host prompt after `n`).

(r3) The line gained a suffix (`:195`: `echo "Aborted. Nothing was changed. (devcontainer config)"`). The old script printed `Aborted. Nothing was changed.` (`git show 712c626:devcontainer-config/install.sh`, the `*) echo "Aborted. Nothing was changed."; exit 1 ;;` arm). P1a (HEAD) printed `… Aborted. Nothing was changed. (devcontainer config)` then `[exit=1]`. P1b (712c626) printed `… Aborted. Nothing was changed.` then `[exit=1]`. The exit-1 half holds. "Keeps its old wording" is true only of the prefix.

**Evidence:** `devcontainer-config/install.sh:190-198`; `test/cc-isolated-functions.bats:640`; r3 `probe.txt` (P1a, P1b); r1 `exp-E1-E5-E6-E7.txt` (E1); r2 `experiments.log` (E6)

---

## Claim 10: "`diff` follows symlinks, so a migration from links to copies would review as "(none)". Hence the explicit REPLACE lines below." (with "`cp -r stage/skills ~/.claude/skills` writes INTO the checkout through the link")

**Location:** `devcontainer-config/install.sh:240-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers diff output through a per-file link into the checkout (empty) and through a link elsewhere (shows content); the cp/rm hazards were verified in the research doc, not re-run; does not establish that the installer never runs `cp` or `rm -rf` through a link (Claim 15 for the guards).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: "It does not establish the same behavior for BSD/macOS diff (not run; the commit's Notes flag macOS as untested)." · r2 (in its Claim 8 prose): the "prints nothing" concern "applies only when the link target equals the stage. That is exactly the case of a link into the checkout, and the REPLACE line covers it."

(r1) In E3b a per-file `hooks/h.sh` link into the checkout produced a `REPLACE symlink …/hooks/h.sh` line and no `h.sh` hunk. Only files absent from the destination appeared. In E3 the same link pointed at a different file, and a hunk appeared. The install path never calls `cp -r` onto a live name. It copies to `.cw-new.$name` and renames: `if ! cp -R "$stage/$name" "$dest/.cw-new.$name"; then ok=0; break; fi` (`install.sh:399`), then `mv "$dest/.cw-new.$name" "$dest/$name"` (`:436`). r3's P3/P3b showed the same thing for top-level links and a per-file skill link.

**Evidence:** `devcontainer-config/install.sh:240-244`, `devcontainer-config/install.sh:399`, `devcontainer-config/install.sh:436`; r1 `exp-E2-E4.txt` (E3, E3b); r3 `probe.txt` (P3, P3b)

---

## Claim 11: "The seven entry names, derived from CLAUDE_HOME_SRC so the host can never install a subset of the payload (FP-066)."

**Location:** `devcontainer-config/install.sh:246-250`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the derivation, and that FP-066 exists in the failure-pattern library; does not establish that FP-066's recorded symptom (a container session missing repo skills) is the same failure as a host subset install; it is analogous, not identical.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r1: "It is analogous, not identical." · r2: "It does not establish behavior if CLAUDE_HOME_SRC ever contains two entries with the same basename."; T18 (all seven installed) executed and passes.

(r1)

```bash
# devcontainer-config/install.sh:248-250
CLAUDE_HOME_NAMES=()
for _item in "${CLAUDE_HOME_SRC[@]}"; do CLAUDE_HOME_NAMES+=("$(basename "$_item")"); done
unset _item
```

Every host loop iterates `CLAUDE_HOME_NAMES`, and `assemble` exits on a missing source (`:115-119`). `docs/thoughts/failure-patterns.md:208` has `**FP-066** 2026-07-29 symptom:repo-skills-never-registered-in-any-container-session`.

**Evidence:** `devcontainer-config/install.sh:93`, `devcontainer-config/install.sh:108-120`, `devcontainer-config/install.sh:248-250`; `docs/thoughts/failure-patterns.md:208`; r2 `install-host-head.log` (T18)

---

## Claim 12: "Skip rules come first: before this target reads or stages anything … A skip is not a decline and does not change the exit status."

**Location:** `devcontainer-config/install.sh:287-289` (same claim: `docs/decisions/037-bare-host-copy-install.md:33-34`, commit 6793b79 body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering: the only work before the skip checks is choosing `dest`, with no staging and no file reads, plus the unchanged exit status (T1: 1, T3: 0); does not establish "unchanged apart from this one line" (Claim 13).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Verified
**Replicate annotations:** merge note: the Mostly accurate verdict comes from r1's and r2's compound claims. Both locate the defect in the sibling sub-claim (Claim 13) and state this ordering half holds. r1: "The skip does come before any read or stage." r2: "'Before this target reads or stages anything' holds." · r3: ordering is "skip checks at `:293-304` come before the guards at `:310+`, `mktemp` at `:333` and `assemble` at `:335`"; P1c exited `[exit=0]`.

(r2) Before the checks, the function only picks `dest` and `label` from environment variables and prints a blank line (`echo` at `install.sh:286`). There are two claims here. "Before this target reads or stages anything" holds. "Unchanged apart from this one line" does not hold for the closed-stdin, no-`--yes` case (Claim 13). (r3) The skip branches `return 0` without setting `DECLINED`. P1c (`--yes`, the devcontainer target accepted, the host skipped) exited `[exit=0]`.

**Evidence:** `devcontainer-config/install.sh:279-304`, `devcontainer-config/install.sh:461-464`; r3 `probe.txt` (P1c); r2 `install-host-head.log`; r1 `exp-E1-E5-E6-E7.txt` (E1)

---

## Claim 13: "so every non-interactive run (scripts, tests, --yes) is unchanged apart from this one line."

**Location:** `devcontainer-config/install.sh:287-289`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output and exit status of `</dev/null` and `--yes </dev/null` runs, old against new; does not establish anything about runs with invalid arguments (Claim 8) or callers' parsing of that output.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Mostly accurate
**Replicate annotations:** r2: "For `--yes` runs the delta is the blank line plus the Skipped line (T3 output)." · r3: "The exit status and the files written are unchanged."

(r1) The non-interactive output differs by more than one line. `install_claude_home` prints a blank line before the skip (`install.sh:286`: `  echo`), and the devcontainer decline line gained a suffix (Claim 9). E1, old vs new, `</dev/null`:

```
OLD: Install this config and bless it? [y/N] Aborted. Nothing was changed.
NEW: Install this config and bless it? [y/N] Aborted. Nothing was changed. (devcontainer config)
     <blank>
     Skipped host target (~/.claude): it needs an interactive terminal (stdin is not a TTY). ...
```

The exit status is unchanged (1 and 0). More precise wording: "a blank line plus one skip line, and the decline line gains a ' (devcontainer config)' suffix." r2 (E6) and r3 (P1a/P1b) got the same result.

**Evidence:** `devcontainer-config/install.sh:286-304`, `devcontainer-config/install.sh:195`; r1 `exp-E1-E5-E6-E7.txt` (E1); r2 `experiments.log` (E6); r3 `probe.txt` (P1a, P1b)

---

## Claim 14: "Neither check stops an agent that sets out to fake a terminal (`script` gives it a pty; `env -u` drops CLAUDECODE). They stop the accidental run and make the deliberate one conspicuous."

**Location:** `devcontainer-config/install.sh:290-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers util-linux `script` on this Linux sandbox; does not establish availability on macOS (BSD `script` takes different arguments), the "conspicuous" clause, or whether a host sandbox `denyWrite` would then stop the writes (Claim 27).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish 'conspicuous'. The only trace is the manifest's `installed_parent`, which is not reliably 'script' (Claim 12b)" (merged Claim 22) · r3: "It does not establish whether a host sandbox `denyWrite` would then stop the writes" · r1: does not establish 037's "fd 0 is /dev/null" observation (see Claim 26).

(r1) E5 ran with `CLAUDECODE=1` set around the wrapper. Inside `script -qec 'env -u CLAUDECODE bash -c …' /dev/null` it printed `stdin-is-tty` and `CLAUDECODE=unset`, and it printed `[outside: not-tty]` for the agent's own Bash tool. r2's E1 and r3's P4, P7, P8 and P9 completed full host installs through the same wrapper, e.g. r3 P9: `Installed into …/p9/home/.claude.`

**Evidence:** `devcontainer-config/install.sh:290-304`; `test/install-host.bats:101-104`; r1 `exp-E1-E5-E6-E7.txt` (E5); r2 `experiments.log` (E1); r3 `probe.txt` (P4, P8), `probe9.txt`

---

## Claim 15: "Guards: nothing below may write through a link into the checkout." (commit 6793b79: "Refuses a destination, backup dir or .cw-new.* leftover that is a symlink into (or resolves inside) the checkout.")

**Location:** `devcontainer-config/install.sh:309-331`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a destination symlinked into the checkout, a dangling-link destination, a symlinked backup root, a backup root resolving inside the checkout, and `.cw-new.*` symlinks; does not establish any refusal or notice for a destination that is a symlink to a non-checkout directory, which is followed silently (E2 installed through `~/.claude -> elsewhere`, and the review's `Destination:` line did not mention the link), nor that `.cw-new.*` real directories are preserved (they are `rm -rf`'d, `:398`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: a `~/.claude` symlinked to a directory outside the checkout is followed and installed into, and the link is kept (r1 E2, r2 E1, r3 P4). r2: "the guard comment does not claim to refuse it." · r2: "It also does not guard a pre-existing `.claude-workflows-backup/<stamp>` symlink. That case only triggers the `.$$` suffix, because `-e` follows links." · r1: a pre-planted `$bkroot/<stamp>` is safe (inferred, not run): an existing target takes the `.$$` suffix, and a dangling one makes `mkdir -p` fail, which removes `.cw-new.*` and exits · r3: "It does not establish time-of-check/time-of-use safety between these checks and the writes at `:395-447`" · r1 (residue routed to synthesis): see Escalations E5.

(r1)

```bash
# devcontainer-config/install.sh:310-331
  if [ -L "$dest" ] && [ ! -d "$dest" ]; then
    host_refuse "$dest is a dangling symlink ..."
  fi
  if [ -e "$dest" ] && [ ! -d "$dest" ]; then
    host_refuse "$dest exists and is not a directory."
  fi
  if inside_repo "$(resolve_phys "$dest")"; then
    host_refuse "$dest resolves inside the repo checkout ..."
  fi
  local bkroot="$dest/.claude-workflows-backup"
  if [ -L "$bkroot" ]; then
    host_refuse "$bkroot is a symlink ..."
  fi
  if [ -d "$bkroot" ] && inside_repo "$(resolve_phys "$bkroot")"; then
    host_refuse "$bkroot resolves inside the repo checkout."
  fi
  local name
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -L "$dest/.cw-new.$name" ]; then
      host_refuse "$dest/.cw-new.$name is a symlink left from elsewhere; remove it and rerun."
    fi
  done
```

T14 (destination symlinked into the checkout) and T21 (planted backup symlink) pass, and the checkout snapshot is unchanged in both. r3's P5 (`~/.claude -> repo`) was refused with `[exit=1]` and a clean `git status`.

**Evidence:** `devcontainer-config/install.sh:255-277`, `devcontainer-config/install.sh:309-331`, `devcontainer-config/install.sh:416-422`; r1 `bats-head.txt` (T14, T21), `exp-E2-E4.txt` (E2); r2 `experiments.log` (E1); r3 `probe.txt` (P4, P5)

---

## Claim 16: "REPLACE symlink $link -> $(readlink "$link") with a copy" (commit 6793b79: "The review lists every symlink it will replace (top-level and per-file), every foreign file it will move (flagging hooks wired in settings)")

**Location:** `devcontainer-config/install.sh:342-368`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-file REPLACE line for a symlink the repo has no counterpart for; does not affect per-file links whose name exists in the repo (those are correctly labelled).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Incorrect
**Replicate annotations:** r2: "A foreign *symlink* gets both a REPLACE and a MOVE line (E2)" (observed; r2 did not flag it as a mislabel) · r2: the WIRED test is a fixed-string grep for `hooks/<basename>`: "A foreign `hooks/lib/foo.sh` is flagged if settings mention some `hooks/foo.sh`. A hook wired by a path that doesn't contain `hooks/<basename>` … is not flagged" (inferred, not executed; r2 confidence Medium) · r1: WIRED matches the basename only, so a nested foreign `hooks/lib/x.sh` is checked as `hooks/x.sh`, and foreign empty directories move without a MOVE line.

(r3)

```bash
# devcontainer-config/install.sh:350-353
      while IFS= read -r -d '' link; do
        echo "REPLACE symlink $link -> $(readlink "$link") with a copy"
        changed=1
      done < <(find "$dest/$name" -type l -print0 | sort -z)
```

The loop prints a REPLACE line for every symlink it finds, without checking that the stage has the path. A foreign per-file link gets no copy. It is only moved to the backup, so the review contradicts itself. In P3, `hooks/foreignlink.sh -> …/other.sh` and `hooks/dangling.sh -> …/elsewhere.sh` each printed `REPLACE symlink … with a copy` and, a few lines later, `MOVE to backup (not in the repo): …`. A reader who stops at the REPLACE line expects that hook to keep working as a copy. In fact the link is moved and nothing replaces it.

**Evidence:** `devcontainer-config/install.sh:345-368`; r3 `probe.txt` (P3); r2 `experiments.log` (E2); r1 `bats-head.txt` (T5, T13, T20)

---

## Claim 17: "Content diff: the same review_diff the devcontainer target uses. Through a symlinked entry it compares the link's target (the checkout) with the stage."

**Location:** `devcontainer-config/install.sh:370-374`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers review_diff being shared and dereferencing links; does not establish that the target is the checkout; the parenthetical assumes the README's old install.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: "'(the checkout)' is the typical target, not the only one: a link elsewhere compares that target. Does not establish behavior for a link to an unreadable target (would be diff exit 2 and an abort, per `:149-151`)." · r2: "It does not establish that a dangling link can be diffed. Such a link makes `diff` exit 2 and aborts the host target"; for a link into the checkout, the diff prints nothing (T5 sees no `(none` only because the REPLACE lines set `changed`) · r3: a skill inside a linked non-checkout directory "was not listed as MOVE because the entry is a link … Nothing is lost: the link is moved and its target is left in place."

(r3) The mechanism holds (`:372`: `if ! review_diff "$dest" "$stage" "${CLAUDE_HOME_NAMES[@]}"; then`). The parenthetical "(the checkout)" holds only for the README's links. In P3c, `~/.claude/skills -> …/myskills` was a non-checkout directory holding `zzz/SKILL.md`. The diff compared that directory with the stage and showed `-mine` for `skills/zzz/SKILL.md`, which was not listed as MOVE (`:346-348` takes the REPLACE branch only). More precise wording: "compares the link's target (the checkout, for the README's old install) with the stage."

**Evidence:** `devcontainer-config/install.sh:133-155`, `devcontainer-config/install.sh:345-374`; r3 `probe.txt` (P3c); r2 `experiments.log` (E2, E2b); r1 `exp-E2-E4.txt`

---

## Claim 18: "1. Copy every entry beside its target. Any failure: undo and stop before a single live entry is touched." (commit 6793b79: "A copy failure undoes itself before touching a live entry.")

**Location:** `devcontainer-config/install.sh:392-406`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the step-1 copy-failure undo (T16: `mkdir -p "$dest"` or any `cp -R` into `.cw-new.<name>`); **does not establish any recovery for a failure in step 2 or 3**: a failed move-aside left the destination without CLAUDE.md and skills, all seven `.cw-new.*` beside it, and only the raw `mv` error (exit 1).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3 (residue on a Verified claim): a failure in step 2 (move-aside) or step 3 (swap-in) has no undo and no recovery message. r1 E4/E9, r2 E4 and r3 P6 each left the live destination missing `CLAUDE.md` and `skills` (moved to the backup), with all seven `.cw-new.*` stranded. The only output was `mv: cannot move … Permission denied`, and nothing named the backup dir or said how to finish or roll back. r2+r3: "The step-3 ERROR message at `:433` names the `.cw-new` path for the one entry it stops on. It does not mention entries already swapped or where the old entries went." · r1: "The claim is only about copy failures, so this residue is not a contradiction." · escalation: see Escalations E2.

(r2) Step 1 behaves as the comment says. T16 (a read-only destination) passes: exit 1, `nothing was replaced`, destination snapshot unchanged, no backup directory and no `.cw-new.*`.

```bash
# devcontainer-config/install.sh:402-406
  if [ "$ok" -eq 0 ]; then
    for name in "${CLAUDE_HOME_NAMES[@]}"; do rm -rf "$dest/.cw-new.$name" 2>/dev/null || true; done
    echo "ERROR: could not copy the new files into $dest; nothing was replaced." >&2
    exit 1
  fi
```

Steps 2 and 3 have no guard (`install.sh:423-437`: `mv "$dest/$name" "$backup/$name"` then `mv "$dest/.cw-new.$name" "$dest/$name"`). E4 made the real directory `workflows` non-writable. The only output was `mv: cannot move '…/workflows' to '…/.claude-workflows-backup/20260923T233319Z/workflows': Permission denied`, and then `set -e` exited. That left `guides workflows` and all seven `.cw-new.*` in the destination, with `CLAUDE.md` and `skills` in the backup.

**Evidence:** `devcontainer-config/install.sh:392-437`; `test/install-host.bats` T16; r2 `experiments.log` (E4); r1 `bats-head.txt` (T16), `exp-E2-E4.txt` (E4), `exp-E8-E9.txt` (E9); r3 `head-install-host.txt` (ok 16), `probe.txt` (P6)

---

## Claim 19: "Installs by copying to .cw-new.<name>, moving the old entries (links as links) to .claude-workflows-backup/<UTC stamp>/, then swapping in." (commit 6793b79)

**Location:** `devcontainer-config/install.sh:408-437`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of operations and links moved as links (T6) for one run at a time; does not establish recoverability when step 2 or 3 fails partway (Claim 18) or safety for concurrent runs (Claim 20).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r1: "Concurrent runs are also not covered: two runs in the same second can both pass `[ -e "$backup" ]` before either `mkdir -p` (not run)." · r2: concurrent runs share the `.cw-new.<name>` names; in E5b the destination ended with none of the seven entries.

(r1)

```bash
# devcontainer-config/install.sh:423-437 (excerpt)
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
  fi
  # 3. Swap the new copies in.
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    ...
    mv "$dest/.cw-new.$name" "$dest/$name"
  done
```

T6 (links backed up as links, checkout unchanged) passes.

**Evidence:** `devcontainer-config/install.sh:408-437`; r1 `bats-head.txt` (T6); r2 `install-host-head.log` (T6)

---

## Claim 20: "2. Move whatever is there now … into a fresh backup dir."

**Location:** `devcontainer-config/install.sh:408-418`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one run at a time, including two sequential runs in the same second (the second gets `<stamp>.<pid>`, so "fresh" holds); does not establish safety for concurrent runs: two concurrent runs share the `.cw-new.<name>` names, and in E5b the destination ended up with none of the seven entries.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: E5b concurrent run: "One failed with `mv: cannot stat '…/.cw-new.CLAUDE.md'` … All content was still recoverable from the two backup directories. Concurrent runs need two interactive terminals both answering y, so this is an edge case." · r3: "In the concurrent case `mkdir -p` succeeds on an existing dir, and a second `mv skills <existing>/skills` would nest the entry (`<backup>/skills/skills`) rather than overwrite it. That is inferred, not run."; r3 confidence Medium · r1: E7 second same-second run used `<stamp>.415425`.

(r2)

```bash
# devcontainer-config/install.sh:411-417
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  ...
    backup="$bkroot/$stamp"
    if [ -e "$backup" ]; then backup="$backup.$$"; fi
```

E5 ran two sequential y installs in the same second and got `20260923T233319Z` and `20260923T233319Z.351261`, with no collision. r3's P7 gave the same result (`20260923T233238Z`, `20260923T233238Z.333103`).

**Evidence:** `devcontainer-config/install.sh:408-437`; r2 `experiments.log` (E5, E5b), `compare-1514518.log` (e5b final dest); r1 `exp-E1-E5-E6-E7.txt` (E7); r3 `probe.txt` (P7)

---

## Claim 21: "Provenance, in link-claude-home's format plus additive keys. `rm -f` first so a planted symlink cannot redirect the write." (commit 6793b79: "Writes .claude-workflows-manifest (rm -f first) with installed_by, installed_parent and installed_at appended")

**Location:** `devcontainer-config/install.sh:439-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rm-then-cp sequence defeating a pre-planted symlink (T6) and the presence and values of `commit`, `assembled_from`, `installed_by=host-tty` and `installed_at=<stamp>`; does not cover what `installed_parent` records (Claim 22) or a symlink planted between the `rm -f` and the `cp`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "`installed_by=host-tty` is a constant and asserts nothing measured." · r2: "`stamp` is always set at `:411`, before the `any` check."

(r2)

```bash
# devcontainer-config/install.sh:441-447
  rm -f "$dest/.claude-workflows-manifest"
  cp "$stage/.manifest" "$dest/.claude-workflows-manifest"
  {
    echo "installed_by=host-tty"
    echo "installed_parent=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ' || echo unknown)"
    echo "installed_at=$stamp"
  } >> "$dest/.claude-workflows-manifest"
```

T6 plants `.claude-workflows-manifest -> checkout CLAUDE.md`, then asserts `[ ! -L … ]` and an unchanged checkout. T10 checks `commit=`, `assembled_from=` and `installed_by=host-tty`. E3 shows `installed_at=20260923T233317Z`.

**Evidence:** `devcontainer-config/install.sh:410-411`, `devcontainer-config/install.sh:439-447`; `test/install-host.bats` T6, T10; r2 `experiments.log` (E3); r1 `exp-E1-E5-E6-E7.txt` (E6); r3 `probe.txt` (P8)

---

## Claim 22: "installed_parent records "script" when the installer ran under a pty wrapper, which is an audit trace for the agent-bypass case the TTY rule cannot stop." (commit 6793b79 Notes)

**Location:** `devcontainer-config/install.sh:445`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `installed_parent` records under three `script -qec` command strings; does not establish values on macOS `script`, whose argument syntax differs.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r1: "Does not establish that `installed_parent` is `script` under other wrappings. A wrapper that interposes a shell (`script -c "sh -c 'bash install.sh; …'"`) or `setsid` would record something else, so it is an audit trace, not a proof." · r2: E3 recorded `SHELL=/bin/sh: installed_parent=sh` (and `script` under bash/zsh); "It does not establish that 'script' appears whenever a pty wrapper was used, and it does not establish that a human run never shows it." · r3: "the decision's revisit trigger (`037:64`, 'backup stamp with no human at the terminal') cannot rely on it" · escalation: see Escalations E4.

(r3) `:445` records the comm of `$PPID`, the installer's immediate parent. That parent is `script` only when `script`'s `$SHELL -c` execs the command directly, i.e. a single simple command. In P8, `script -qec "env -u CLAUDECODE $INSTALL"` recorded `installed_parent=script`, and so did `script -qec "cd $ROOT && env -u CLAUDECODE ./devcontainer-config/install.sh"`. But `script -qec "bash -c 'env -u CLAUDECODE $INSTALL; echo done'"` recorded `installed_parent=bash`, which is what a human's interactive bash would leave. The pty-wrapped install succeeded with no trace. An agent trying to bypass the rule needs only a compound command.

**Evidence:** `devcontainer-config/install.sh:445`; r3 `probe.txt` (P8); r2 `experiments.log` (E3); r1 `exp-E1-E5-E6-E7.txt` (E6)

---

## Claim 23: "Until it lands, every install.sh commit still carries a `Live-verified:` trailer by hand."

**Location:** `docs/decisions/035-install-sh-gating.md:86-92`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two commits in this range that touch install.sh (1514518, 6793b79); does not establish anything about commits outside the range, or whether either trailer's host check has been done (both say `Live-verified: no`).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: both trailers say `Live-verified: no`; the host check is not done.

(r1) 1514518: `Live-verified: no — run ./devcontainer-config/install.sh on the host and confirm the devcontainer diff, prompt and bless behave as before (plan step 9)`. 6793b79: `Live-verified: no — on the host run ./devcontainer-config/install.sh, read the ~/.claude review …` (from `git log --format=%B 712c626..d0fdd04`).

**Evidence:** `docs/decisions/035-install-sh-gating.md:86-92`; commits 1514518, 6793b79

---

## Claim 24: "Every existing non-interactive devcontainer run is unchanged apart from one extra line." (also `:52` "scripted callers see one extra line, not a new behavior"; and the sub-decision "It is skipped, with a message, when `--yes` is given or stdin is not a TTY.")

**Location:** `docs/decisions/037-bare-host-copy-install.md:31-33`, `docs/decisions/037-bare-host-copy-install.md:52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the delta in non-interactive output; does not establish that the skip list is complete, because the code also skips on CLAUDECODE, which this bullet omits.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r2: "The skip list in this bullet leaves out the third condition, which the code implements at `install.sh:297-300` and which README.md:22-23, the `--help` text and the commit all name."

(r2) This is the same finding as Claim 13. E6 shows the Aborted-line suffix `(devcontainer config)` and a blank line in addition to the Skipped line, so the delta is more than one extra line.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:31-33`; `devcontainer-config/install.sh:293-304`; r2 `experiments.log` (E6); r1 `exp-E1-E5-E6-E7.txt` (E1); r3 `probe.txt` (P1a, P1b)

---

## Claim 25: "Provenance is `~/.claude/.claude-workflows-manifest`, in the same format link-claude-home writes."

**Location:** `docs/decisions/037-bare-host-copy-install.md:38`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file name and base keys (the host version adds `installed_by/parent/at`); does not establish that any consumer (health-check) tolerates the extra keys.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "Does not establish that any consumer (health-check) tolerates the extra keys."

(r1) `devcontainer-config/link-claude-home.sh:70-71`: `if [ -f "$SRC/.manifest" ]; then` / `cp -f "$SRC/.manifest" "$DEST/.claude-workflows-manifest" 2>/dev/null || true`. The host target copies the same `assemble`-written `.manifest` to the same name (`install.sh:442`), then appends to it (Claim 21).

**Evidence:** `devcontainer-config/link-claude-home.sh:70-71`; `devcontainer-config/install.sh:121-127`, `devcontainer-config/install.sh:441-447`

---

## Claim 26: "In this session the Bash tool has no TTY (verified 2026-09-23: fd 0 is `/dev/null` and `tty` prints "not a tty") … But util-linux `script` can wrap the installer in a pty, which is how the tests drive it. The check stops accidents, not intent."

**Location:** `docs/decisions/037-bare-host-copy-install.md:50`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the agent Bash tool having no TTY, `script` supplying one, and an install going through; does not establish the parenthetical "fd 0 is `/dev/null`" across sessions (r2's session had fd 0 as a socket), nor behavior of other harnesses or the user's host shell.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1 (its Claim 9, which spans install.sh:290-292 and this line): "Does not establish … 037's specific 'fd 0 is /dev/null' observation (only `[ -t 0 ]` was checked)." · r2: "In this session fd 0 was a socket (`/proc/$$/fd/0 -> socket:[…]`). That is a different session and does not contradict the dated observation, but the detail does not reproduce."; output was run inline, not captured to a log · r3: observed `/proc/self/fd/0 -> /dev/null`; "This output was read in the terminal and not captured to a file. That is a provenance gap."

(r3) Command `bash scratchpad/cfc-r3/misc.sh` (cwd the scratchpad; exit 0; 2026-09-23T23:33Z) printed `not a tty` and `/proc/self/fd/0 -> /dev/null`. (r2) Under `script -qec`, `tty` printed `/dev/pts/1` and `CC=unset`, and E1 installed:

```
CLAUDECODE=1
not a tty
/proc/458271/fd/0 -> socket:[158109687]
/dev/pts/1
CC=unset
```

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:50`; `test/install-host.bats:101-104`; `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-r3/misc.sh`; r2 `experiments.log` (E1); r1 `exp-E1-E5-E6-E7.txt` (E5)

---

## Claim 27: "The backstop is sandbox `denyWrite ~/.claude` (guide §3)."

**Location:** `docs/decisions/037-bare-host-copy-install.md:50`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that guide §3 recommends `denyWrite` on `~/.claude`; does not establish that the user's host has it set, that it applies to an installer launched via `script` from the sandboxed Bash tool, or that an agent can't reach install.sh unsandboxed (`dangerouslyDisableSandbox`, excluded commands).
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r2: "It also does not cover the devcontainer target's write to `~/.config/claude-devcontainer`, which denyWrite `~/.claude` does not cover. Decision 037 itself says '~/.config is agent-writable on a bare host'." · r2: the brief's phrase "the only hard barrier" does not appear in the changed files (grep returned nothing); the guide's accepted-gaps list names two backstops, sandbox denyWrite and the PostToolUse config audit (`guides/bare-host-hook-wiring.md:122-124`) · r3: `dangerouslyDisableSandbox` "prompts the user rather than being denied"; "a Bash-level denyWrite on `~/.claude` would make the copy step fail and self-undo (Claim 9)"; plan Risks line 216: "A host without that sandbox setting has no hard barrier".

(r1) `guides/bare-host-hook-wiring.md:74-76`: "`denyWrite` to `~/.claude`, `~/CLAUDE.md` and the auditor script. … Bash sees `~/.claude` as read-only." Verification needs execution: a sandboxed agent Bash call on the user's host running `script -qec 'env -u CLAUDECODE ./devcontainer-config/install.sh' /dev/null` against a canary CLAUDE_CONFIG_DIR under `~/.claude`. That cannot be done here, because it needs the host's settings.json sandbox block and the real `~/.claude`.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:50`; `guides/bare-host-hook-wiring.md:74-77`, `guides/bare-host-hook-wiring.md:122-124`; `docs/working/plan-copy-install-bare-host.md:216`

---

## Claim 28: "copies to `.cw-new.<name>`, moves the old entry (link or dir, never with a trailing slash) to the backup, and only then moves the new copy into place."

**Location:** `docs/decisions/037-bare-host-copy-install.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of operations; does not establish recoverability or a recovery message when step 2 or step 3 fails partway, and no doc claims either.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r3: P6 failure residue (live `~/.claude` missing CLAUDE.md and skills, `.cw-new.*` stranded, only mv's error printed) "is outside the claim, reported because the brief asked" (same residue as Claim 18).

(r3) The order is as stated. `:423-427` moves to `$backup`, then `:431-437` runs `mv "$dest/.cw-new.$name" "$dest/$name"`. Neither step 2's `mv` nor step 3's has error handling, and `set -e` stops the script at the first failure. In P6, `workflows/` was made read-only. The run printed only `mv: cannot move '…/.claude/workflows' to '…/.claude-workflows-backup/20260923T233237Z/workflows': Permission denied` and then `[exit=1]`.

**Evidence:** `devcontainer-config/install.sh:408-437`; r3 `probe.txt` (P6)

---

## Claim 29: "The installer copies the whole `hooks/` directory (including `hooks/lib/`) and the whole `scripts/` directory, so hooks that find their helpers by their own path (`log-usage.sh` → `lib/usage-common.sh` and `../scripts/lib/`; `claude-config-audit.sh` → `../scripts/claude_config_audit.py`) keep working."

**Location:** `guides/bare-host-hook-wiring.md:16-21`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers log-usage.sh end to end (T9 with the real hooks/ and scripts/) and the static paths of claude-config-audit.sh; does not establish a run of claude-config-audit.sh from the installed copy, or the other hooks' runtime behavior after install.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "'Every hook is a copy' holds because the repo's payload dirs contain no symlinks today (`find skills workflows guides patterns hooks scripts -type l` returned nothing). `cp -r` would copy a future in-repo symlink as a link." · r2: "`~/.claude/scripts/…` is inside the `~/.claude` subtree that §3's denyWrite covers."

(r1) `hooks/log-usage.sh:11`: `source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/usage-common.sh"`, and `:14`: `…/../scripts/lib/skill-paths.sh"`. `hooks/claude-config-audit.sh:47-48`: `HOOK_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")` / `AUDIT_SCRIPT="$HOOK_DIR/../scripts/claude_config_audit.py"`. T9 passes: the installed `log-usage.sh` exits 0 and writes `"smoke"` to the hermetic usage log.

**Evidence:** `guides/bare-host-hook-wiring.md:16-21`; `hooks/log-usage.sh:11-14`; `hooks/claude-config-audit.sh:43-49`; `devcontainer-config/install.sh:93`; r1 `bats-head.txt` (T9); r2 `install-host-head.log` (T9); r3 `head-install-host.txt` (ok 9)

---

## Claim 30: "`install.sh` does not write `settings.json`, but it prints a `REMINDER` pointing here whenever the installed `hooks/wiring.json` is missing or differs from the repo's." (code: "REMINDER: hooks/wiring.json changed (or was not installed before).")

**Location:** `guides/bare-host-hook-wiring.md:61-64`, `devcontainer-config/install.sh:381-384`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing, unchanged and changed cases after a y; does not establish a reminder when the user declines (none is printed even if wiring.json differs), or whether the reminder names the correct §2 anchor text.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "The guide's 'whenever' is true only for installs that complete." · r3: "`cmp` exits 2 on a missing file, so a missing file counts as changed."

(r1) `if ! cmp -s "$dest/hooks/wiring.json" "$stage/hooks/wiring.json"; then` / `wiring_changed=1` (`install.sh:382-383`). The REMINDER is printed at `:453-458`. No path in the function writes `settings.json`, which is only read by `grep` at `:362`. T7 (settings byte-identical) and T11 pass.

**Evidence:** `devcontainer-config/install.sh:362`, `devcontainer-config/install.sh:381-384`, `devcontainer-config/install.sh:453-458`; r1 `bats-head.txt` (T7, T11); r2 `install-host-head.log` (T11); r3 `probe.txt` (P4), `probe9.txt`, `head-install-host.txt` (ok 11)

---

## Claim 31: "`claude-config-audit.sh` looks for the auditor at `CLAUDE_CONFIG_AUDIT_SCRIPT`, then `<hook dir>/../scripts/`, then `~/private_reviews/`. … With the `install.sh` copy, the second of those is `~/.claude/scripts/claude_config_audit.py`"

**Location:** `guides/bare-host-hook-wiring.md:82-85`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the resolution order; does not establish the "If it finds none, the hook does nothing" branch (not read past `:49`).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r1+r3: the "does nothing" branch was not read · r3: sandbox coverage of the installed path was not established · r2 (in its Claim 17 prose): "The same excerpt also confirms the §3 resolution order."

(r1) `hooks/claude-config-audit.sh:43-49`: `if [[ -n "${CLAUDE_CONFIG_AUDIT_SCRIPT:-}" ]]; then` … `AUDIT_SCRIPT="$HOOK_DIR/../scripts/claude_config_audit.py"` / `[[ -f "$AUDIT_SCRIPT" ]] || AUDIT_SCRIPT="$HOME/private_reviews/claude_config_audit.py"`. With the hook copied to `~/.claude/hooks`, `readlink -f` resolves to the hook itself, so `HOOK_DIR/..` is `~/.claude`.

**Evidence:** `hooks/claude-config-audit.sh:31-49`; `guides/bare-host-hook-wiring.md:82-87`

---

## Claim 32: "Skipped, before reading or staging anything and without affecting the exit status, on --yes, when CLAUDECODE is set, or when stdin is not a TTY." / "Declining the devcontainer target now continues to the host target; the run still exits 1 when anything was declined." (commit 6793b79)

**Location:** `devcontainer-config/install.sh:190-199`, `devcontainer-config/install.sh:461-464` (commit 6793b79)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers devcontainer-n then host-n (exit 1), devcontainer-y then host-n (exit 1), and devcontainer-n then host-y (exit 1); does not cover the "otherwise unchanged" part (Claim 33) or output wording.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Does not establish the n/y exit status under test (T6 does not assert status)" (static from `:196` and `:464`) · r3: executed n/y directly in P9, which installed and still ended `[exit=1]`.

(r1) `echo "Aborted. Nothing was changed. (devcontainer config)"` / `DECLINED=1` / `return 0` (`install.sh:195-197`). T5 and T17 (`n\nn\n`) reach the host prompt. T17 and T19 assert `status -eq 1`. r3's P3b/P3c (`n,n`) showed the host review, then `[exit=1]`.

**Evidence:** `devcontainer-config/install.sh:190-198`, `devcontainer-config/install.sh:386-390`, `devcontainer-config/install.sh:461-464`; r1 `bats-head.txt` (T5, T17, T19); r2 `install-host-head.log`; r3 `probe.txt` (P3b, P3c), `probe9.txt`

---

## Claim 33: "Non-interactive devcontainer runs are otherwise unchanged." (commit 6793b79)

**Location:** `devcontainer-config/install.sh:195` (commit 6793b79)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit codes and the effects on the devcontainer install, which are unchanged; does not cover output text: the closed-stdin decline line gained ` (devcontainer config)`.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** none

(r2) This is the same finding as Claims 9 and 13. `echo "Aborted. Nothing was changed. (devcontainer config)"` at `install.sh:195` differs from the old `echo "Aborted. Nothing was changed."`, as E6 records.

**Evidence:** `devcontainer-config/install.sh:195`; r2 `experiments.log` (E6); r1 `exp-E1-E5-E6-E7.txt` (E1)

---

## Claim 34: "All 24 fail against the current install.sh (T7 and T16 were tightened so they cannot pass when nothing is installed)." (commit dcf4a6d)

**Location:** `test/install-host.bats:106-391` (commit dcf4a6d)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dcf4a6d's tree, whose install.sh is byte-identical to 712c626's (`diff` printed `same`); does not establish why each test fails (for example, T15 fails on exit status, not on a host-target assertion).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the per-test failure reason was not inspected.

(r1) `bats-old.txt`: `not ok 1` through `not ok 24`, exit=1. T7 and T16 carry the tightening guards `[ -d "$CLAUDE_HOME_DIR/skills" ] && [ ! -L "$CLAUDE_HOME_DIR/skills" ]   # the install ran` and `[[ "$output" == *'nothing was replaced'* ]]`. r2 (`install-host-old.log`) and r3 (`dcf4a6d-install-host.txt`: `ok=0 notok=24`) got the same result.

**Evidence:** `test/install-host.bats` (T7, T16); r1 `bats-old.txt`; r2 `install-host-old.log`; r3 `dcf4a6d-install-host.txt`, `exits.txt`

---

## Claim 35: "test/install-host.bats 24/24 · test/cc-isolated-functions.bats 90/90 (unmodified) · test/link-claude-home-wiring.bats 14/14 · test/hooks/*.bats 144/144 (6 files)" (commit d0fdd04; also 1514518's and 6793b79's "90/90" and "24/24")

**Location:** `test/link-claude-home-wiring.bats:256-272` (commit d0fdd04)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these four suites at d0fdd04 in this Linux sandbox; does not establish results on the user's host or macOS, or the counts at the intermediate commits 1514518 and 6793b79.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "It also does not establish that the edited test 14 still catches its stated mutations." · r3: "The '(unmodified)' part was not rechecked by diff." · r1: `git diff 712c626..d0fdd04 --stat -- test/cc-isolated-functions.bats` is empty, so that file is unmodified.

(r3) Commands run from `…/cfc-r3/tree-d0fdd04`, all exit 0: `bats test/install-host.bats` 24 ok / 0 not ok; `bats test/cc-isolated-functions.bats` 90/0; `bats test/link-claude-home-wiring.bats` 14/0; `bats test/hooks/` 144/0 over 6 files. r1 (`bats-head.txt`, `suites-summary.txt`) and r2 (per-suite logs) got the same counts.

**Evidence:** `test/link-claude-home-wiring.bats:270-271`; r3 `head-install-host.txt`, `head-ccif.txt`, `head-lchw.txt`, `head-hooks.txt`, `exits.txt`; r1 `bats-head.txt`, `suites-summary.txt`; r2 `install-host-head.log`, `cc-isolated.log`, `link-wiring.log`, `hooks.log`

---

## Claim 36: "test/guide-index-sync.bats, test/cross-reference-integrity.bats, test/fixture-hermeticity.bats pass · scripts/run-tests.sh --fast: 864 ok, 0 not ok (1m23s)" (commit d0fdd04)

**Location:** commit d0fdd04 message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not run by the winning replicate; does not establish anything about these suites.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
**Replicate annotations:** merge note: the Unverifiable verdict is r3's, and r3 did not run these suites. r1 executed them: guide-index-sync 1/0, cross-reference-integrity 1/0, fixture-hermeticity 2/0 (`suites-summary.txt`) and run-tests.sh --fast 864/0, exit 0 (`run-tests-fast.txt`). r2 executed run-tests.sh --fast, 864 ok / 0 not ok, exit 0, 1m31s (`run-tests-fast.log`). r2: the three named files were "assume[d] … inside the 864-test fast run (not checked file by file)" · r3 (out of scope): "the 864-test fast suite and three docs bats files (not run)".

(r3) Paraphrased — no quote available because this is an unexecuted test-count claim. Verdicting it requires execution, and it was not run within this pass's budget. To verify, run `scripts/run-tests.sh --fast` and the three named bats files from the d0fdd04 tree.

**Evidence:** commit d0fdd04 message; r1 `suites-summary.txt`, `run-tests-fast.txt`; r2 `run-tests-fast.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`README.md:21-22`, `devcontainer-config/install.sh:42-43`): "only installs for a human at a terminal" is false. An agent's Bash tool clears both checks with `env -u CLAUDECODE script -qec … /dev/null`, and this branch's own test suite does exactly that. Reword to match install.sh:290-292 and 037.
- **Claim 16** (`devcontainer-config/install.sh:350-353`): the review prints `REPLACE symlink … with a copy` for foreign per-file links, which get no copy and are only moved. Print REPLACE only when the stage has the path.
- **Claim 22** (`devcontainer-config/install.sh:445`, commit 6793b79): `installed_parent` records `bash`/`sh`, not `script`, when the pty wrapper runs a compound command or `SHELL=/bin/sh`. It is not a reliable audit trace for the agent-bypass case.

### Mostly Accurate
- **Claim 4** (`README.md:26-29`): a dangling per-file link inside an owned dir aborts the review with `could not diff payload item 'hooks'`. The error doesn't name the path, and the README gives no recovery step.
- **Claim 5** (`README.md:31-32`): "Everything replaced … is moved" holds only when the run reaches the swap (dangling-link abort; step-2 failure).
- **Claim 8** (`devcontainer-config/install.sh:53-61`, commit 1514518): `-h/--help` is a second observable change, and `--yes extra` now exits 2.
- **Claim 9** (`devcontainer-config/install.sh:192-195`): the Aborted line keeps its old wording only as a prefix; it now ends with ` (devcontainer config)`.
- **Claim 12** (`devcontainer-config/install.sh:287-289`): the verdict is carried by r1's and r2's compound claims. Their defect is Claim 13's; the ordering itself holds (r3 Verified).
- **Claim 13** (`devcontainer-config/install.sh:287-289`): non-interactive output gains a blank line plus the skip line, and the decline line gains a suffix. That is more than "one line".
- **Claim 17** (`devcontainer-config/install.sh:370-371`): "(the checkout)" holds only for the README's old links.
- **Claim 24** (`docs/decisions/037-bare-host-copy-install.md:31-33`, `:52`): "one extra line" is really a blank line, the skip line and the suffix. The skip list also omits CLAUDECODE.
- **Claim 33** (commit 6793b79): "otherwise unchanged" leaves out the Aborted-line suffix.

### Unverifiable
- **Claim 27** (`docs/decisions/037-bare-host-copy-install.md:50`): the sandbox `denyWrite ~/.claude` backstop needs a sandboxed, `script`-wrapped agent run on the user's host against a canary dir.
- **Claim 36** (commit d0fdd04): r3 did not run these suites, but r1 and r2 executed them and reproduced the counts (see annotations).

## Escalations

- **E1** · `README.md:21-22`, `devcontainer-config/install.sh:42-43` · r1 (Goal-Alignment Escalate) · addressee: orchestrator. "Claim 2 (README and `--help` overstate the TTY guard as human-only)", to fix before the plan-step-9 host run. (Merged Claim 2.)
- **E2** · `devcontainer-config/install.sh:408-437` · r1 (Escalate; its Claim 12 Legibility-target routes "the step-2/3 residue [as] a for-author item for the critics"; its Out-of-scope leaves "code-quality judgments on the residues … to the critics"), r2 (Escalate), r3 (the "Additional brief item" under its Claim 10) · addressee: orchestrator (critics, unnamed). A failure in step 2 (move-aside) or step 3 (swap) partly empties the live `~/.claude` with no recovery message, and this lands on the user's real host in plan step 9. (Merged Claims 18, 28.)
- **E3** · `README.md:31-32`, `devcontainer-config/install.sh:145-151` · r2 (Escalate), r3 (its Claim 2a attention item) · addressee: orchestrator. A dangling per-file link blocks the migration, and the only error is `could not diff`, which doesn't name the path. (Merged Claims 4, 5.)
- **E4** · `devcontainer-config/install.sh:445` · r3 (Escalate), r2 (its Claim 12b attention item: "as an audit trace it can be evaded") · addressee: orchestrator. A compound command dodges the audit trace that the TTY residual relies on. Decision 037's revisit trigger (`037:64`) cannot rely on it. (Merged Claim 22.)
- **E5** · `devcontainer-config/install.sh:309-331` · r1 ("Residues on Verified claims … the adjacent behavior is unguarded"), r2 ("Residuals recorded in Verified claims' Scope fields (for synthesis)") · addressee: orchestrator (synthesis). A `~/.claude` symlinked to a non-checkout directory is written through silently, and the review's `Destination:` line doesn't mention the link. (Merged Claim 15.)
- **E6** · `devcontainer-config/install.sh:345-368` · r1 (Residues section) · addressee: orchestrator (synthesis). Foreign empty directories move without a MOVE line. The WIRED check matches the basename only, so a nested `hooks/lib/x.sh` is checked as `hooks/x.sh`. (Merged Claims 4, 16.)
- **E7** · `devcontainer-config/install.sh:408-437` · r2 (Residuals section, E5b executed), r3 (Out of scope: "concurrent-run races (inferred only)"), r1 (Claim 12 Scope, "not run") · addressee: orchestrator. Concurrent runs collide on `.cw-new.*` and the backup stamp. In r2's E5b the destination ended with none of the seven entries. (Merged Claims 19, 20.)
- **E8** · macOS / BSD `script`, `sort -z`, `find -print0` (`devcontainer-config/install.sh:345-369`, `:290-292`) · r1, r2, r3 (Out of scope) · addressee: orchestrator. Untested on macOS. BSD `script` takes different arguments.
- **E9** · `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/fc/` · r3 (Escalate) · addressee: orchestrator. Sibling replicates shared `scratchpad/fc/`. One of r3's Writes overwrote a pre-existing `fc/probe.sh`, and r3's first `fc/run-suites.sh` collided there too: "A sibling that relied on `fc/probe.sh` may have run my content." r3's own evidence comes from the isolated `scratchpad/cfc-r3/`. r1's header records drivers run from `$scratch/fc` (`exp.sh`, `run-suites.sh`, `run-fast.sh`), with copies saved in r1's log dir.
- **E10** · commit d0fdd04 message · r3 (Out of scope: "the 864-test fast suite and three docs bats files (not run)") · addressee: orchestrator. Merged Claim 36 is Unverifiable on r3's verdict, but r1 and r2 executed those suites. See the Claim 36 annotations before treating it as open.

## Verdict stability

- **Total clusters (merged claim rows):** 36
- **Agreed (all reporting replicates gave the same verdict, `(compound)` counted at face value):** 28, of which 4 are single-replicate detections (Claims 1, 23, 25, 28) and 3 were surfaced by two replicates (Claims 10, 11, 31)
- **Disagreed:** 8
  - Claim 2: r1=Incorrect · r2=Verified (compound) · r3=Verified (compound)
  - Claim 4: r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
  - Claim 5: r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
  - Claim 12: r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Verified
  - Claim 16: r1=Verified (compound) · r2=Verified · r3=Incorrect
  - Claim 17: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 22: r1=Verified (compound) · r2=Mostly accurate · r3=Incorrect
  - Claim 36: r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
- **Agreement rate:** 28/36 = 77.8% (24/32 = 75.0% excluding single-replicate detections). All 3 merged Incorrect verdicts come from a single replicate (r1 once, r3 twice). This is below the ≥90% falsifier for dropping to k=2.

## Submitted Claims

## Claim 38: "With the README's old install (top-level entries and per-file hook links into the checkout), a y moves each old link into `.claude-workflows-backup/<stamp>/` as a link, and no checkout file's bytes or listing change."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:408-437`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the README symlink layout reproduced from `test/install-host.bats` `symlink_install`: CLAUDE.md plus five top-level dir links, a per-file `hooks/h.sh` link, and a copied `hooks/guard.py`. The run answered `n` for the devcontainer target and `y` for the host target, on a single local filesystem. It does not cover a checkout reached through a bind mount (the critic's own caveat) or a top-level `hooks` link. The repo snapshot leaves out `devcontainer-config/claude-home/`, the gitignored staging dir that `install_devcontainer` rebuilds on every run (`:172`), even when that target is declined.

Probe `p38_41.sh` printed `REPO UNCHANGED`: the listing (with link targets) and the sha256 of every file under the fake checkout matched before and after. The backup dir `.claude-workflows-backup/20260923T235539Z/` held `CLAUDE.md l`, `guides l`, `patterns l`, `scripts l`, `skills l` and `workflows l`, each still pointing into the repo. It also held `hooks d`, containing `hooks/h.sh l` (still a link) and `hooks/guard.py f`. The live entries were all regular files or directories afterwards, and `hooks/h.sh` was a regular file. The move is a plain `mv` with no trailing slash:

```bash
# devcontainer-config/install.sh:423-427
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
```

**Evidence:** `devcontainer-config/install.sh:423-427`, `:431-437`; probe output `REPO UNCHANGED` plus the backup listing above.

---

## Claim 39: "The `resolves inside the repo checkout` destination guard refuses a checkout path given as: trailing slash, relative non-existent path, dot segments, and a symlinked ancestor — each run prints the ERROR and exits before staging, leaving the repo unchanged."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:255-271`, `:316-318`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** The four named forms were each run with `n\ny` answers in a pty. The claim is true for dot segments that pass only through **existing** directories. It is false for a dot segment that passes through a **non-existent** component.

**Refused as claimed.** All six variants below printed `ERROR: … resolves inside the repo checkout`, exited 1 and left the repo unchanged:
- `$ROOT/`
- `nonexist/sub` with cwd = `$ROOT`
- `$ROOT/skills/../x`
- `$S/outside/../repo`
- `$S/lnk/claude` and `$S/lnk`, where `lnk -> $ROOT`

**Counterexample.** With `CLAUDE_HOME_DIR=$S/nx/../repo`, where `nx` does not exist, the guard passed. The run printed the host `Canonical (repo):` line and asked the y/N question. On `y` it printed `Installed into $S/nx/../repo.`, and the repo snapshot changed. The repo's own `guides/`, `hooks/`, `patterns/` and the other entries were moved into `$ROOT/.claude-workflows-backup/<stamp>/`, and copies were swapped in. `$S/nx/../repo/sub` behaved the same way, writing a full install into `$ROOT/sub/`.

The cause is in `resolve_phys`. It walks up with `basename`/`dirname` until it reaches a directory that exists, then appends the `..`-bearing tail literally. The resulting string starts with `$S/`, not the repo root, so `inside_repo` returns false. Later, `mkdir -p "$dest"` (`:395`) creates `nx`, and the kernel resolves `..` into the checkout:

```bash
# devcontainer-config/install.sh:257-264
resolve_phys() {
  local p="$1" tail=""
  while [ ! -d "$p" ]; do
    tail="/$(basename "$p")$tail"
    p="$(dirname "$p")"
  done
  echo "$(cd "$p" && pwd -P)$tail"
}
```

The trigger needs `CLAUDE_HOME_DIR` or `CLAUDE_CONFIG_DIR` set to a hand-crafted path. The default `~/.claude` is not affected. The review still shows the destination string, but the string does not name the checkout. Possible fixes: reject any `..` segment left in `tail`, or re-run the guard after `mkdir -p "$dest"` on the now-existing path.

**Evidence:** `devcontainer-config/install.sh:257-264`, `:266-271`, `:316-318`, `:395`; `p39.sh` output (`dot-thru-missing`, `dot-thru-missing-sub`: `repo CHANGED`).

---

## Claim 40: "The skip rules run before `mktemp`/`assemble`, so a `--yes`, no-TTY or CLAUDECODE run creates no stage and writes nothing under the host destination."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:279-305`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers four modes, each with the host destination either absent or holding the README symlink layout:
- `--yes` under a pty
- piped `n\ny`
- `</dev/null`
- `CLAUDECODE=1` under a pty

This is about the host target only. The devcontainer target's `assemble "$SRC/claude-home"` (`:172`) still runs first and writes the gitignored staging dir inside the checkout, as it did before this branch.

In each probe, `TMPDIR` pointed at a path that does not exist. Any `mktemp` would therefore have failed under `set -e` before the skip line could print. All 8 runs printed the expected `Skipped host target …` line and never printed `=== Host target:`. The destination snapshot was unchanged in all 8, `TMPDIR` was never created, and the exit status matched the devcontainer answer: 0 for `--yes`, 1 where `n` or EOF declined it. The three `return 0`s (`:293-304`) come before the guards (`:310`) and the `mktemp` (`:333`).

**Evidence:** `devcontainer-config/install.sh:293-304`, `:333-335`; `p40.sh` output (8/8 `dest UNCHANGED`, no TMPDIR created).

---

## Claim 41: "A y leaves `settings.json`, `settings.local.json`, `projects/`, `memory/`, `logs/` and `.credentials.json` in the destination byte-identical."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:392-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a successful `y` from the README symlink layout. Checked: sha256 of the three files, listing and sha256 of every file under `projects/`, `memory/` and `logs/`, plus mode and mtime of the three files. Not covered: runs after a step-2 or step-3 failure (the critic's caveat). Statically, those steps only ever `mv` or `rm -rf` the seven `CLAUDE_HOME_NAMES` and `.cw-new.*`.

Probe `p38_41.sh` printed `HOST STATE UNCHANGED`. The only writes outside the seven names and `.cw-new.*` are the backup dir and the manifest. The manifest write is `rm -f` followed by `cp` and `>>` on `.claude-workflows-manifest` (`:441-447`). `settings*.json` is only read, by `grep -qsF` (`:362`).

**Evidence:** `devcontainer-config/install.sh:362`, `:397-399`, `:423-427`, `:441-447`; probe output `HOST STATE UNCHANGED`.

---

## Claim 42: "The backup is a `mv` into a directory under `$dest`, so on a single-filesystem `~/.claude` it is one rename per entry, not a second full copy; only the staging copy (`cp -R` into `.cw-new.*`) costs payload-size I/O."

**Submitted by:** performance-reviewer
**Location:** `devcontainer-config/install.sh:408-437`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** The rename half was confirmed with inode and device numbers. `strace` is not installed, so syscalls were not traced. The "only" half is checked against the whole `install_claude_home` function, not just `:408-437`.

**Rename: confirmed.** After a first install, a second `y` moved the real `CLAUDE.md`, `skills` and `hooks` into the backup with the same inode and device numbers (e.g. `skills ino=434125 dev=136` before and `backup skills ino=434125 dev=136` after). That is a rename, not a copy.

**"Only the staging copy": overstated.** There are two payload-size copies per host run, not one:
1. `assemble "$stage"` (`:335`) runs `cp -r` on every source from the checkout into `$TMPDIR/cw-host-stage.*`, whatever the answer.
2. `cp -R "$stage/$name" "$dest/.cw-new.$name"` (`:399`) runs on `y`.

`review_diff` also reads both trees in full. Each `y` also leaves a new payload-size backup dir, even with no changes: 5 no-change `y` runs left 5 backup dirs totalling 12M for a 2.1 MB payload. Retained disk grows per install until the user deletes backups, though no copy I/O is spent on them.

**Evidence:** `devcontainer-config/install.sh:333-335`, `:397-399`, `:423-427`; `p42_43.sh` inode output; backup count `5`, `du` `12M`.

---

## Claim 43: "The whole interactive two-target run with no changes costs about 0.27 s wall on a ~108-file payload."

**Submitted by:** performance-reviewer
**Location:** `devcontainer-config/install.sh` (whole script)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The payload was copied from this worktree's real seven sources: 109 files, 2,140,471 bytes. Timing is on this WSL2 machine, under `script` with piped answers, after a first install so both reviews print `(none …)`. The devcontainer `--bless` is an echo stub; a real `cc-isolated.sh --bless` is not measured. This is one machine, as the claim says.

Wall times (5 runs each):
- `y\ny`: 0.276–0.279 s
- `n\nn`: 0.273–0.277 s, with one outlier at 1.840 s

Both reviews printed `(none …)` in every run. The order of magnitude and the ~0.27 s figure hold.

**Evidence:** `p43only.sh` output (`none-lines=2` on every run).

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 39** (`devcontainer-config/install.sh:257-264`): the inside-checkout guard is bypassed by a `..` segment through a non-existent component (`CLAUDE_HOME_DIR=<outside>/nx/../<repo>`). A `y` then moves the checkout's own entries into a backup inside the checkout. Fix: reject a `..` left in `resolve_phys`'s tail, or re-run the guard after `mkdir -p "$dest"`.
- **Claim 42** (`devcontainer-config/install.sh:335`, `:399`): the backup is a rename, but there are two payload-size copies (`assemble` into `$TMPDIR` plus `.cw-new.*`), and every `y` adds a full-payload backup dir, even with no changes.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes. All six submitted claims have verdicts, each from a hermetic execution.
- Out of scope: freshly harvested claims from the diff (intake was limited to submitted claims); bind-mounted checkouts; a real `cc-isolated --bless`.
- Escalate: Claim 39's guard bypass. It is minor, since it needs a hand-crafted `CLAUDE_HOME_DIR`, but a `y` can then rewrite the checkout.
