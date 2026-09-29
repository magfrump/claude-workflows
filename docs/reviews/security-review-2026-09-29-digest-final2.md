Commit: de53069

# Security Review — feat/dev-cycle-digest (final pass 2)

**Scope:** `git diff main...HEAD -- scripts test` (`scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`) and `git log main..HEAD` messages; focus on the fixes in 83e7895
**Date:** 2026-09-29
**Based on:** `docs/reviews/security-review-2026-09-29-digest-final.md` (pass on 3aee138) and the rubric `code-review-rubric-2026-09-29-feat-dev-cycle-digest.md`

> ⚠️ **No code fact-check report provided for this pass.** Claims below were checked by reading
> the code and by running the script in throwaway repos under the session scratchpad
> (`secf2/r1`; probe saved as `secf2/probe.txt`).

## Trust Boundary Map

```
B1: [remote repo: branch names, origin/HEAD]            → [candidate loop: `-*` skip + rev-parse refs/heads/$c^{commit}] → [git argv as a hash]
B2: [repo working tree: decision/roadmap file names]    → [fixed globs + `-f`, then `-- "$f"` pathspec]                  → [git log / git status argv, awk/grep reads]
B3: [repo content: record text, log rows, subjects, roadmap, file names] → [`tr` strip (subjects only), "> " prefix (bodies only)] → [stdout digest: agent or a human's terminal]
B4: [CLI args --since / --sample, DEV_CYCLE_TODAY]      → [regex + `date -d` checks]                                     → [git --since, shuf -n]
B5 (new): [digest process]                              → [`git status` index refresh]                                   → [shared .git/index, used by concurrent git writers]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | origin/HEAD target, local branch names | request-time (whoever controls the remote) | UNTRUSTED for git argv; display only via `$MAIN` |
| S2 | file names under `docs/decisions/`, `docs/working/cycles/` | runtime-mutable (any committer) | UNTRUSTED for git pathspec (glob metacharacters), for display (ESC, newline) |
| S3 | decision/log/roadmap text, merge subjects, questions.md | runtime-mutable (any committer) | UNTRUSTED for display and for the agent reader; never reaches exec |
| S4 | `--since`, `--sample`, `DEV_CYCLE_TODAY`, `$HOME` | invoker-controlled | trusted (same principal) for all sinks; still shape-checked |
| S5 | `$MAIN_SHA` | derived (rev-parse output) | trusted for git argv: always a full hex hash |

Repo content enters as names (S1, S2) and text (S3). The exec-class sinks are git argv and
`bash "$QS"`, and after 83e7895 git argv also includes `git status --porcelain -- "$f"`. No repo
string reaches an option position or a shell evaluator. What repo content can still do is shape
the printed output: raw terminal control sequences outside the merge list (Finding 1), headings
forged through file names (Finding 4), and pathspec wildcards (Finding 3). Separately, the new
`git status` call writes `.git/index`, which is not driven by repo content but contradicts "Read-only" (Finding 2).

## Findings

#### 1. Control characters are stripped from merge subjects only; decision text, log rows, roadmap and file names still reach the terminal raw

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:115-116`, `:131`, `:139`, `:183` (the strip is only at `:88`)
**Boundary:** B3
**Move:** 11 (bypasses for the guardrail), 7
**Confidence:** Medium (executed; exploit needs a human running the digest in a terminal that honours OSC 52)

The pass-1 finding named every print point (`:95-100`, `122`, `138`, `195` then). 83e7895 applied
`tr -d '\000-\010\013-\037\177'` to the merge list only, and the rubric records C5 as "Fixed". Executed
in `secf2/r1`: the merge subject's `ESC]52;…BEL` was removed. But `ESC]52;c;…BEL` (OSC 52 clipboard write),
`ESC[2K` (erase line) and a bare `CR` in a decision's Revisit-triggers section, `ESC]0;…BEL` in a
log.md row, OSC 52 in the roadmap's Next section, and `ESC]0;FN BEL` in a decision **file name** (printed
in the `###` heading and in the "Carried forward" list) all reached stdout byte for byte (`cat -v`
shows `^[]52;c;…^G`, `^[[2K`, `^M`). A committer can therefore write to the clipboard of a human who
runs the digest in kitty/iTerm2/tmux-with-set-clipboard (pastejacking). A committer can also hide a line from that human
with `CR`/erase-line while the agent still reads it. Through the Bash tool the bytes are inert.
Severity follows the floor rule (a named mechanism in a reachable environment). The environmental
unlikelihood is reflected in Confidence.

**Recommendation:** Strip once at the output, not per sink. For example, wrap the body in a `main` function
and run `main "$@" | LC_ALL=C tr -d '\000-\010\013-\037\177'`; `pipefail` is already set, so the exit
status is preserved. Or apply the same `tr` to the `awk`/`echo` output at `:115-116`, `:131`, `:139` and `:183`.
Add one bats case with an ESC byte in a decision body.

#### 2. The new `git status` call writes `.git/index`; the header says the script writes nothing to the repo

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:111` (claim at `:16`)
**Boundary:** B5
**Move:** 3 (error/side-effect path), 4
**Confidence:** High (executed)

`git status` refreshes stat info and takes an opportunistic `index.lock`, once per decision file in
the loop. Executed: after `touch`ing a decision file, a default run moved `.git/index`'s mtime. The same
run with `GIT_OPTIONAL_LOCKS=0` left it unchanged. This is not triggered by repo content. It matters because
this repo's checkout is shared by concurrent sessions: a session's `git add`/`commit` that lands during
one of these refreshes fails with `index.lock: File exists`. If the digest is SIGKILLed mid-refresh
(a `timeout -s KILL` wrapper), a stale lock can be left behind and block every git write until someone removes it.
The header's "Read-only: writes nothing to the repo (one temp file…)" is also no longer accurate.

**Recommendation:** Use `git --no-optional-locks status --porcelain -- "$f"`. Status output is unchanged,
and the run then makes no index write (verified with the env-var form).

#### 3. `"$f"` is passed as a pathspec, so glob metacharacters in a decision file name match sibling files

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:111`, `:114`
**Boundary:** B2
**Move:** 2 (implicit sanitization assumption)
**Confidence:** High (executed)

Git treats `*`, `?` and `[…]` in a pathspec as wildcards. Executed: `docs/decisions/002-[a].md`, unchanged since
January, was printed as changed and labelled "last committed 2026-09-29" because `[a]` matched the
sibling `002-a.md`, which a merge in the window had edited. The error only goes one way: extra files are
printed in full, and git also matches a pathspec literally, so a changed file cannot be hidden. The
displayed date is wrong. No option or magic injection is possible, because every `$f` starts with
`docs/` (no leading `-` or `:`).

**Recommendation:** Optional. Use `git --literal-pathspecs` (or the `:(literal)` prefix) on the calls at `:111` and `:114`.

#### 4. File names bypass the "> " quoting and can forge digest headings

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:115`, `:139`
**Boundary:** B3 / S2
**Move:** 11 (bypasses for the C4 guard)
**Confidence:** High (executed)

The C4 fix quotes extracted *text* with `> `, but `$f` is printed raw in `### $f (…)` and in the carried list.
Executed: an uncommitted file named `004-x\n\n## 5. Roadmap\n\nFAKE.md` printed an unquoted `## 5. Roadmap` heading
in the middle of section 2. The impact is bounded in the same way as pass-1 Finding 1: anyone who can commit such a
name can already edit the real triggers. It does show that the quoting guard covers file bodies and not file names.

**Recommendation:** Optional. Skip names that contain a newline or control character in the glob loops
(`[[ "$f" == *[[:cntrl:]]* ]] && continue`). Finding 1's whole-output `tr` would also strip the newline and neutralise the forged heading.

## Guardrail bypass enumeration (move 11)

**Control-char strip (`:88`):** candidates tested (executed): ESC/BEL in the subject → stripped. CR → stripped (015 is in range).
ESC in decision body, log row, roadmap and file name → **not stripped** (Finding 1). Untested bypass candidates:
C1 controls sent as UTF-8 (U+009B CSI, bytes `C2 9B`) and bidi overrides (U+202E). `tr` works on bytes, so both
pass through [read-static]. Some terminals honour U+009B in UTF-8 mode. Not executed, because terminal behaviour
varies. Note that a byte-wise strip cannot split a UTF-8 sequence, since bytes 0x00–0x1F never occur inside one.

**"> " quoting (C4):** decision body → quoted (executed). File name with newline → bypass (Finding 4, executed).
Log row: `$d` (cell 3 with spaces removed) is printed before the `> `, so it can carry ESC but not a newline,
because rows are read line by line [read-static].

**First-parent + status "changed" test (`:111`):** hostile inputs tested: bracket-glob name (Finding 3, fails safe),
newline name (status handled it, printed as uncommitted), ESC name (carried, executed). No input caused an option
parse or an extra process.

## Primitive sweep

Primitive: process exec / git argv
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:47` symbolic-ref origin/HEAD | literal | — | cleared |
| `:52` rev-parse `refs/heads/$c^{commit}` | S1 | `refs/` prefix, `-*` skip | cleared (pass-1, unchanged) |
| `:57`, `:59` symbolic-ref / rev-parse HEAD | literal | — | cleared |
| `:88` log `$MAIN_SHA --since=$SINCE_TS` | S5, S4 | hash; SINCE regex + `date -d` | cleared |
| `:90` rev-list `$MAIN_SHA` | S5, S4 | same | cleared |
| `:111` log `--first-parent … $MAIN_SHA -- "$f"` | S5, S4, S2 | `--`, `docs/` prefix | cleared for injection; Finding 3 (wildcards) |
| `:111` status `--porcelain -- "$f"` | S2 | `--`, `docs/` prefix | cleared for injection; Finding 2 (index write), Finding 3 |
| `:114` log `-- "$f"` | S2 | same | Finding 3 (wrong date) |
| `:180` log `-- docs/roadmap.md` | literal | — | cleared |
| `:148` `bash "$QS" open` | S4 (`SCRIPT_DIR` / `$HOME`) | — | cleared: same trust as the script |
| `:173` shuf `--random-source=<(yes "$seed")` | S4 hash | — | cleared |

Primitive: terminal output of repo text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:93`, `:173` merge list | S3 | `tr` strip | cleared (executed) |
| `:115` `### $f` heading | S2 | none | Findings 1, 4 |
| `:116` trigger body | S3 | `> ` prefix only | Finding 1 |
| `:131` log row | S3 | `> ` before text only | Finding 1 |
| `:139` carried list | S2 | none | Findings 1, 4 |
| `:153`, `:158` questions.sh output | S3 via questions.sh | none | not analyzed in this pass: output of a separate script, unchanged here |
| `:162` questions.sh stderr | S3 via questions.sh | inside a ``` fence | carried from pass-1 Finding 1 (Low, accepted) |
| `:183` roadmap Next | S3 | `> ` prefix only | Finding 1 |

Primitive: file read — unchanged since the pass on 3aee138. The symlink note from pass 1 (Informational) still applies to `:105` and `:179`.

## Endorsement Claims

- **Claim:** In the runs probed, no repo-derived name or text reached a git option position or a shell evaluator through the calls added in 83e7895.
  **Location:** `scripts/dev-cycle.sh:111`
  **Evidence:** executed
  **Verified:** Decision file names containing ESC/BEL, a newline, and `[a]` went through `git log --first-parent -- "$f"` and `git status --porcelain -- "$f"`. Each run exited 0, and no process or file appeared apart from the index refresh (Finding 2). `$MAIN_SHA` is a rev-parse hash, and `SINCE_TS` passed both the regex and the `date -d` check.
  **Not verified:** Behaviour under user-level git config (`core.fsmonitor`, globally configured `filter.*` drivers such as git-lfs, which `git status` can invoke on a racily-clean file when `.gitattributes` routes the file to that filter; the driver is the user's own tool, not repo code).
  **route: code-fact-check**
- **Claim:** The `tr` at `:88` removes C0 controls except tab and newline, plus DEL, from merge subjects.
  **Location:** `scripts/dev-cycle.sh:88`
  **Evidence:** executed
  **Verified:** A merge subject containing `ESC]52;…BEL` printed as `]52;c;bWVyZ2U= x` in sections 1 and 4.
  **Not verified:** UTF-8-encoded C1 controls and bidi characters (see the bypass list above).
- **Claim:** The `git status` output is only tested for being non-empty and is never printed, so its path-quoting format does not reach the digest.
  **Location:** `scripts/dev-cycle.sh:111-112`
  **Evidence:** read-static
  **Verified:** Lines 111–119 read. `$changed` is used only in `-n "$changed"`.
  **Not verified:** Nothing further; there is no other use of `$changed`.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Control chars still raw outside the merge list (OSC 52, CR, erase-line) | Medium | B3 | `:115-116,131,139,183` | Medium |
| 2 | `git status` writes `.git/index` (lock contention in shared checkout; header claim) | Low | B5 | `:111` | High |
| 3 | Pathspec wildcards in `$f` match siblings (fail-safe; wrong date) | Informational | B2 | `:111,114` | High |
| 4 | File names bypass the "> " quoting and forge headings | Low | B3/S2 | `:115,139` | High |

## Overall Assessment

The 83e7895 fixes add no way for repo content to execute code or write files. The new
`git log --first-parent` and `git status` calls take only a hash, a validated timestamp and a `docs/`-prefixed
path after `--`, and the quoting throughout is correct. Repo content can still do more than change the
digest's *wording*, in one way: raw terminal control sequences from decision text, log rows, the roadmap
and file names (Finding 1). The pass-1 control-char fix covered one of the five print points it named,
while the rubric marks it Fixed. The single most important change is to strip once at the script's
output. That also neutralises Finding 4. Separately, `git --no-optional-locks` on the new status call
removes the index write (Finding 2). Both are one-line changes. Everything is fixable in place, and nothing
here is architectural. No Critical or High. Within the code paths read, no finding blocks merge on
exploitability grounds, but Finding 1 is Medium under the floor rule and needs either the fix or an
override-log row. The load-bearing endorsement claim is executed and pending code-fact-check verification.

## Goal-Alignment Note
- **Answered:** Checked the new `git status --porcelain -- "$f"` and first-parent `git log` calls for option or pathspec-magic injection (none: `docs/` prefix, `--`, hash-only main). Checked the quoting (correct) and the control-char strip (works, but only on merge subjects). All checks were executed against hostile file names and contents in a throwaway repo. Found one Medium (the partial strip), two Low (index write in the shared checkout; file-name heading forgery) and one Informational (pathspec wildcards).
- **Out of scope:** Correctness of the carry-forward window beyond its security surface, test-suite adequacy, and questions.sh's own output handling (a separate, unchanged script). UTF-8 C1 and bidi terminal behaviour was not executed.
- **Escalate:** None. The partial C5 fix recorded as "Fixed" in the rubric should be corrected, either by fixing it or with an override row, since this is the loop's last iteration.
