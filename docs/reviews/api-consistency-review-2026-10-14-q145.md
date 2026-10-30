Commit: 0d573a7b

# API Consistency Review: fix/q145-ancestor-vanish (iteration 2)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-q145 (4 files: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/thoughts/failure-patterns.md`)
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-2026-10-14-q145-i2.md` (0 Incorrect; Claims 2 and 10 feed findings 2 and 3 below)

## Baseline Conventions

The public surface here is the lib's internal function API (the lib is sourced by the dev-cycle scripts, and `test/scripts/dev-cycle.bats:1113-1115` pins its function list) and the bats file's test-helper knobs.

- **NAME-array helpers** (`with_at`, `outside_seeds`, `config_seeds`, `c1_seeds`, `root_copies`, `import_work`, `nul_list`): the output array's name comes first, then positional inputs. The header opens `fn NAME ARG...:` with the arguments in caps. It then says "array NAME gets ..." when the array is replaced (`with_at`, `nul_list`) or "appends ... to array NAME" when it is added to (`config_seeds`, `c1_seeds`). The body binds it as `local -n <prefix>_a="$1"`, where the prefix comes from the function's initials (`wa_a`, `ow_a`, `os_a`, `c1_a`, `nl_a`).
- **Stream producers** (`root_starts`, `tree_starts`, `md_ls`, `lower_all`, `instruction_names`): these print NUL-separated output, the caller wraps them in `nul_list NAME`, and they take no NAME.
- **Return-contract wording:** NAME-filling helpers say "It returns 1 when ..." (`with_at` :1365, `outside_seeds` :1497, `config_seeds` :1507, `c1_seeds` :1587, `import_work` :1617). Stream producers say "It fails when ... does" (`root_starts` :1354).
- **Provenance tags:** each provenance tag goes in parentheses at the end of a clause, e.g. `(i2 api F1)`, `(U2a3b final N1)`, `(... : Q-145)`.
- **Nameref collisions:** these are documented only at the outermost entry point. `outside_seeds` (:1499-1500) says "NAME must not be one of the three functions' locals". Neither `with_at` nor `nul_list` documents its own nameref.
- **Test knobs** (`build-loop-check.bats:16-19`): `T_*` environment variables are documented in the file header as inputs that the `imps` helper consumes (`T_READER_ROOTS`, `T_READER_HOMES`, `T_SETTINGS=1`, `T_MANAGED`). Earlier PATH shims in this file (`:264`, `:460-466`, `:507-525`, `:626`) take no knobs. To change a shim's behaviour, those tests write a different shim file.
- **Test titles:** each title is a behaviour sentence ending in a parenthesised provenance tag. Q-ids appear in titles elsewhere (`test/install-host.bats:928` "(Q-058)", 60 such titles repo-wide).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `top_files` | lib function | `root_starts`, `tree_starts`, `with_at` | `scripts/lib/dev-cycle-read.sh:1355,1361,1654` | Consistent: `<scope>_<kind>` shape, and "top" is config_seeds' own term (`tops=()`) |
| `top_files NAME DIR...` (signature) | parameter order | `with_at NAME PATH...`, `config_seeds NAME`, `nul_list NAME CMD...` | `scripts/lib/dev-cycle-read.sh:1356,1506,1636` | Consistent: NAME first, variadic inputs after |
| (no `local -n` binding; passes `"$1"` to nul_list) | nameref local | `wa_a`, `os_a`, `c1_a`, `nl_a` | `scripts/lib/dev-cycle-read.sh:1362,1511,1589,1637` | Consistent: binds no nameref of its own, so it adds no name to the collision set. The only collision is nul_list's `nl_a` (Finding 4) |
| `T_ONCE` | test env knob | `T_SETTINGS`, `T_READER_ROOTS`, `T_MANAGED` | `test/scripts/build-loop-check.bats:16-19` | Minor: uses the `T_` namespace that the file header documents as imps' inputs, but only the test's find shim reads it (Finding 1) |
| `T_RMTOP` (values `1`, `drop`) | test env knob | same | `test/scripts/build-loop-check.bats:16-19` | Minor: same as `T_ONCE`. It is also the first enum-valued `T_` knob (existing ones are booleans or paths) |
| `"$a/shim"`, `"$a/shim/log"`, `"$a/shim/fired"` | test fixture paths | `$BATS_TEST_TMPDIR/bin`, `gbin`, `$tb`, `$S=.../py` | `test/scripts/build-loop-check.bats:264,466,507,626` | Consistent: shim directory names already vary per test |
| test title "...(Q-145)" | test name | "(U2b3b2b)", "(Q-058)" | `test/scripts/build-loop-check.bats:712`, `test/install-host.bats:928` | Consistent |
| FP-173 | failure-pattern entry | FP-170..172 | `docs/thoughts/failure-patterns.md:312-314` | Consistent: same `symptom:/cause:/fix:/ref:` grammar |

## Findings

#### 1. Shim-only knobs share the `T_` namespace the file header reserves for imps' inputs

**Severity:** Minor
**Location:** `test/scripts/build-loop-check.bats:733-742,758,770`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a maintainer of `build-loop-check.bats` reading the `imps` header

Precedent: `T_*` env vars documented as the `imps` helper's inputs, used in `test/scripts/build-loop-check.bats:16-25`

**Evidence:**
```
# T_READER_ROOTS and T_READER_HOMES, when set, become the caller's
# IMPORT_READER_ROOTS and IMPORT_READER_HOMES after the lib is sourced (it clears them);
# T_SETTINGS=1 sets them as the scripts do, with reader_settings. T_MANAGED
# becomes IMPORT_MANAGED_DIR (by default a path that does not exist).
```
and in the new test:
```
if [[ -n "\${T_ONCE:-}" && -e "$a/shim/fired" ]]; then "$real" "\${args[@]}" "\$@"
...
PATH="$a/shim:$PATH" T_ONCE=1 imps "$w" docs/a.md docs/other.md
```

The file header lists the `T_` knobs and what `imps` does with each. `T_ONCE` and `T_RMTOP` are passed on the `imps` command line just as those knobs are, but `imps` ignores them. They reach the test's own find shim only because `env` passes the environment through. A reader who greps for `T_ONCE` finds it next to `imps` and may look for it in the header. The test's leading comment does explain both knobs, so nothing is wrong at runtime and nothing leaks between tests (`$BATS_TEST_TMPDIR` scopes the shim). This is a legibility issue only.

**Recommendation:** Do one of two things. Either give the shim knobs a distinct prefix (e.g. `SHIM_ONCE`, `SHIM_RMTOP`), or add a header line saying that a test's own shim may also read `T_*` knobs and documents them in that test's comment. Optional; not a merge blocker.

#### 2. config_seeds' header ties "after three tries" to a vanished entry only

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1506-1509`
**Move:** 3 (consumer contract / documentation drift)
**Confidence:** High
**Legibility-target:** a caller of config_seeds (outside_seeds)

**Evidence:**
```
# config_seeds NAME: appends outside_seeds' items (1) and (2) to array NAME. It
# returns 1 when a find, grep, realpath or lower_all fails (the top-level
# listing, top_files, after three tries, for an entry that vanishes
# mid-listing: Q-145), or a top is no longer a directory after it.
```
The call site retries on any failure:
```
top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1
```

Read as written, the parenthesis says top_files gets three tries for a vanished entry. A permission error or link loop could then seem to fail at once. In fact every top_files failure is tried three times (fact-check i2 Claim 2 scope note; the test pins `1 1 1` for an unreadable top at `build-loop-check.bats:768`). The return value is the same either way, so callers are not misled about *whether* config_seeds fails. They are misled about *how often* find runs before it does, and about whose stderr survives (only the third try's). The walk-level comment at :1549-1553 states this correctly ("a permission error, a link loop or a missing top fails every try").

**Recommendation:** Reword to e.g. "(the top-level listing, top_files, after three tries, retried for an entry that vanishes mid-listing: Q-145)", or "...after three tries of any failure (Q-145)".

#### 3. top_files' header omits the depth-0 case for a dangling DIR link

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1579-1584`
**Move:** 8 (nullability / output contract)
**Confidence:** High
**Legibility-target:** a future caller of top_files other than config_seeds

**Evidence:**
```
# top_files NAME DIR...: array NAME gets the files and links (-xtype f or l,
# links followed only as DIRs: -H) directly in each DIR, NUL-separated through
```
Probe (findutils 4.9.0): `top_files z "$d/dl"` where `dl -> /nonexistent` gave `dangling rc=0 /tmp/tmp.ZTldUNoBTX/dl`. The DIR argument itself is in NAME, and the exit status is 0.

The header promises entries "directly in each DIR". A DIR argument that is a dangling link is returned as an entry, and the function still succeeds (fact-check i2 Claim 10). config_seeds handles this with its `[[ -d "$d" ]]` recheck at :1562. That guard sits at the call site, not inside top_files, so a second caller that trusts the header would treat the link as a file inside the directory. Today config_seeds is the only caller. This is a contract-precision gap, not a live bug.

**Recommendation:** Add the fact-check's precise wording: "...directly in each DIR (or the DIR itself, when it is a link whose target is gone: callers recheck -d)". Alternatively, move the `-d` recheck into top_files so the guarantee travels with the function.

#### 4. A NAME of `nl_a` collides with nul_list's nameref (pre-existing, inherited)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1584`, `:1637`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** a caller of top_files

**Evidence:**
```
top_files() { nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0; }
nul_list() { local -n nl_a="$1"; shift; ...
```
Probe: `nl_a=(); top_files nl_a "$d"` printed `local: warning: nl_a: circular name reference` 7 times, then `rc=0 n=1`.

top_files passes NAME to nul_list unchanged, so a caller array named `nl_a` produces bash circular-nameref warnings on stderr. On this bash the result still lands, because bash falls back to the local. `with_at` passes through nul_list the same way and doesn't document this either. The lib documents collisions only at `outside_seeds` (:1499-1500). top_files adds no local of its own, so it adds nothing new to the collision set. The only caller passes `fl`, which is safe. This matches the convention; it is listed for completeness, as the brief asked.

**Recommendation:** None required. If one is wanted, add "NAME must not be nl_a" to nul_list's own header, which would then cover top_files and with_at alike.

#### 5. top_files embeds nul_list, unlike the find-wrapper root_starts

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1584`
**Move:** 1 (baseline)
**Confidence:** Medium
**Legibility-target:** a maintainer adding the next find wrapper

Precedent: NAME-first helper embedding nul_list used in `scripts/lib/dev-cycle-read.sh:1361-1367` (`with_at`); stream-producing find wrapper wrapped by the caller used in `scripts/lib/dev-cycle-read.sh:1355,1596` (`root_starts`, `nul_list fl root_starts "$r"`)

**Evidence:**
```
root_starts() { local -; set -o pipefail; find -P "$1" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -print0 | instruction_names; }
...
top_files() { nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0; }
```

The lib has both shapes, and top_files follows the `with_at` shape, so this is consistent. The stream shape (`nul_list fl top_files ...`) would have read just as well at the three-try call site. No change suggested.

## What Looks Good

- **Signature shape:** `top_files NAME DIR...` follows the lib's NAME-first convention, and its header opens with the same `fn NAME ARG...:` line the neighbours use.
- **"gets" vs "appends":** the header says "gets", which is correct. nul_list's `mapfile` replaces the array and empties it on failure, matching `with_at`'s "gets". It does not use config_seeds' "appends".
- **Provenance tags:** `(config_seeds retries: Q-145)` follows the lib's `(... : tag)` style.
- **Nameref hygiene:** top_files declares no locals, so outside_seeds' rule that NAME must not be one of the three functions' locals is unaffected.
- **Stderr contract:** top_files leaves find's stderr alone and the caller decides what to drop. The last try's message survives, consistent with `checkout_md` and the other helpers that let failure output through.
- **Function-list pin:** `test/scripts/dev-cycle.bats:1115` adds `top_files` right after its caller `config_seeds`, matching the definition order.
- **Test title and fixture style:** the new test title and the `want walk ok|failed` assertions follow the file's established style. Looping over `tree main` walks matches the neighbouring tests (:688-722).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `T_ONCE` / `T_RMTOP` are shim-only but share imps' documented `T_` namespace | Minor | `test/scripts/build-loop-check.bats:733-770` | Medium |
| 2 | config_seeds' header implies three tries only for a vanished entry | Minor | `scripts/lib/dev-cycle-read.sh:1506-1509` | High |
| 3 | top_files' header omits the dangling-DIR depth-0 entry | Minor | `scripts/lib/dev-cycle-read.sh:1579-1584` | High |
| 4 | NAME `nl_a` collides with nul_list's nameref (inherited, undocumented as in with_at) | Informational | `scripts/lib/dev-cycle-read.sh:1584,1637` | High |
| 5 | top_files embeds nul_list (with_at shape) rather than the root_starts stream shape | Informational | `scripts/lib/dev-cycle-read.sh:1584` | Medium |

## Overall Assessment

The change is consistent with the lib's conventions. Name, argument order, the "gets" wording, the provenance-tag style and nameref hygiene all match the neighbouring NAME-array helpers, and the dev-cycle.bats pin keeps the exported-function list in step. There is nothing Breaking or Inconsistent: config_seeds' return contract (0 or 1) is unchanged for outside_seeds. The three Minor findings are all wording and could be fixed in place with a single comment-only commit. Two make the headers state exactly what the code does: retries apply to any failure, and a dangling DIR link comes back as an entry. The third is a naming nicety for the test knobs. None blocks a merge.

## Goal-Alignment Note

The PR's goal is to stop config_seeds' top-level ancestor listing from failing the walk when another process deletes an entry mid-listing, while still failing closed on every other error. The API surface serves that goal. The new `top_files` helper isolates the one find invocation that needs `-ignore_readdir_race` and retries, so the race handling sits at a single named call site and doesn't spread into the other three find listings in config_seeds. Those still fail on the first error, which is the intended narrowing (FP-173 "narrow-the-guard"). Findings 2 and 3 are where the documented contract is still looser than the behaviour. Both concern the fail-closed half of the goal: how often a persistent error is retried, and the dangling-link case the `-d` recheck covers. Tightening them would make that half legible to the next caller without reading the call site. The test knobs (Finding 1) serve the goal's verification, and their only cost is a namespace a reader could misread.
