Commit: 9e5d92df

# Architecture Review — feat/build-loop-u2b1a (U2b1a, `--check`'s frame), iteration 2

**Scope:** `git diff main...HEAD` (code: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh` help; `test/scripts/build-loop-check.bats` for context only)
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b1a-i2.md` (shared brief's Stage 1 summary); plan `docs/working/plan-build-loop-handoff.md` (D6, D7, step 5 U2b split, U3/U3b)

Scope check: in scope. The diff adds a public mode (`--check`), moves a module responsibility (brief enumeration, F31) into the shared lib, adds two lib exports (`open_shared`/`OPEN_SHARED`, `anybrief`), and introduces a cross-cutting concern (process-wide git hardening and a state gate).

Trust-boundary cross-reference: the only `docs/reviews/security-review-*.md` files are the 2026-08/09 egress reviews (another subsystem); no finding below coincides with their labeled boundaries, so the cross-reference is a no-op. The U2b1a security review, if it runs this pass, is under `security-reviewer-review-*`, which the scan pattern does not match.

## Dependency Map

- `build-loop.sh` and `dev-cycle.sh` both source `scripts/lib/dev-cycle-read.sh` from their own directory. Dependency direction stays correct: scripts → lib, and the lib never calls back into a script.
- New in this diff: the lib owns brief enumeration (`open_shared`, which uses `main_by_name`, `anybrief`, `brief_fields`, `lower` and `MAIN_SHA`). `build-loop.sh`'s `status_line` consumes the result as `OPEN_SHARED`.
- `build-loop.sh` owns the gate's environment and policy: `harden` (four config-count pairs and four `GIT_*` exports, applied process-wide before the first git call), `state_gate` (runs before `resolve_main` in `--check` only), `merge_result` (merge-tree in an empty cwd under `GATE_TMP`), and `check_line`. `check_line` → `status_line` (text) → `check_brief`/`brief_fields`/`check_branch`/`marker_kind`, then `check_branch` again, then `merge_result`.
- The lib's git calls are hardened only through the environment they inherit. Under `build-loop.sh` they inherit `harden`; under `dev-cycle.sh` they run with `GIT_LITERAL_PATHSPECS=1` alone.
- Later consumers named by the plan: U2b1b (diff-tree on MAIN→TREE inside `check_line`), U2b2 (lib header contract items 2–4: the gate's checkout), U3 (`--merge`: commit-tree on TREE plus a CAS on main, reusing `check_line`), U3b (`--state`, reusing `state_gate`), and the D6 snippet (inline in SKILL.md, with its own replace-ref and graft precheck).

## Findings

#### 1. Git hardening has three placements, and the lib's functions are hardened only when build-loop.sh calls them

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:147-162`; `scripts/lib/dev-cycle-read.sh:421-422`; `scripts/dev-cycle.sh:127`
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`harden` runs as a process-wide environment property set by `build-loop.sh`. The lib functions it protects (`check_brief`, `check_branch`, `brief_fields`, the import walks behind `truthwalk`, which run `git ls-files --others`) are also called from `dev-cycle.sh` (`--check-brief`, `--check-branch`, `--check-fix`), which exports only `GIT_LITERAL_PATHSPECS=1`. Iteration 1's C3 fix then added a per-call hardening (`--no-textconv`) inside the lib itself. The same concern ("the gate's git runs no repo-planted command") now has three homes: env pairs in one script, a per-call flag in the lib, and a state gate in that script for `--check` only. No single place says which lib calls are safe under which entry point. The next hardening need (U2b1b's diff-tree, U2b2's checkout reads, a new lib call) has to pick one of the three, and a fix placed in the env pairs silently fails to cover `dev-cycle.sh`. Override row 387 settled "the caller owns git hardening", with the revisit trigger "U2b's hardened git wrapper". This diff meets that trigger without restating the rule for the second caller.

**Evidence:**
```
# Every git call in this process, the lib's included, runs hardened through
# config-count pairs, which outrank the repo's config: ...
harden() {
  local c="${GIT_CONFIG_COUNT:-0}" kv
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null; do
```
```
  # --no-textconv: -G greps the diff, and a repo-local textconv driver would run.
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv -G'^Status: ' "$MAIN_SHA" -- "$a")"
```
```
TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1
```

**Recommendation:** Move `harden` and its four exports into the lib as one function (for example `git_harden`), and call it from both scripts right after sourcing. Add one line to the lib header's caller rules: "call git_harden before any git call". `state_gate` can stay in `build-loop.sh`, its only caller (see 4). Then per-call flags like `--no-textconv` remain belt-and-braces rather than the only cover for one entry point. Cite row 387 as closed or re-pointed.

#### 2. check_line parses status_line's printed --status line positionally, then re-reads and re-parses check_branch

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:456-474` (`check_line`), against `status_line` `:397-434`
**Move:** 7 (content coupling: a consumer depends on another function's output text)
**Confidence:** Medium
**Legibility-target:** for-author

`check_line` recovers STATE, BRANCH, LOOP and SHA by field position from the `--status` line: `read -r _ _ st _ br loop sha _`. That line is also a public output format documented in the header and read by the skill. Any later field added before SHA (U2b1b or U3 may want one), or a change to the `new` and `absent` placeholder rows (`- absent - - 0`), would shift `check_line`'s reading without failing a test that targets `check_line`. `check_line` then calls `check_branch` again and parses that line positionally too. The gate thus reads its own module's data through two printed formats, and U3's `--merge` inherits both by reusing `check_line`. Separately, the `read` is excerpted: the whole function continues to `:474`, and the second parse is `read -r _ _ _ n _ <<<"$out"`.

**Evidence:**
```
  out="$(status_line "$a")"
  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
  read -r _ _ st _ br loop sha _ <<<"$out"
```
```
  echo "ok $a $st $pol $br $loop $sha $date $disp$reason"
```

**Recommendation:** Follow `brief_fields`' pattern. Add a `status_fields` that sets a `STATUS[...]` associative array in the calling shell, with `status_line` as its printer. `check_line` already runs in its own subshell, so it can call `status_fields` there and read named fields. At minimum, add one test that pins `check_line`'s field reading against the `--status` format.

#### 3. open_shared's once-per-process cache does not follow the lib's cache conventions

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:452-477`; `scripts/build-loop.sh:399`, `:487`
**Move:** 3 (module boundary), 7
**Confidence:** High
**Legibility-target:** for-author

The lib's existing walk caches are keyed on their inputs: `IMPORTED_MAIN_DONE` holds the commit, `MAIN_BY_NAME` and the root, and `import_reset` clears them (contract item 4). `OPEN_SHARED` is keyed on nothing, using an empty-string sentinel. It is computed from `MAIN_SHA` but survives a second `resolve_main`, which the header explicitly allows ("a second call re-reads main"). `import_reset` does not clear it, and a cached `error` is sticky. This is correct today only because each mode resolves main once. U3's `--merge` moves main by CAS, and a loop-style caller may re-resolve, so either would read a stale list. "Once per process" also holds only because the `--check` case block calls `open_shared` in the parent shell before `check_line`'s subshell runs `status_line`. That ordering dependency lives in a one-line comment in the case block, and `open_shared` is not in the lib header's list of call-in-the-caller's-shell functions.

**Evidence:**
```
OPEN_SHARED=""
open_shared() {
  local f list b rc=0
  local -A count=() BRIEF=()  # a local BRIEF: the caller's stays as it was
  [[ -z "$OPEN_SHARED" ]] || return 0
```
```
    open_shared  # once, in this shell: check_line runs in a subshell
```

**Recommendation:** Key the cache to its input (`OPEN_SHARED_AT="$MAIN_SHA"`; recompute when it differs), and clear it in `import_reset` or a renamed `gate_reset` so contract item 4 covers it. Add `open_shared` to the header's list of functions to call in the caller's shell.

#### 4. The state gate's extension point is a key-name regex, but its routed next rules are value predicates and its contract lives in the lib

**Severity:** Minor
**Location:** `scripts/build-loop.sh:181-200` (`STATE_KEYS_RE`, `state_gate`); `scripts/lib/dev-cycle-read.sh:43-54` (contract items 2–3)
**Move:** 8 (extension points), 2
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Keeping `state_gate` in `build-loop.sh` is the right placement: U3b's `--state` is a mode of the same script, and the D6 snippet cannot source anything before extraction anyway. But the rules routed to it next do not fit its shape. Contract item 3 (U2b2) needs `core.symlinks` = false; item 2 names `core.ignoreCase` and sparse checkout; U3's commit-tree needs `i18n.commitEncoding` and `user.*` (finding 5). These are value tests or call-specific inputs. A name regex can only refuse a key's presence, and `git init` writes `core.symlinks`/`core.ignoreCase` on some filesystems, so refusing the name would refuse legitimate repos. Meanwhile the duties are stated in the lib header and enforced in the script, and the header does not name `state_gate` as their enforcer. The D6 snippet's precheck (replace refs, grafts) is a third partial list of the same state, which must stay a subset of `state_gate`'s.

**Evidence:**
```
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
```
```
#  3. Refuse a checkout whose core.symlinks is false or with a
#     working-tree-encoding, filter or ident attribute on any path the walk
#     reads (.gitattributes, $GIT_DIR/info/attributes, core.attributesFile).
#     U2b builds this; the walk does not check it.
```

**Recommendation:** When U2b2 lands, give `state_gate` a second table of key=value refusals beside the name regex, and have items 2–3 in the lib header name `state_gate` as their enforcer. When U3b ships the D6 snippet, add a test that its precheck list is a subset of `STATE_KEYS_RE` plus the file checks.

#### 5. The temporary-GIT_DIR plan for merge-tree is the right boundary; it needs the object format, and U3's commit-tree should share it for a different reason

**Severity:** Minor
**Location:** `scripts/build-loop.sh:436-453` (`merge_result`, the planned fix's site); plan D7 (`commit-tree R -p MAIN -p TIP`, CAS)
**Move:** 3, 8
**Confidence:** Medium (probes on git 2.39.5; the sha256 point is reasoned, not run)
**Legibility-target:** for-author

The plan narrows merge-tree's inputs to the object store plus two hashes, so no config, `modules/`, `shallow` file or promisor of the real repo reaches it. That is a cleaner boundary than extending `STATE_KEYS_RE` call by call. Four points for the plan:

- **(a) Object format.** A plain `git init --bare` makes a sha1 repo. `--expect` and `merge_result` accept 64-hex ids, so on a sha256 repo the temp dir must be initialized with the repo's object format, or merge-tree cannot read the store (it would fail closed, as "could not be computed").
- **(b) Global and system config.** The temp dir still reads the user's global and system config. Whether that is in scope is the security reviewer's call; `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM=1` would make it hermetic.
- **(c) The `shallow` file.** It is GIT_DIR-side, so the temp dir drops it. Probe: a planted `.git/shallow` naming both tips made the real-repo merge-tree print "refusing to merge unrelated histories" (rc 128). The temp dir with only `GIT_OBJECT_DIRECTORY` merged normally. The state gate refuses `info/grafts` but not `shallow`, which also rewrites parents; after the fix that difference remains for `check_branch`'s `rev-list --count` and `marker_kind`'s parent read.
- **(d) U3's commit-tree.** It opens no submodule, so the lazy-fetch reason does not carry over. Probe: on 2.39.5 it ignored `commit.gpgSign=true` with a `gpg` shim on PATH. But it does read repo config that changes the object: `i18n.commitEncoding=ISO-8859-1` added an `encoding ISO-8859-1` header to the commit. `user.*` sets the identity. Neither is in `STATE_KEYS_RE`.

So yes: running commit-tree in the same temp GIT_DIR, with explicit `GIT_AUTHOR_*`/`GIT_COMMITTER_*`, gives one isolation for every object-writing call. The CAS (`update-ref`) must stay in the real repo, where the refs are. That is the one hardened real-repo write (its reference-transaction hook is covered by the `core.hooksPath` pair).

**Evidence:**
```
  t="$(mktemp -d "$GATE_TMP/m.XXXXXX")" || return 2
  out="$(cd "$t" && git --git-dir="$common" merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
```

**Recommendation:** Build the fix as one helper (for example `gate_git`), created once per process under `GATE_TMP`. It sets `GIT_DIR` (initialized with the repo's object format) and `GIT_OBJECT_DIRECTORY`, and optionally `GIT_CONFIG_GLOBAL`/`GIT_CONFIG_NOSYSTEM`. merge-tree uses it now, U3's commit-tree later. Name in its comment which calls must stay in the real repo (ref reads, the CAS).

#### 6. check_line's aggregation reads only the first line's prefix; U2b1b's multi-line output will need a different rule

**Severity:** Minor
**Location:** `scripts/build-loop.sh:485-494` (the `check)` case), `:454-455` (`check_line`'s header)
**Move:** 8
**Confidence:** High
**Legibility-target:** for-author

`check_line`'s comment says "U2b1b adds the changed paths", and the plan says `--check` will add one line per changed path plus deny lines. The case block judges a brief by `[[ "$out" == "ok "* ]]` on the whole captured output. On a multi-line `$out`, that matches whenever the first line starts with `ok`, so a later deny line would not set `fails`. This is correct for U2b1b's single line today, but it is the extension point the next unit edits. An extension that only appends lines inherits a fail-open aggregation.

**Evidence:**
```
    for a in "${ARGS[@]}"; do
      out="$(check_line "$a")"; printf '%s\n' "$out"
      [[ "$out" == "ok "* ]] || fails=1
    done
```

**Recommendation:** Either have `check_line` return its verdict as its exit status (the case block then tests `$?`), or note in `check_line`'s header that U2b1b must change the aggregation to "every line ok". The exit-status form keeps the verdict out of the text format (compare finding 2).

#### 7. Plan text names a state gate "from install.sh" and a `refuse KEY` format that this diff does not use

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:84` (D7), `:207` (`--state`)
**Move:** 3
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

No `install.sh` exists in the repo. `state_gate` in `build-loop.sh` is now the single statement of the gate's state rules. U3b's `--state` is planned to print `refuse KEY`, while `state_gate` prints `refuse state WHAT: WHY`. Fixing this now avoids U3b building a second format or hunting for a second gate.

**Evidence:**
```
All git calls are hardened, with the state gate from `install.sh`.
```
```
- `--state` → `ok`, or `refuse KEY` for each planted `.git` state the gate refuses (exit 2).
```

**Recommendation:** Re-point D7 to `state_gate` in `scripts/build-loop.sh`, and give `--state`'s line as `refuse state WHAT: WHY`.

## What Looks Good

- **Ordering.** Hardening is applied before the first git call (`rev-parse --show-toplevel`), and the state gate runs before `resolve_main`, the first object read. The protection is at the composition root, not scattered per call (finding 1 is about the second entry point, not this one).
- **F31 moved into the lib** (rows 298, 323). `open_shared` reads every candidate through `brief_fields`/`main_entry`, so the lib keeps one brief read path, and `anybrief` collapses the three spellings of the closed/ rule.
- **`merge_result`** isolates the merge by construction (an empty cwd) rather than by enumerating attribute sources. It returns a three-way verdict (0/1/2) that `check_line` maps without parsing git's text, beyond validating the tree id.
- **`check_line` hands merge_result the re-verified SHA, never the branch name**, so a branch moving after the check cannot change what is merged.
- **Row 307 handled at the source.** `check_branch` and `marker_kind` read into locals and refuse on failure, so the fix also covers `dev-cycle.sh`'s `--check-branch`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Hardening in three places; lib calls hardened only under build-loop.sh (row 387's trigger met) | Coupling | `build-loop.sh:147-162`, `lib:421-422`, `dev-cycle.sh:127` | High |
| 2 | check_line parses status_line's and check_branch's printed lines by position | Coupling | `build-loop.sh:456-474` | Medium |
| 3 | open_shared cache unkeyed, not cleared by import_reset, sticky error, ordering-dependent | Minor | `lib:452-477`, `build-loop.sh:487` | High |
| 4 | State gate is a name regex; next rules are value predicates; contract and enforcer split | Minor | `build-loop.sh:181-200`, `lib:43-54` | Medium |
| 5 | Temp-GIT_DIR plan: needs the object format; commit-tree should share it (i18n.commitEncoding, user.*) | Minor | `build-loop.sh:436-453`, plan D7 | Medium |
| 6 | `"ok "*` aggregation fails open once check_line prints several lines | Minor | `build-loop.sh:485-494` | High |
| 7 | Plan names a state gate in install.sh and a different `--state` format | Informational | plan `:84`, `:207` | High |

## Overall Assessment

The frame keeps dependency direction right (scripts → lib) and moves the right responsibility into the lib (brief enumeration). The gate's isolation is placed well for build-loop.sh's own process. The most important structural concern is finding 1: git hardening is now a property of one entry point's environment plus scattered per-call flags. The lib's functions therefore have different safety under `dev-cycle.sh` than under `build-loop.sh`, and each later unit (U2b1b, U2b2, U3) has to choose among three placements. One lib-level `git_harden` called by both scripts fixes it in place. The other findings shape the extension points U2b1b, U2b2 and U3 will edit: the positional parse of `--status` text, the unkeyed `OPEN_SHARED`, the name-only state rules and the first-line aggregation. None needs restructuring. On the planned submodule fix: the temp GIT_DIR is the right boundary. It needs the repo's object format, and U3's commit-tree should run in the same temp dir. The reason is not the lazy fetch but repo config that changes the commit (`i18n.commitEncoding`, `user.*`), which the state gate does not list.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 9e5d92df` line at the top.
- Answered: yes
- Out of scope: whether the user's global/system git config is inside the gate's threat model (security reviewer); the exploitability of `dev-cycle.sh`'s unhardened `ls-files --others` under a planted `core.fsmonitor` (security; finding 1 frames only the structure).
- Escalate: nothing
