Commit: 1f4f7a21

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b2 (branch feat/build-loop-u2b2)
**Scope:** Stage 2.5 submitted claims 62-67 only (final confirming pass, U2b2): `scripts/build-loop.sh` checkout_gate (:628-692) and check_line (:699-758). No harvesting from the diff.
**Checked:** 2026-10-08 (probes ran 2026-10-09T01:59Z-02:01Z UTC)
**Total claims checked:** 6
**Summary:** 5 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern.

Execution provenance: every probe ran under `timeout`, in a fresh `/tmp/sc25u2b2-XXXX` dir created and entered in the same script (`d=$(mktemp -d /tmp/sc25u2b2-XXXX) && cd "$d" || exit 1`), and removed by the script itself; `ls -d /tmp/sc25u2b2-*` matched nothing afterwards. One run (the first claim 67 attempt) stopped at a syntax error before its cleanup; its dir `/tmp/sc25u2b2-u933` was removed by hand. No background process was started. Captured output and the probe scripts are in the session scratchpad, `LOGS=/tmp/claude-1000/-workspace/67a6f690-c029-41ac-9bf2-d19f7c0e4343/scratchpad/sc25u2b2/` (files named under each claim). Per the brief, nothing but this report was written into the worktree, so the logs are not under `docs/reviews/execution-logs/`. The output that decides each verdict is quoted inline below. Probes 62-64 ran the real `scripts/build-loop.sh --check` (as the gate runs it) from a probe repo built with the `sm` fixture shape (settings self-merge + never none, brief x open naming feat/x with Policy: self-merge, feat/x adding `work-feat-x.txt`).

---

## Submitted Claims

## Claim 62: "A checkout made under a global `core.sparseCheckout=true` — a setting the gate's own config read does not see (GIT_CONFIG_GLOBAL=/dev/null) — is refused for a self-merge brief, through the skip-worktree index-bit rule."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:650-652`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout whose sparse-checkout under a global-only `core.sparseCheckout=true` left a main file outside the patterns (index tag `S`); the gate's config read sees nothing and the `ls-files -v` rule refuses it. Does not establish anything about cone-mode or `index.sparse` sparse indexes (not built), and a global sparseCheckout whose patterns cover every file sets no S bit and passes, correctly, since that checkout is complete.

The config-read arm cannot see a global setting. The script exports `GIT_CONFIG_GLOBAL=/dev/null` (`scripts/build-loop.sh:229`, `export GIT_LITERAL_PATHSPECS=1 ... GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 ...`), and checkout_gate reads only `git config --type=bool --get "${v%% *}"` (`:641-647`). The index-bit rule reads the checkout's index, not config:

```bash
# scripts/build-loop.sh:650-652
  n="$(git ls-files -v -z | tr '\0' '\n' | awk 'substr($0, 1, 2) != "H " { n++ } END { print n + 0 }')" \
    || { CHECKOUT_WHY="the checkout's index could not be listed"; return 1; }
  [[ "$n" == 0 ]] || { CHECKOUT_WHY="the checkout's index marks entries skip-worktree, assume-unchanged or unmerged"; return 1; }
```

Executed. The probe added a top-level `README.md` on main and checked out under a probe-local `$HOME/.gitconfig` holding `[core] sparseCheckout = true` (repo config untouched) with `.git/info/sparse-checkout` = `/docs/`, then ran `git read-tree -mu HEAD`. Its output: `repo config core.sparseCheckout: []`, `global core.sparseCheckout: [true]`, `gate-view config read: []`, `S README.md` in `ls-files -v`, README.md absent from the work tree, and an empty user-view `git status`. The baseline `--check` was `ok ...` (exit 0). After the sparse checkout:

```
refuse docs/working/briefs/2026-10-01-x.md: a self-merge brief needs --check run from a clean checkout of the default branch's commit; the checkout's index marks entries skip-worktree, assume-unchanged or unmerged
path docs/working/briefs/2026-10-01-x.md A work-feat-x.txt
exit 2
```

Control: with the same global setting but sparse patterns `/*`, every entry was `H` and `--check` returned `ok` with exit 0.

- Command: `timeout 120 bash $LOGS/probe-62-64.sh 62`. The probe itself runs `timeout 60 bash /workspace/.claude/wt-build-loop-u2b2/scripts/build-loop.sh --check docs/working/briefs/2026-10-01-x.md` with `HOME=$d/home` and no GIT_CONFIG_GLOBAL exported.
- cwd: `/tmp/sc25u2b2-Uca4/repo`. Probe exit 0; gate exit 2. Timestamp 2026-10-09T01:59:52Z.

**Evidence:** `scripts/build-loop.sh:229`, `scripts/build-loop.sh:641-652`, `$LOGS/claim62.log`, `$LOGS/probe-62-64.sh`

---

## Claim 63: "A checkout made with repo `core.autocrlf=true` (CRLF written, git status clean) is refused for a self-merge brief by the byte comparison."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:686-691`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo-config `core.autocrlf=true` on LF blobs, with the index racy and with it made non-racy; in both, git status is clean and the byte comparison refuses. Does not establish `core.eol` or `text=auto` attribute variants, `core.autocrlf=input` (which writes LF and would correctly pass), or files whose blobs already hold CRLF.

The byte comparison hashes each regular file's checked-out bytes with conversions off and compares them to main's blob ids:

```bash
# scripts/build-loop.sh:686-691
  [[ ${#ps[@]} -gt 0 ]] || return 0
  # --stdin-paths: one hash-object for every file (one per path cost a process each).
  x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" \
    || { CHECKOUT_WHY="the checkout's files could not be hashed"; return 1; }
  [[ "$x" == "$(printf '%s\n' "${ids[@]}")" ]] \
    || { CHECKOUT_WHY="a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)"; return 1; }
```

`core.autocrlf` is not in `STATE_KEYS_RE` (`scripts/build-loop.sh:243`, `'^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'`), so the state gate lets it through. The gate's own git status reads the repo config, applies the same conversion, and reports clean.

Executed. After `git config core.autocrlf true` and a fresh checkout of every tracked file, `od -c docs/a.md` showed `l i n e   o n e \r \n ...`, and `git status --porcelain` was empty. `--check` then printed:

```
refuse docs/working/briefs/2026-10-01-x.md: a self-merge brief needs --check run from a clean checkout of the default branch's commit; a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)
exit 2
```

The probe then backdated the files and ran `git update-index -q --really-refresh`, which left status clean and the index non-racy. `--check` printed the same refusal, from the same byte rule. The baseline before autocrlf was `ok` with exit 0.

- Command: `timeout 120 bash $LOGS/probe-62-64.sh 63`, running `timeout 60 bash .../scripts/build-loop.sh --check docs/working/briefs/2026-10-01-x.md`.
- cwd: `/tmp/sc25u2b2-*/repo` (the dir is named in the log). Gate exit 2 both times. Timestamp 2026-10-09T01:59:58Z.

**Evidence:** `scripts/build-loop.sh:243`, `scripts/build-loop.sh:654-656`, `scripts/build-loop.sh:686-691`, `$LOGS/claim63.log`

---

## Claim 64: "An `ident` attribute set only by a global `core.attributesFile` (so the gate's git never sees it) yields a refused self-merge brief." (Submitter saw the git status rule refuse; verdict which rule refuses, and whether the byte-hash arm would also catch it.)

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:654-656`, `scripts/build-loop.sh:686-691`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a global-only `core.attributesFile` naming `docs/i.md ident`, where the file is checked out expanded to `$Id: <sha> $`. The brief is refused in both index states tried. Which rule refuses depends on index raciness: the git status rule when the index entry is racy (as right after a checkout), the byte-hash rule when the index stat matches. Does not establish other global-only attributes (`filter`, `working-tree-encoding`, `eol`), which were not run here.

The gate's git cannot see the attribute. harden sets `core.attributesFile=/dev/null` (`scripts/build-loop.sh:221`, `for kv in ... core.attributesFile=/dev/null ...`), and `:229` exports `GIT_CONFIG_GLOBAL=/dev/null`. Two arms can therefore notice the expanded file. The first is the status rule at `:654-656`:

```bash
# scripts/build-loop.sh:654-656
  git status --porcelain=v1 -z --untracked-files=no --ignore-submodules=none > "$GATE_TMP/status" 2>"$GATE_TMP/err" && [[ ! -s "$GATE_TMP/err" ]] \
    || { CHECKOUT_WHY="git status failed or warned in the checkout"; return 1; }
  [[ ! -s "$GATE_TMP/status" ]] || { CHECKOUT_WHY="the checkout's index or tracked files differ from that commit (git status)"; return 1; }
```

The second is the `--no-filters` byte comparison at `:686-691`, quoted under Claim 63.

Executed. Under the probe HOME, `docs/i.md` read `see @docs/x$Id: 0f9460c8de7b4f783def78cdbe6b2895d712b8d4 $` and the user-view status was empty.

- **64a, right after checkout (index racy):** `--check` refused through the status rule: `refuse ...; the checkout's index or tracked files differ from that commit (git status)`, exit 2. The status rule fires because git does not trust a racily clean entry's stat and re-reads the file without the hidden attribute. That cause is inferred from git's documented racy-git handling and is consistent with 64b; it was not traced inside git. A variant with no diagnostic `git status` before the gate gave the same result (`$LOGS/claim64-nodiag.log`), so the probe's own status call did not cause it.
- **64b, files backdated and `git update-index --really-refresh` run under the global config (non-racy):** the gate-view `git status` with `GIT_OPTIONAL_LOCKS=0` was empty, so the status rule passed. `--check` refused through the byte-hash arm: `refuse ...; a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)`, exit 2.

So the byte-hash arm catches it whenever the status rule does not. In the racy case the status rule's `return 1` (`:656`) fires first, so the byte arm never runs in that pass. The bytes differ in both states, so the byte arm would also refuse it.

- Command: `timeout 120 bash $LOGS/probe-62-64.sh 64` (and `$LOGS/probe-64-nodiag.sh 64`), each running `timeout 60 bash .../scripts/build-loop.sh --check docs/working/briefs/2026-10-01-x.md` with `HOME=$d/home`.
- cwd: `/tmp/sc25u2b2-*/repo`. Gate exit 2 in all four runs; baseline `ok` with exit 0. Timestamps 2026-10-09T01:59:59Z and 02:00:09Z.

**Evidence:** `scripts/build-loop.sh:221`, `scripts/build-loop.sh:229`, `scripts/build-loop.sh:654-656`, `scripts/build-loop.sh:686-691`, `$LOGS/claim64.log`, `$LOGS/claim64-nodiag.log`

---

## Claim 65: "Once `co` is set in check_line (~:739), every exit from check_line prints a first line that is not `ok` (paths ~:740, :747, :750, :756)."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:739-757`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every normal exit of check_line after `:739` with `co` non-empty. Does not establish abnormal termination: an unbound-variable abort under `set -u`, which the subshell inherits, or a signal would print no first line at all. That empty line is also not `ok`, and the caller's `[[ "$out" == "ok "* ]] || fails=1` (`:777`) counts it as a failure.

The whole function after `:739` was read through its closing brace (`:758`). The read covered `nrules` (`:590-610`) and the lib helpers it and `:750` call (`pathform`, `truthrule`, `nul_list`, `lower_all` in `scripts/lib/dev-cycle-read.sh:191-200`, `:1096-1107`, `:859`, `:864`). None of them calls `exit` or `echo`s to stdout. The statements after `:739` that can end the function are these:

```bash
# scripts/build-loop.sh:739-740
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
  if [[ ${#ps[@]} -eq 0 ]]; then echo "${co:-ok $a $sha $tree}"; return; fi
# :747
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
# :750
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: the paths the merge of $br changes could not be lower-cased"; return; fi
# :756-757
  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
  printf '%s\n' "${rows[@]}"
```

- `:740` prints `$co` when it is set, because of `${co:-...}`.
- `:747` and `:750` print fixed `refuse` lines.
- `:756` tests `-n "$co"` before the `ok` branch.
- The loop at `:751-755` only appends to `rows`.
- `:757` prints after the first line.

`co` always begins `refuse `. The script runs `set -euo pipefail` (`:172`). check_line is called as `out="$(check_line "$a")"` (`:776`), and without `inherit_errexit`, bash 5.2 clears `-e` in command substitutions; a grep finds no `shopt` in `scripts/build-loop.sh`. So no failing statement exits early and silently, apart from the `set -u` case named in Scope. The executed runs for claims 62-64 match: each refusal printed `refuse` first and then the `path` row.

**Evidence:** `scripts/build-loop.sh:172`, `scripts/build-loop.sh:739-758`, `scripts/build-loop.sh:776-777`, `scripts/build-loop.sh:590-610`, `scripts/lib/dev-cycle-read.sh:191-200`, `scripts/lib/dev-cycle-read.sh:859-864`, `scripts/lib/dev-cycle-read.sh:1096-1107`

---

## Claim 66: "One `git hash-object --stdin-paths` process hashes all regular files per gate pass: the number of processes checkout_gate spawns is fixed, independent of the number of tracked files."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:628-692`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers external execs and forks across 10 vs 2,000 regular files, and across 0 vs 5 gitlinks. Does not establish the cost of the bash-side per-entry loop, which is builtin-only but linear CPU. The precise version is: fixed for regular files and symlinks, plus one forked subshell and one `ls` per gitlink whose directory exists in the checkout.

The first half holds. One pipeline hashes every collected path:

```bash
# scripts/build-loop.sh:688
  x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" \
```

The per-entry loop (`:665-685`) uses only builtins for 100644, 100755 and 120000 entries. The second half needs a qualifier. Gitlink entries, which are tracked, spawn a subshell and an `ls` each when their directory exists:

```bash
# scripts/build-loop.sh:673
        if [[ -L "$p" ]] || { [[ -e "$p" ]] && ! x="$(ls -A -- "$p" 2>/dev/null)"; }; then
```

Executed with exec-logging shims on PATH for git, tr, awk, ls and the other externals, plus the `/proc/stat` `processes` delta (min of 3 runs). Each repo was run once as self-merge and once as review; the difference is checkout_gate's share:

| repo | self-merge execs | review execs | delta | system forks (sm / rv) |
|---|---|---|---|---|
| 10 files | 94 | 80 | 14 (10 git, 2 tr, 2 awk) | 185 / 163 |
| 2,000 files | 94 | 80 | 14 | 189 / 163 |
| 10 files + 5 gitlinks (empty dirs) | 99 (incl. `5 ls`) | 80 | 19 | 195 / 163 |

- Command: `timeout 300 bash $LOGS/probe-66.sh`, running `timeout 120 bash .../scripts/build-loop.sh --check docs/working/briefs/2026-10-01-x.md` per repo.
- cwd: `/tmp/sc25u2b2-*/<repo>`. Probe exit 0. Timestamp 2026-10-09T02:00:35Z. Load 0.49.

The fork column is system-wide and noisy (±4), but it moves by +10 for 5 gitlinks: 5 subshell forks plus 5 `ls` execs. On this worktree's tree (3,116 entries at 100644 and 58 at 100755, no gitlink) the count is fixed in practice.

**Evidence:** `scripts/build-loop.sh:665-692`, `scripts/build-loop.sh:673`, `scripts/build-loop.sh:688`, `$LOGS/claim66.log`, `$LOGS/probe-66.sh`

---

## Claim 67: "One checkout_gate pass costs about 0.27-0.28 s on this worktree (~3,170 files) at low load, and nine passes about 2.55 s."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:736-738`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checkout_gate's body, extracted byte for byte from `:533` (callervar) and `:628-692`, run under the script's harden and export environment in this worktree at 1f4f7a21 (3,174 tracked entries), at load 0.45-0.61. Does not establish check_line's other costs, or behavior under higher load or a cold page cache. The in-code comment at `:737` says "about 0.25 s here", about 8% under the measured figure. That comment is not this claim's text but sits at the cited location.

The cited comment:

```bash
# scripts/build-loop.sh:736-738
  # still print (a loop's advisory run from its own branch learns them). Run
  # per brief, so each decision sees the checkout as it is: about 0.25 s here,
  # times the self-merge briefs in one --check (at most the slot count).
```

Executed: `timeout 300 bash $LOGS/probe-67.sh`, cwd `/workspace/.claude/wt-build-loop-u2b2`, which is read-only. Status ran with `GIT_OPTIONAL_LOCKS=0` and hash-object without `-w`. `MAIN_SHA=HEAD=1f4f7a21247d047a9e83fa94670b01dede63d690`, probe exit 0, timestamp 2026-10-09T02:01:00Z. Uptime before was `load average: 0.45, 0.60, 0.82` and after `0.61, 0.63, 0.83`.

- The pass returned `rc=0 WHY=[]`, so the walk went to completion, through the hash-object comparison.
- Single passes (bash `time`, real): 0.271, 0.276, 0.275, 0.267, 0.271 s.
- Nine passes: 2.635, 2.550, 2.545 s.

Both figures match the claim: 0.27-0.28 s, and about 2.55 s for nine (one of three runs was 2.64).

**Evidence:** `scripts/build-loop.sh:533`, `scripts/build-loop.sh:628-692`, `scripts/build-loop.sh:736-738`, `$LOGS/claim67.log`, `$LOGS/probe-67.sh`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 66** (`scripts/build-loop.sh:673`): the process count is fixed in the number of regular files and symlinks, not in all tracked entries. Each gitlink whose directory exists adds one subshell and one `ls`. Tighten it to "independent of the number of tracked regular files".

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Goal:** land U2b2 through its review-fix loop. This pass confirms that the security and performance critics' six submitted endorsements are sound enough to cite in the final rubric.
- **Alignment:** all six were checked against 1f4f7a21. Five are confirmed: the three by running the real `--check` gate, one statically, one by timing. Claim 66 needs one qualifier (gitlinks); it is not a defect in the gate, since this repo has no gitlink.
- **Not in the submitted list:**
  - Claim 64's refusal rule depends on whether the index is racy. Any test asserting the git status message for a global-attribute case could therefore be timing-sensitive. The suite's ident test sets the attribute in the repo, which is a different case.
  - In the claim 67 harness, a caller environment with `LC_ALL` set to an uninstalled locale (`en_US.UTF-8` here) printed a bash `setlocale` warning to stderr each time checkout_gate's `local -x LC_ALL=C` was unwound. Whether the real `--check` emits the same stderr noise under such a caller locale was not tested; the fixtures set `LC_ALL=C`.
  - The `:737` comment's "about 0.25 s" is about 8% under the measured 0.27 s.
- **Not done:** no fresh harvesting, no edits to code, and no writes outside this report.
