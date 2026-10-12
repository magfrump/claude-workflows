Commit: 5e816c5b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b1 (branch `feat/build-loop-u3b1`)
**Scope:** full branch `main...HEAD` (HEAD 5e816c5b): `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-merge.bats` (one case), `docs/working/plan-build-loop-handoff.md:324`, the override-log rows dated 2026-10-12, and the code commits' messages (ec9ba0c7, 8f99a919, 8367359f, 1bf01630). Final confirming pass (k=3 replicate 2).
**Checked:** 2026-10-12
**Total claims checked:** 40
**Summary:** 34 verified, 3 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Legibility target for every claim: a reader who acts on the comment, header, commit or plan text (the orchestrator author in U4, a reviewer of this branch, or the merge-message author) without opening the implementation.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read before checking; no claim below matches a logged pattern, and neither Incorrect below is a fabricated symbol/API, so the log needs no entry (and this pass writes only its own report).

**Execution provenance (shared).** All probes ran from throwaway repos under `/tmp/u3b1f2-*` (each script makes and enters its own `mktemp -d`, refuses git writes outside it), invoking `bash /workspace/.claude/wt-build-loop-u3b1/scripts/build-loop.sh`; mutants ran on copies of `scripts/` and `test/` under the probe's temp dir (the worktree was never edited). Captured output and probe scripts: `/tmp/u3b1f2-logs/` (outside the worktree, per the brief's write-only-your-report rule).

| Log | Command (cwd `/tmp/u3b1f2-logs`) | Exit | UTC |
|---|---|---|---|
| `orch.log` | `TMPDIR=$(mktemp -d /tmp/u3b1f2-bats-XXXX) bats test/scripts/build-loop-orchestrator.bats` | 0 (8/8 ok) | 2026-10-12T20:33:44Z |
| `merge.log` | same, `build-loop-merge.bats` | 0 (12/12 ok) | 20:33:53Z |
| `read-help.log` | same, `bats -f "help\|header\|usage" build-loop-read.bats` | 0 (2/2 ok) | 20:40:37Z |
| `p1.log` | `bash f2-probe1.sh` (config order, `010`, git-call shim per mode, caller env, default_gate tag) | 128 (the probe's own tree-ref step failed: a `>` redirect truncated the ref before `rev-parse` read it; sections A-F tag are complete; redone as p4) | 20:36:16Z |
| `p2.log` | `bash f2-probe2.sh` (packed refs, odd commit headers, cut, 64 KiB boundary) | 0 | 20:36:57Z |
| `p3.log` | `bash f2-probe3.sh` (5 mutants on copies) | 128 (same probe bug in its last step; all 5 mutant results are complete) | 20:37:44Z |
| `p4.log` | `bash f2-probe4.sh` (main at a tree, master present) | 0 | 20:37:59Z |
| `p5.log` | `bash f2-probe5.sh` (UTF-8 regex vs Python, 837,930 cases; B4 mutant) | 0 | 20:38:53Z |
| `p6.log` | inline `git rev-parse --git-path` with GIT_GRAFT_FILE / GIT_SHALLOW_FILE / GIT_OBJECT_DIRECTORY / GIT_ALTERNATE_OBJECT_DIRECTORIES | 0 | ~20:39Z |
| `p8.log` | `bash f2-probe8.sh` (16 MB marker, `time`) | 0 | 20:39:36Z |
| `p9.log` | `bash f2-probe9.sh` (FENCE_AWK-refused line at body line 101) | 0 | 20:40:24Z |

Git 2.39.5; bash; perl; python3.

---

## Claim 1a: "a 16 MB marker costs ~1.2 s ... there" (override row, `--marker` reads the marker commit a fourth time; Won't-Fix)

**Location:** `docs/reviews/override-log.md:711`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the wall time of one `--marker` run on a 16,000,181-byte blocked marker on this machine (two runs); does not establish the time on other hardware or for a body just under the cap.

Executed: two `--marker` runs printed `skip docs/working/briefs/2026-10-01-x.md: its marker is 16000181 bytes, over the 65536-byte cap` with `real 0m0.956s` and `real 0m1.016s` — the same order as "~1.2 s". The cap check precedes the body read (paraphrased — no quote available because the ordering is quoted under Claim 19).

**Evidence:** `docs/reviews/override-log.md:711`, `scripts/build-loop.sh:829-831`, `/tmp/u3b1f2-logs/p8.log`, `/tmp/u3b1f2-logs/f2-probe8.sh`

---

## Claim 1b: "... and ~145 MB there" (same row)

**Location:** `docs/reviews/override-log.md:711`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** Covers nothing about memory; the run in Claim 1a measured time only.

Execution was attempted but `/usr/bin/time` is absent in the sandbox (`ls: cannot access '/usr/bin/time': No such file or directory`, p8 attempt at 20:39:33Z, exit 2), so max RSS could not be read. Needed: `/usr/bin/time -v` or a cgroup memory reading around the same probe.

**Evidence:** `docs/reviews/override-log.md:711`, `/tmp/u3b1f2-logs/f2-probe8.sh`

---

## Claim 2: Plan as-built note: "`--state` exits 1 (stderr only) for a non-decimal GIT_CONFIG_COUNT or a GIT_DIR naming no repository, and prints `refuse state gate:` / `refuse state objects:` as `--check` does; ... a caller pair is refused by key whatever its value ... default_gate checks the ref's own object type (not MAIN_SHA) ... `--marker` also skips a marker commit over 64 KiB (its body not processed ...), a body line holding `<!--` ... and one that is not strict UTF-8 ...; land's re-run of default_gate leaves a moved branch to the compare-and-swap or W's fast-forward"

**Location:** `docs/working/plan-build-loop-handoff.md:324`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed as-built behaviour against the code and probes; does not establish the forward-looking parts (U4 calling `--state` without git_harden exported; rows 493/494/517 closing "once U4's SKILL.md starts each iteration with `--state`"), which name future units.

Executed: `GIT_CONFIG_COUNT=010 ... --state` → `exit 1`, `err: build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count`; `GIT_DIR=$T/nonexistent ... --state` → `exit 1`, `err: Not inside a git repository` (p1 C, D). `state_start` is shared, so the gate/objects lines are --check's:

```bash
# scripts/build-loop.sh:1172-1178
state_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check --main "$MAIN_SHA" \
    || { echo "refuse state objects: ..."; exit 2; }
}
```

(excerpt elides the objects message text at :1177 — read; function ends :1178.) Key-whatever-value: `GIT_CONFIG_PARAMETERS="'core.hooksPath'='/dev/null'"` → `refuse state core.hookspath: ...` exit 2 (p1 D). Ref's own type: `:564` (Claim 15). 64 KiB, `<!--`, strict UTF-8: Claims 19, 23, 25. The B4 merge-suite case passes and its mutant fails (Claim 32).

**Evidence:** `docs/working/plan-build-loop-handoff.md:324`, `scripts/build-loop.sh:454-463`, `:572`, `:1172-1178`, `/tmp/u3b1f2-logs/p1.log`, `/tmp/u3b1f2-logs/merge.log`

---

## Claim 3: "default_gate also refuses a default branch that names anything but a commit (row 656)" (plan); "default_gate also refuses a default branch that names something other than its commit (row 656)" (commit ec9ba0c7)

**Location:** `docs/working/plan-build-loop-handoff.md:324`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refs/heads/main at an annotated tag (loose and packed), at a nested tag, and at a tree with and without master; does not establish blob refs (same path as a tree by reading) or other default-branch names.

The rule fires only for an object that peels to a commit, because resolve_main skips anything that does not:

```bash
# scripts/lib/dev-cycle-read.sh:539-541
    sha="$(git show-ref --verify --hash "refs/heads/$c" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi
```

(excerpt of resolve_main, which continues to :549+ with the current-branch fallback — read.) Executed: annotated tag → `refuse state default-branch: refs/heads/main names an object that is not a commit` (loose p1 F, packed p2 F3, nested tag p1 F); main at a tree → `exit 1`, `build-loop.sh needs a default branch found by name ...` (p2 F2); main at a tree with master present → `refuse state default-branch: both main and master exist`, exit 2 (p4). Every non-commit is kept from being used, but "default_gate refuses" holds only for the tag case; the precise version is the header's own `:147-148` "naming an object that is not a commit (an annotated tag)" plus "other non-commits are not found by name (exit 1) or meet another default-branch refusal". Text-only.

**Evidence:** `scripts/build-loop.sh:564-565`, `scripts/lib/dev-cycle-read.sh:529-549`, `/tmp/u3b1f2-logs/p1.log`, `/tmp/u3b1f2-logs/p2.log`, `/tmp/u3b1f2-logs/p4.log`

---

## Claim 4: "--marker ... ok BRIEF SHA — SHA: the marker (the branch tip, as --status reads it). Then the body (the message after the subject and the blank line below it, trailing blank lines dropped), scrubbed as all output is, each line prefixed "> " (an empty one ">"); at most 100 lines of 300 bytes ..., with a last line "> (build-loop.sh --marker cut this body: K of N lines shown, M cut at 300 bytes)" when cut. A stopped marker's body may be empty."

**Location:** `scripts/build-loop.sh:96-107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ok line, body extraction (including gpgsig/encoding/mergetag headers and extra leading blank lines), prefixing, both caps and the note, and an empty stopped body; does not establish the scrub's own character set (lib code, unchanged here).

```bash
# scripts/build-loop.sh:832
  body=""; m="${m#*$'\n\n'}"; [[ "$m" != *$'\n'* ]] || body="${m#*$'\n'}"; body="${body#$'\n'}"
```

Executed: a commit with a multi-line `gpgsig` header holding a ` ` continuation line, and one with `encoding` + `mergetag` headers, both print `ok ... ` then `> Which one?` (p2 G); a body after two extra blank lines prints `>`, `>`, `> Which one?` (leading blanks kept, as "after the subject and the blank line below it" says). Suite cases T32 (`orch.log` ok 3, 6) pin prefixing, `>` for empty, the 100-line note `100 of 101 lines shown, 0 cut at 300 bytes`, and the empty stopped body.

**Evidence:** `scripts/build-loop.sh:96-107`, `:823-872`, `test/scripts/build-loop-orchestrator.bats:62-78`, `:119-134`, `/tmp/u3b1f2-logs/p2.log`, `/tmp/u3b1f2-logs/orch.log`

---

## Claim 5a: "skip BRIEF: WHY — As --status skips it; the tip is no blocked or stopped marker (WHY names --status' LOOP); the marker commit is over 64 KiB (its body is not processed); a body line starts, after blanks, ">" and list markers (...), with "#", "**Needs:**", "**Status:**", "**Answer" or "Q-" and a digit, in any case, holds "<!--" ... or is not strict UTF-8 (...); ... a blocked marker with no body; or a read that fails."

**Location:** `scripts/build-loop.sh:108-118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed skip cause except the FENCE_AWK clause (Claim 5b), and exit 0 on every skip; does not establish the read-failure branches by execution (static: each `|| { echo "skip ..."; return; }`).

Suite: `orch.log` ok 4 (grammar, `<!--`, three raw non-UTF-8 commits), ok 5 (empty blocked body, cap), ok 7 (absent/working/ready/not-a-marker tips) — all assert exit 0 via `marker_is`/`bl`. Boundary executed: a 65,536-byte commit prints `ok`, a 65,537-byte one `skip ...: its marker is 65537 bytes, over the 65536-byte cap` (p2), matching `[[ "$n" -le "$MARKER_MAX" ]]` at `:830`.

**Evidence:** `scripts/build-loop.sh:108-118`, `:823-866`, `/tmp/u3b1f2-logs/orch.log`, `/tmp/u3b1f2-logs/p2.log`

---

## Claim 5b: "a line of the body, as written or as quoted, that FENCE_AWK refuses, or a fence it leaves open" (a --marker skip cause)

**Location:** `scripts/build-loop.sh:115-117`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which lines FENCE_AWK reads (the printed lines, first 100, cut at 300 bytes, unquoted and quoted); does not establish any harm from the unread lines (they are never printed, so the questions file never holds them).

FENCE_AWK reads the *printed* body only:

```bash
# scripts/build-loop.sh:859-861
  for m in "$(printf '%s\n' "$body" | sed -E 's/^> ?//')" "$body"; do
    [[ -n "$body" ]] || break
    r="$(printf '%s\n' "$m" | env LC_ALL=C awk "$FENCE_AWK"'fence($0) { next } END { ... }')" \
```

(excerpt ends :861; loop continues to :866 — read.) `$body` here is perl's output, already cut to 100 lines. Executed (p9): a 101-line blocked body whose line 101 is "```", `[a]: https://example.invalid` or `<div>` prints `ok ...` and `> (build-loop.sh --marker cut this body: 100 of 101 lines shown, 0 cut at 300 bytes)`, exit 0 — no skip, although "a line of the body as written" that FENCE_AWK refuses exists. The in-code comment `:833` ("Scrubbed first, so the rules, the caps and FENCE_AWK read what is printed") is the precise version; the header should say "a printed line, unquoted or quoted, that FENCE_AWK refuses". Text-only: the output contract (no refused line reaches the questions file) holds.

**Evidence:** `scripts/build-loop.sh:115-117`, `:833`, `:857-866`, `/tmp/u3b1f2-logs/p9.log`, `/tmp/u3b1f2-logs/f2-probe9.sh`

---

## Claim 6: "--state the state gate --check runs first, alone ...: ok, or --check's "refuse state WHAT: WHY" lines and exit 2. It checks what this script's own git reads trust, as they run hardened; it does not make a plain git command safe in the caller's shell, and it is a snapshot. Exit 1 (stderr only) for a caller's GIT_CONFIG_COUNT that is not plain decimal, or a GIT_DIR naming no repository. First, read only here, the caller's environment: a repo-local git variable set (...; the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside), or a caller pair (git -c, GIT_CONFIG_COUNT) setting a key the state gate refuses or one this script's own hardening sets (core.useReplaceRefs, core.hooksPath, core.fsmonitor, core.attributesFile, core.commitGraph, core.multiPackIndex; a git -c pair would win over it), whatever the value. Then --check's state gate, its default-branch rules and its object check"

**Location:** `scripts/build-loop.sh:119-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output/exit contract, the six listed keys (= `HARDEN` at `:455`), the variables refused and kept, and the ordering caller_gate → state_gate → default_gate/store_check; "First" is relative to the state gate: `git rev-parse --show-toplevel` (`:572`) runs before caller_gate under the caller's GIT_DIR, so a GIT_DIR naming another repository is reported from there (it reads that repository's config via `git config --list` but no object). Does not establish safety of the caller's own bare git (the text disclaims it).

```bash
# scripts/build-loop.sh:583-584
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
```

Executed (p1 D): clean → `ok` exit 0; GIT_DIR (another repo), GIT_WORK_TREE (existing non-repo), GIT_CONFIG, GIT_OBJECT_DIRECTORY, GIT_COMMON_DIR → one `refuse state VAR: set in the caller's environment, ...` each, exit 2 (GIT_CONFIG naming a missing file adds `refuse state caller-config: the caller's config pairs could not be read`); `GIT_NO_REPLACE_OBJECTS=1 GIT_PREFIX=sub/` → `ok`; `'core.commitGraph'='true' 'Diff.X.textconv'='cat' 'includeIf.onbranch:x.path'='/y'` → three refusals; `'color.ui'='never'` → `ok`.

**Evidence:** `scripts/build-loop.sh:119-136`, `:455`, `:532-546`, `:572-586`, `/tmp/u3b1f2-logs/p1.log`, `/tmp/u3b1f2-logs/orch.log`

---

## Claim 7: "--check ... the default branch a symbolic ref or naming an object that is not a commit (an annotated tag)"

**Location:** `scripts/build-loop.sh:147-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check (and --state) refusing an annotated-tag main at startup; does not establish other non-commit objects (Claim 3: they never reach this rule).

```bash
# scripts/build-loop.sh:564-565
  p="$(git show-ref --verify --hash "refs/heads/$MAIN" 2>/dev/null)" && [[ "$(git cat-file -t "$p" 2>/dev/null)" == commit ]] \
    || { echo "refuse state default-branch: refs/heads/$MAIN names an object that is not a commit"; bad=1; }
```

Executed (p1 F): `--check docs/working/briefs/x.md` with main at an annotated tag → `refuse state default-branch: refs/heads/main names an object that is not a commit`, exit 2. This is a behaviour change for --check/--merge/--start/--prompt (all reach `state_start` via `gate_start`), as the header now documents.

**Evidence:** `scripts/build-loop.sh:147-148`, `:552-571`, `:1179-1182`, `/tmp/u3b1f2-logs/p1.log`

---

## Claim 8: "Exit: 0 every line printed (or help; a --marker skip is a line), for --state ok, ...; 2 any other ... verdict line, or the state gate (--state's included) not ok. ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, no perl or lib/dev-cycle-read.sh, a failed mktemp (--state, --check, --merge, --start, --prompt; no line printed), or no default branch found by name."

**Location:** `scripts/build-loop.sh:375-384`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --marker skip exit 0, --state ok/refuse exits, the non-decimal count and no-repo exit 1; the mktemp-failure exit 1 for --state is static (`GATE_TMP="$(mktemp -d)"` under `set -e` at `:1174`, before any echo); does not establish the perl/lib exit-1 paths (unchanged).

Executed: p1 C (exit 1 for every mode with `GIT_CONFIG_COUNT=010`), p1 D (exit 1 `Not inside a git repository`), p2 F2 (exit 1 no default branch), suite `state_is`/`marker_is` (exit 2 / 0). The help-extraction test still passes on the new last header line (`read-help.log`: `ok 2 build-loop.sh -h and --help print the header from its first line through its last`).

**Evidence:** `scripts/build-loop.sh:375-384`, `:1174`, `/tmp/u3b1f2-logs/p1.log`, `/tmp/u3b1f2-logs/read-help.log`

---

## Claim 9: "The caller's own environment is trusted: its `git -c` pairs can still win, so --state reads them (caller_gate); a GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) stops every mode."

**Location:** `scripts/build-loop.sh:450-453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's ordering of GIT_CONFIG_PARAMETERS after GIT_CONFIG_COUNT pairs, bash's octal reading of `010`, git's decimal reading, and the stop before any git call in all eight modes; does not establish behaviour for `--help` (exits at `:436` before harden, with no git call) or git versions other than 2.39.5.

```bash
# scripts/build-loop.sh:456-463
harden() {
  local c="$CALLER_COUNT" kv
  [[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo "build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }
  for kv in "${HARDEN[@]}"; do
    export "GIT_CONFIG_KEY_$c=${kv%%=*}" "GIT_CONFIG_VALUE_$c=${kv#*=}"; c=$((c + 1))
  done
  export GIT_CONFIG_COUNT="$c"
}
```

Executed (p1): `git -c core.hooksPath=/caller` over a COUNT pair `/dev/null` → `/caller`; `--list --show-scope` lists `command core.x=count` before `command core.x=param`; bash `$((010))=8`; git read 10 command pairs with `GIT_CONFIG_COUNT=010`. With a git shim logging every call, `GIT_CONFIG_COUNT=010` on `--settings`, `--status`, `--marker`, `--state`, `--check`, `--start`, `--prompt`, `--merge` each gave exit 1, the stderr line, and `git calls: 0` (p1 C). Mutant removing `:458` turns the orchestrator suite red (p3 `no-decimal-check`: `count [010]` → `Not inside a git repository`).

**Evidence:** `scripts/build-loop.sh:450-464`, `/tmp/u3b1f2-logs/p1.log`, `/tmp/u3b1f2-logs/p3.log`

---

## Claim 10: "stray_vars: the repo-local git variables set here, one per line, but the caller's (callervar) and GIT_PREFIX, which only names a subdirectory for an alias (the script cds to the top level). checkout_gate and caller_gate refuse them."

**Location:** `scripts/build-loop.sh:514-517`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exclusions and both callers (caller_gate refuses each; checkout_gate refuses the first); does not establish checkout_gate's behaviour by execution in this pass (static).

```bash
# scripts/build-loop.sh:517
stray_vars() { local v; for v in $(git rev-parse --local-env-vars); do [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" || echo "$v"; done; }
```

```bash
# scripts/build-loop.sh:1096-1097
  x="$(stray_vars)"; v="${x%%$'\n'*}"
  [[ -z "$v" ]] || { CHECKOUT_WHY="$v is set, so git can read another work tree, index, object store or config file"; return 1; }
```

(excerpt of checkout_gate, which continues past :1097 — read to :1153.) Executed via caller_gate in p1 D (Claim 6).

**Evidence:** `scripts/build-loop.sh:508-517`, `:534-536`, `:1096-1097`, `/tmp/u3b1f2-logs/p1.log`

---

## Claim 11: "--state's snapshot of the git settings in the caller's environment ...: the orchestrator runs --state at the start of each iteration ... Not covered: anything else such an environment can do (BASH_ENV, PATH), and what changes after the snapshot."

**Location:** `scripts/build-loop.sh:518-523`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that caller_gate reads only git variables and command-scope config pairs, once; does not establish that the orchestrator runs it each iteration (U4, not built).

caller_gate's two reads are `stray_vars` and `GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only` (`:534`, `:537`); nothing reads BASH_ENV or PATH (paraphrased — no quote available because the claim covers absence of code: no reference to BASH_ENV/PATH in caller_gate `:532-546`).

**Evidence:** `scripts/build-loop.sh:518-546`

---

## Claim 12: "A stray variable: GIT_REPLACE_REF_BASE, GIT_SHALLOW_FILE and GIT_ALTERNATE_OBJECT_DIRECTORIES name files the state gate does not read, and GIT_GRAFT_FILE or GIT_OBJECT_DIRECTORY move the ones it does."

**Location:** `scripts/build-loop.sh:523-526`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how `git rev-parse --git-path` (state_gate's file lookup, `:497`) maps under each variable; does not establish every git command's use of these variables.

```bash
# scripts/build-loop.sh:496-498
  for f in info/attributes info/grafts shallow objects/info/alternates; do
    p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { ...; return 1; }
    if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not an empty file"; bad=1; fi
```

(excerpt of state_gate ends :498; loop closes :499, function :507 — read.) Executed (p6): `GIT_GRAFT_FILE=/g` → grafts path `/g`; `GIT_OBJECT_DIRECTORY=$T/o` → alternates `$T/o/info/alternates`; `GIT_SHALLOW_FILE=/s` → shallow still `.git/shallow`; `GIT_ALTERNATE_OBJECT_DIRECTORIES=/a` → paths unchanged. state_gate lists `refs/replace/` literally (`:500`), so GIT_REPLACE_REF_BASE names refs it does not list.

**Evidence:** `scripts/build-loop.sh:496-501`, `/tmp/u3b1f2-logs/p6.log`

---

## Claim 13: "A caller pair (git -c, GIT_CONFIG_COUNT; read with the caller's count, so harden's own pairs are not listed) ...: git applies git -c pairs after harden's, so they win (a GIT_CONFIG_COUNT pair comes before harden's and loses, but is refused too)."

**Location:** `scripts/build-loop.sh:526-530`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's precedence and caller_gate's listing; does not establish other git versions.

```bash
# scripts/build-loop.sh:537
  x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only)" || { echo "refuse state caller-config: ..."; return 1; }
```

Executed (p1 A): COUNT pairs `0: core.hooksPath=/caller`, `1: core.hooksPath=/dev/null` → `git config --get core.hooksPath` = `/dev/null` (the later, harden's, wins); with `-c` → `/caller`. A clean run prints `ok` (harden's six keys, which are HARDEN keys, are therefore not listed). Mutant dropping `GIT_CONFIG_COUNT="$CALLER_COUNT"` (p3 `caller-full-count`) prints `refuse state core.usereplacerefs ...` etc. on every run and turns the suite red.

**Evidence:** `scripts/build-loop.sh:526-546`, `/tmp/u3b1f2-logs/p1.log`, `/tmp/u3b1f2-logs/p3.log`

---

## Claim 14: "... for a key the state gate refuses or one HARDEN sets, whatever its value" / "# a trailing blank marks a HARDEN key"

**Location:** `scripts/build-loop.sh:528`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six HARDEN keys (lower-cased match) and STATE_KEYS_RE keys, any value; does not establish matching of keys with mixed-case subsections against HARDEN (none of the six has a subsection).

```bash
# scripts/build-loop.sh:540-543
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
    if [[ "$k" == *" " || "$k" =~ $STATE_KEYS_RE ]]; then
      echo "refuse state ${k% }: set by the caller's git -c or GIT_CONFIG_COUNT pairs, ..."; bad=1
    fi
```

(excerpt of the read loop :538-544 — read.) Executed: harden's own value `core.hooksPath=/dev/null` via `-c` is refused (p1 D); `core.commitGraph=true` refused (HARDEN, not in STATE_KEYS_RE).

**Evidence:** `scripts/build-loop.sh:455`, `:484`, `:538-544`, `/tmp/u3b1f2-logs/p1.log`

---

## Claim 15: "resolve_main peels the ref to its commit, which land's compare-and-swap would then never match (row 656). The ref itself, not MAIN_SHA: land's re-run must leave a moved branch to its own refusal (the compare-and-swap, or the fast-forward in W)."

**Location:** `scripts/build-loop.sh:560-563`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the compare-and-swap path by execution and the W path statically; does not establish W's fast-forward refusing a main moved to an ancestor of NEW (pre-existing land behaviour).

```bash
# scripts/build-loop.sh:1408-1412
  { state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; } > "$GATE_TMP/state" \
    || { MERGE_WHY="the git state changed after the check ($(head -n 1 "$GATE_TMP/state"))"; return 1; }
  if [[ -z "$w" ]]; then
    git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
      || { MERGE_WHY="the default branch moved after the check, or could not be updated; it was left as it is"; return 1; }
```

(excerpt of land ends :1412; else-branch W fast-forward :1413-1420 — read.) Executed: merge suite ok 2 passes; the mutant restoring `== "$MAIN_SHA"` makes it fail with `refuse ...: the git state changed after the check (refuse state default-branch: refs/heads/main names an object that is not a commit)` (p5).

**Evidence:** `scripts/build-loop.sh:560-565`, `:1403-1420`, `/tmp/u3b1f2-logs/merge.log`, `/tmp/u3b1f2-logs/p5.log`

---

## Claim 16: "Every mode but the read modes decides or writes (a new mode is gated by default). --marker reads one marker as --status reads its tip: the orchestrator's --state at the start of its iteration covers both (row 690)."

**Location:** `scripts/build-loop.sh:578-580`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that --marker is ungated and reads through status_fields like --status; "covers both" is a design statement depending on U4, not established.

```bash
# scripts/build-loop.sh:581
GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1  # not the gate repository's GATE_*
```

marker() begins with `status_fields "$a"` (`:824`).

**Evidence:** `scripts/build-loop.sh:578-584`, `:823-827`, `:1546-1549`

---

## Claim 17: "The caller's environment first: it can point the state gate's own reads elsewhere."

**Location:** `scripts/build-loop.sh:582`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering before state_gate and the redirection of state_gate's `--git-path` reads; does not cover `:572`'s earlier `rev-parse --show-toplevel` (Claim 6's scope).

Ordering quoted under Claim 6 (`:583-584`); redirection executed under Claim 12 (p6).

**Evidence:** `scripts/build-loop.sh:582-584`, `/tmp/u3b1f2-logs/p6.log`

---

## Claim 18: "A blocked marker's body rule (D3, D11), as the loop prompt states it and --marker enforces it (row 689: one string), with BODY_LINES and BODY_BYTES." + BODY_RULE text vs the regex and plan D11

**Location:** `scripts/build-loop.sh:805-807`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the prompt interpolates the same variables and that the rule text matches the perl test (prefix stripping, five starts, case, `<!--`, strict UTF-8) and D11's list; does not establish how a loop model reads the prose.

```bash
# scripts/build-loop.sh:838-841
      (my $s = $l[$i]) =~ s/^(?:[ \t>]|[-*+][ \t]|[0-9]+[.)][ \t])*//;
      # "<!--" anywhere: questions.sh finds its index markers anywhere in a line (security i1 F1).
      if ($s =~ /^(?:#|\*\*needs:\*\*|\*\*status:\*\*|\*\*answer|q-[0-9])/i || index($l[$i], "<!--") >= 0
        || $l[$i] !~ /\A(?:[\x00-\x7F]|...)*\z/) { print "rule ", $i + 1, "\n"; exit 0 }
```

(regex elided at :842 — read; loop ends :843.) Prompt: `at most $BODY_LINES lines of $BODY_BYTES bytes (longer is cut; a commit over $MARKER_MAX bytes is skipped): $BODY_RULE;` (`:1538`). Executed: `>#x` and `-**Needs:** y` skip (`>` needs no blank), `-#x` is quoted (list marker needs a blank, as the text says) (p2); suite ok 4 covers the rest. D11 (`plan:92`) lists the same five starts; BODY_RULE adds the two later clauses.

**Evidence:** `scripts/build-loop.sh:805-807`, `:836-843`, `:1538`, `docs/working/plan-build-loop-handoff.md:92`, `/tmp/u3b1f2-logs/p2.log`

---

## Claim 19: "The marker commit's size cap in bytes: over it, the body is not processed (marker_kind has still read the commit, in --status' own reads)."

**Location:** `scripts/build-loop.sh:808-809`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cap test before `cat-file commit`; does not establish marker_kind's read cost (Claim 1).

```bash
# scripts/build-loop.sh:829-831
  n="$(git cat-file -s "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }
  [[ "$n" -le "$MARKER_MAX" ]] || { echo "skip $a: its marker is $n bytes, over the $MARKER_MAX-byte cap"; return; }
  m="$(git cat-file commit "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }
```

Executed: 65,536 bytes → `ok`; 65,537 → skip (p2).

**Evidence:** `scripts/build-loop.sh:808-810`, `:829-831`, `/tmp/u3b1f2-logs/p2.log`

---

## Claim 20: "The orchestrator files the body inside an entry it heads itself: the questions readers anchor at column 0, so a quoted line is never read as a heading, a Needs line or an answer (E2, E3). ... (the questions file is read whole by FENCE_AWK: one refused line there would stop every answer in it)"

**Location:** `scripts/build-loop.sh:816-822`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ANSWER_AWK and questions.sh's heading/Needs/answer matches; does not cover questions.sh's index-marker search (not column-0; closed by the `<!--` rule, Claim 22) or its "first prose line" summary pick (`scripts/questions.sh:184`, which may take a `> ` line as an index summary — not a heading, Needs line or answer).

```awk
# scripts/lib/dev-cycle-read.sh:2044-2046
/^(#|##|###) / { inside = 0; next }
!inside { next }
!header && /^\*\*Needs:\*\*/ {
```

```awk
# scripts/lib/dev-cycle-read.sh:2052-2054
!done {
  line = $0; sub(/^- /, "", line)
  if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
```

(excerpts of ANSWER_AWK, which runs :2019-2073 — read; END `if (odd) print "odd " ...` at :2068 is the whole-file stop.) questions.sh: `/^### Q-[0-9]+ /` (`:161`, `:223`, `:364`), `/^\*\*Needs:\*\*/` (`:171`). Executed: mutant printing the T34 body unquoted makes `--check-answer Q-120` print `keep Q-120` instead of `drop Q-120` (p3 `t34-unquoted`).

**Evidence:** `scripts/build-loop.sh:816-822`, `scripts/lib/dev-cycle-read.sh:2040-2073`, `scripts/questions.sh:161-184`, `:223`, `:364`, `/tmp/u3b1f2-logs/p3.log`

---

## Claim 21: "marker_kind has refused a NUL and a second subject line; the headers end at the first empty line."

**Location:** `scripts/build-loop.sh:828`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers gpgsig/mergetag/encoding headers (continuation lines start with a blank, so no header line is empty), a subject followed directly by text, a line holding a blank, and CRLF; does not re-execute the NUL case (i1 verified it statically).

Executed (p2): subject then `Which one?` with no blank, subject then ` ` line, and a CRLF message each → `skip ...: the tip of feat/x starts "handoff:" but is not a marker: its subject runs onto a second line`; signed/encoded headers → body extracted (Claim 4).

**Evidence:** `scripts/build-loop.sh:828-832`, `/tmp/u3b1f2-logs/p2.log`

---

## Claim 22: "# "<!--" anywhere: questions.sh finds its index markers anywhere in a line (security i1 F1)."

**Location:** `scripts/build-loop.sh:839`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers questions.sh's marker constants and --marker's any-position test; does not re-execute the truncation (i1 security F1 did).

```bash
# scripts/questions.sh:140-141
INDEX_START='<!-- index:start -->'
INDEX_END='<!-- index:end -->'
```

render_index locates them with `index($0, start)` (`scripts/questions.sh:340`, per the override row and i2 claim 3; paraphrased — no quote available because this pass cited the line from the prior verified claim rather than re-quoting it); --marker uses `index($l[$i], "<!--") >= 0` (`:840`).

**Evidence:** `scripts/build-loop.sh:839-840`, `scripts/questions.sh:140-141`, `:340`

---

## Claim 23: "(a character is never split)" / "A lead byte whose sequence the cut left short goes with its tail."

**Location:** `scripts/build-loop.sh:103`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 2- and 4-byte characters straddling byte 300 on strict-UTF-8 input (the rule guarantees that input); does not establish behaviour on non-UTF-8 input (skipped before the cut).

```perl
# scripts/build-loop.sh:846-849
      if (length($s) > $ENV{B}) {
        $s = substr($s, 0, $ENV{B}); $cut++;
        # A lead byte whose sequence the cut left short goes with its tail.
        if ($s =~ /([\xC0-\xF7][\x80-\xBF]*)\z/) { my $b = ord($1); $s = substr($s, 0, -length($1)) if length($1) < ($b >= 0xF0 ? 4 : $b >= 0xE0 ? 3 : 2) }
```

(excerpt ends :849; block closes :850, loop :852 — read.) Executed: 298 `x` + U+1F600 + `z` → printed line is `> ` + 298 `x` (300 chars with prefix), note `1 cut at 300 bytes` (p2); suite ok 6 covers the 2-byte case.

**Evidence:** `scripts/build-loop.sh:103`, `:844-853`, `/tmp/u3b1f2-logs/p2.log`, `/tmp/u3b1f2-logs/orch.log`

---

## Claim 24: "Scrubbed first, so the rules, the caps and FENCE_AWK read what is printed." / "FENCE_AWK over the body as written, then as quoted; line N is the body's line N either way."

**Location:** `scripts/build-loop.sh:833`, `:857`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pipeline order (scrub → perl → FENCE passes) and 1:1 line numbering (the note line is appended last); "as written" here, read with `:833`, means the printed lines unquoted. Does not establish that unprinted lines are read (they are not: Claim 5b).

`body="$(printf '%s\n' "$body" | scrub | env LC_ALL=C ... perl -e '...')"` (`:836`) precedes the loop `for m in "$(... | sed -E 's/^> ?//')" "$body"` (`:859`); each quoted line is one body line. Executed: mutant dropping the quoted pass leaves `[a]: b` inside a balanced fence printed (`ok ...`, `> [a]: b`) and fails suite ok 5 (p3 `no-quoted-fence`).

**Evidence:** `scripts/build-loop.sh:833-866`, `/tmp/u3b1f2-logs/p3.log`

---

## Claim 25: "strict UTF-8 (no surrogate or code point past U+10FFFF, as questions.sh check reads it)" (header, BODY_RULE `strict UTF-8`; commit 8367359f: "The rule is now one strict UTF-8 match, as Python reads it")

**Location:** `scripts/build-loop.sh:112-114`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every byte string of length 1-4 over 30 boundary byte values (837,930 strings, LF excluded) compared with `bytes.decode("utf-8")`, the decode `scripts/questions.sh:242` runs; does not establish strings longer than 4 bytes (the regex is a `*` over per-character alternatives, so longer strings compose).

The regex was extracted verbatim from `:842` and run in `perl` under `LC_ALL=C`: `cases 837930 mismatches 0` (p5). questions.sh check: `python3 -c 'import sys; open(sys.argv[1],"rb").read().decode("utf-8")'` (`scripts/questions.sh:242`).

**Evidence:** `scripts/build-loop.sh:112-114`, `:807`, `:842`, `scripts/questions.sh:242`, `/tmp/u3b1f2-logs/p5.log`, `/tmp/u3b1f2-logs/f2-probe5.sh`

---

## Claim 26: "state_start is its state half (all --state runs once main is found: rows 525, 690)."

**Location:** `scripts/build-loop.sh:1170-1171`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `--state` runs state_start alone after main_by_name, and gate_start = state_start + settings reads; does not establish row 690's dispatch half (deferred row).

```bash
# scripts/build-loop.sh:1179-1182
gate_start() {
  state_start
  reader_settings; read_settings; never_res; open_shared
}
```

`state) state_start; echo ok ;;` (`:1550-1553`).

**Evidence:** `scripts/build-loop.sh:1170-1182`, `:1550-1553`, `:586`

---

## Claim 27: Loop prompt: ""handoff: blocked", ... at most $BODY_LINES lines of $BODY_BYTES bytes (longer is cut; a commit over $MARKER_MAX bytes is skipped): $BODY_RULE;"

**Location:** `scripts/build-loop.sh:1538`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the variables are set at top level (`:807-810`) before the final `case` runs `dispatch`, and that "cut"/"skipped" match marker(); does not render the prompt by execution.

`BODY_LINES=100; BODY_BYTES=300; MARKER_MAX=65536` (`:810`); cut and skip behaviour per Claims 4, 19.

**Evidence:** `scripts/build-loop.sh:805-810`, `:1538`

---

## Claim 28: "# A plain caller pair passes; a count harden would misread stops every mode (row 276)."

**Location:** `test/scripts/build-loop-orchestrator.bats:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim's behaviour; the test itself exercises `--settings` only for the count cases, so "every mode" is pinned by p1 C, not by the suite.

Test runs `for c in 010 08 1x " 1"; do ... bash "$BL" --settings` (`:52-55`). p1 C: all eight modes exit 1 with no git call. Note git itself accepts `" 1"` (p1 B: one command pair), so refusing it is stricter than git, consistent with "plain decimal".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:50-55`, `/tmp/u3b1f2-logs/p1.log`

---

## Claim 29: "# Only --state reads the caller's environment: neither --settings nor the gated --check refuses for it."

**Location:** `test/scripts/build-loop-orchestrator.bats:56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --settings and --check; does not run --merge/--start/--prompt with a caller variable (checkout_gate still refuses one for a self-merge brief, per ec9ba0c7's note).

Mutant making caller_gate run in every mode (p3 `caller-every-mode`) fails at `:57`: `--settings` → `status 2`, `refuse state GIT_REPLACE_REF_BASE: ...`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:56-61`, `scripts/build-loop.sh:583`, `/tmp/u3b1f2-logs/p3.log`

---

## Claim 30: "# Inside a balanced fence the raw pass reads nothing; quoted, the line is a link reference definition."

**Location:** `test/scripts/build-loop-orchestrator.bats:110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that this case depends on the quoted pass; does not test other raw-only/quoted-only refusals.

Mutant without the quoted pass prints `ok ...`, `> ```` `, `> [a]: b` and the test fails (p3 `no-quoted-fence`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:110-111`, `/tmp/u3b1f2-logs/p3.log`

---

## Claim 31: "# A marker commit over the cap is skipped before its body is processed (performance i1 F1)."

**Location:** `test/scripts/build-loop-orchestrator.bats:112`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip and its order in code; the test asserts the skip line only, not that the body was unprocessed (that is shown by code order, Claim 19).

Suite ok 5 passes; the cap test (`:830`) precedes `cat-file commit` (`:831`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:112-114`, `scripts/build-loop.sh:829-831`, `/tmp/u3b1f2-logs/orch.log`

---

## Claim 32: "# Moved before land's default_gate re-run: still the compare-and-swap's refusal, not a non-commit (U3b1 B4)." (also 8367359f: "the old MAIN_SHA compare as a mutant turns it red")

**Location:** `test/scripts/build-loop-merge.bats:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-worktree path; does not test the W fast-forward path with a moved main.

The commit-tree shim moves main inside land, before the re-run (`:61`). Executed mutant (p5) → `not ok 2`, output `refuse ...: the git state changed after the check (refuse state default-branch: refs/heads/main names an object that is not a commit)`.

**Evidence:** `test/scripts/build-loop-merge.bats:60-63`, `/tmp/u3b1f2-logs/p5.log`, `/tmp/u3b1f2-logs/merge.log`

---

## Claim 33: Commit ec9ba0c7: "(GIT_REPLACE_REF_BASE, GIT_GRAFT_FILE and the object directories name files the state gate never reads)"

**Location:** commit `ec9ba0c7` message, paragraph 1
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY against state_gate's `--git-path` reads; does not concern the code, which is right, nor the in-code comment (`:523-526`, Claim 12), which was corrected.

GIT_GRAFT_FILE moves `info/grafts` and GIT_OBJECT_DIRECTORY moves `objects/info/alternates` — both files state_gate reads (p6; Claim 12). Text-only and historic: 8f99a919's body already says "GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY move files the state gate reads", but the rubric's "commit-body corrections owed in the merge message" lists only 8f99a919's two phrases; this one is not on that list.

**Evidence:** `git log -1 ec9ba0c7`, `scripts/build-loop.sh:496-499`, `/tmp/u3b1f2-logs/p6.log`

---

## Claim 34: Commit ec9ba0c7 Notes: "caller_gate runs in --state only, so --check keeps its behaviour for a caller's variables (checkout_gate still refuses them for a self-merge brief); --marker's grammar match ignores case (stricter than ANSWER_AWK's Needs match); an empty line quotes as ">" (no trailing blank in the questions file)."

**Location:** commit `ec9ba0c7` message, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the caller-variable behaviour of --check (not its new annotated-tag refusal, a deliberate change, Claim 7), the case comparison, and `>`; does not establish checkout_gate by execution.

`--check` with `GIT_REPLACE_REF_BASE` and a `merge.x.driver` pair prints `ok` (suite `:59-61`, passing). ANSWER_AWK's Needs match is case-sensitive: `!header && /^\*\*Needs:\*\*/` (`scripts/lib/dev-cycle-read.sh:2046`); --marker's uses `/i` (`:840`). `print $s eq "" ? ">\n" : "> $s\n"` (`:851`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:56-61`, `scripts/build-loop.sh:840`, `:851`, `scripts/lib/dev-cycle-read.sh:2046`, `/tmp/u3b1f2-logs/orch.log`

---

## Claim 35: Commit 8f99a919: "a marker commit over 64 KiB is skipped unread" and "one that is not valid UTF-8 ... breaks the body rule"

**Location:** commit `8f99a919` message, paragraph 1
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two phrases against HEAD; does not re-open the code (fixed in 8367359f).

"Unread": marker_kind (via status_fields) reads the commit before the cap, and `cat-file -s` reads its header (`:824`, `:829`); the precise phrase is "its body is not processed" (`:808`). "Valid UTF-8": at 8f99a919 the rule used Perl's lax decoder (i2 claim 7b); HEAD uses the strict regex (Claim 25). Text-only; both are already listed in the rubric under "Commit-body corrections owed in the merge message".

**Evidence:** `git log -1 8f99a919`, `scripts/build-loop.sh:808`, `:824-831`, `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b1.md`

---

## Claim 36: Commit 8f99a919: "default_gate tests the ref's own object type rather than comparing it with the startup MAIN_SHA, so land's re-run leaves a moved branch to the compare-and-swap's own refusal"

**Location:** commit `8f99a919` message, paragraph 2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism (Claim 15) and the no-worktree outcome; does not cover the W path the phrase omits.

Mechanism right (executed, Claim 15). The phrase omits the worktree path, where the refusal is W's `merge --ff-only` (`:1417-1418`); the code comment and plan now say "the compare-and-swap, or the fast-forward in W". Text-only; this commit-body phrase is not in the rubric's owed list (C3 fixed only the code/plan text).

**Evidence:** `git log -1 8f99a919`, `scripts/build-loop.sh:560-563`, `:1410-1420`, `/tmp/u3b1f2-logs/p5.log`

---

## Claim 37: Commit 8367359f: "C1 ... Tested with raw commits ... for a stray byte, a surrogate and a code point past U+10FFFF ... C2 (claim 15): the size cap is tested before the body is read ... C4 (claim 9): --state's exit-1 list names a GIT_DIR naming no repository only."

**Location:** commit `8367359f` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three test bytes, the cap order and the header's exit-1 list; the "old decoder as a mutant" sentence was not re-run here (the regex/Python equivalence was, Claim 25).

Test loop `for b in '\377' '\355\240\200' '\364\220\200\200'` (`test/scripts/build-loop-orchestrator.bats:90`); cap order `:829-831`; header `:125-126` "or a GIT_DIR naming no repository" with GIT_WORK_TREE absent (p1 D shows GIT_WORK_TREE → exit 2).

**Evidence:** `git log -1 8367359f`, `test/scripts/build-loop-orchestrator.bats:88-92`, `scripts/build-loop.sh:125-126`, `/tmp/u3b1f2-logs/p1.log`

---

## Claim 38: Commit 1bf01630: "the T34 case passes now (it pins the readers) and fails with the body unquoted"

**Location:** commit `1bf01630` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the body-unquoted mutant of the test; does not cover a mutant where --marker itself stops quoting (the test builds the quoted body itself, so it pins the readers, as the message says, not --marker).

p3 `t34-unquoted`: `not ok 1 ...` with `keep Q-120` against the wanted `drop Q-120`.

**Evidence:** `git log -1 1bf01630`, `test/scripts/build-loop-orchestrator.bats:147-160`, `/tmp/u3b1f2-logs/p3.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 33** (commit `ec9ba0c7`): says GIT_GRAFT_FILE and the object directories "name files the state gate never reads"; GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY move files it reads. Text-only, historic (8f99a919's body corrects it); add to the merge message's corrections list.
- **Claim 35** (commit `8f99a919`): "skipped unread" and "valid UTF-8". Text-only; already on the rubric's owed merge-message corrections.

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`docs/working/plan-build-loop-handoff.md:324`, and commit ec9ba0c7): "refuses a default branch that names anything but a commit": the refusal fires only for an annotated tag; a tree/blob main is not found by name (exit 1) or meets the both-names refusal. Use the header's "(an annotated tag)" wording.
- **Claim 5b** (`scripts/build-loop.sh:115-117`): "a line of the body, as written ..., that FENCE_AWK refuses": only the printed lines (first 100, cut) are read; a refused line at body line 101 passes (p9). Say "a printed line, unquoted or quoted".
- **Claim 36** (commit `8f99a919`): "leaves a moved branch to the compare-and-swap's own refusal" omits W's fast-forward. Text-only.

### Unverifiable
- **Claim 1b** (`docs/reviews/override-log.md:711`): "~145 MB" for a 16 MB marker; needs `/usr/bin/time -v` (absent in the sandbox).

No Incorrect claim is behavioural: both are commit-message text. No code defect was found in this pass; all 8 orchestrator and 12 merge suite cases pass, and the 6 mutants run here (T34 unquoted, caller_gate in every mode, no decimal check, caller config read with harden's count, no quoted FENCE pass, B4's MAIN_SHA compare) each turn a suite red.

## Goal-Alignment Note

The unit's goal (shared brief §"What this PR is trying to accomplish") is that `--state` reports the repository's gated state and the caller's git environment, and `--marker` hands the orchestrator a body no questions reader can mistake for entry grammar. The code does that. The executed checks (git's ordering of `-c` after COUNT pairs, the `010` stop before any git call in all eight modes, the strict-UTF-8 regex matching Python's decode across 837,930 byte strings, column-0 anchoring, the 64 KiB boundary, odd commit headers) found no behaviour that departs from the documented contract. The open items are wording only: the header's FENCE_AWK clause is broader than the printed-lines check (which is what keeps the output safe), the plan's "anything but a commit" is broader than the tag-only refusal, and three commit-message phrases need merge-message corrections (one of them, ec9ba0c7's GIT_GRAFT_FILE phrase, is not yet on the rubric's list). Forward-dependent claims (U4 running `--state` each iteration and without git_harden exported; rows 493/494/517 closing) cannot be checked until U4 exists.
