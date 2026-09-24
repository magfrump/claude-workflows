Commit: d0fdd04

# Architecture Review: copy-install implementation (`712c626..d0fdd04`)

**Scope:** the diff `712c626..d0fdd04` on `ans/copy-install`: `devcontainer-config/install.sh` (read whole, 464 lines), `README.md`, `guides/bare-host-hook-wiring.md`, `guides/README.md`, decisions 035 and 037, `test/install-host.bats`, `test/link-claude-home-wiring.bats`. Working docs under `docs/working/` and the two plan-time reviews were read as context only.
**Date:** 2026-09-23
**Baseline:** `docs/reviews/architecture-review-copy-install.md` (plan-time, findings F1–F6). This review checks whether the code kept the boundaries that review asked for.
**Fact-check input:** `docs/reviews/code-fact-check-report.md`. I used its verdicts as given and did not re-verify behavior it documents.

Scope check: in scope under **cross-cutting concerns** (the installer is the bless pipeline for two trust domains), **public API** (install.sh's CLI contract: flags, prompts, exit status) and **data models** (a second producer of `.claude-workflows-manifest`).

Trust-boundary cross-reference: the most recent `docs/reviews/security-review-*.md` is `security-review-egress-zone-entries-2026-09-19.md` (Commit: `7c970bf`). Its map covers the egress boundaries (B1–B5) and none of the installer, so this cross-reference is a no-op. None of the findings below moves a trust-boundary crossing.

## Plan-time findings vs implementation

| Plan finding | Asked for | Implemented? |
|---|---|---|
| F1 per-target functions | shared helpers plus `install_devcontainer` and `install_claude_home`; a main sequence that folds the results | **Yes, mostly.** Both target functions exist and `:461-464` is the main sequence. The results are folded through a global `DECLINED`, and a target can still `exit` the whole run (finding 3). |
| F2 names derived from `CLAUDE_HOME_SRC` | one derivation that every loop iterates | **Yes.** Derived at `:248-250`. The guard, pre-pass, diff, copy, move and swap loops all iterate `CLAUDE_HOME_NAMES`. The tests don't pin the derivation (finding 5). |
| F3 wrap `review_diff`, don't fork it | a pre-pass that prints, then the same `review_diff`, with a changed flag returned | **Yes.** `:342-374`. The helper's error path still carries the devcontainer caller's wording (finding 1). |
| F4 CLI contract stated once, in `--help` | README and guide point to `--help` | **Partly.** `usage()` has the contract. The README and 037 restate it as well, and the copies have already drifted (finding 4). |
| F5 manifest additive | stage `.manifest` copied, with new keys appended | **Yes.** `:441-447`. One appended key has weaker semantics than its consumer assumes (finding 6). |
| F6 016 layers intact, 035 note | no change to `PAYLOAD` or the launcher; 035 Consequences note | **Yes** (finding 7, Informational). |

## Dependency Map

- **`install.sh` main sequence** (`:461-464`) → `install_devcontainer` → shared `assemble`, `review_diff`, `confirm` → writes `$DEST` and `$BIN_DIR`, then calls the installed `cc-isolated.sh --bless`.
- **`install.sh` main sequence** → `install_claude_home` → the same `assemble` (into a `mktemp` stage, not `$SRC/claude-home`), `review_diff` and `confirm`, plus the host-only helpers `resolve_phys`, `inside_repo` and `host_refuse` → writes `$dest` (`~/.claude`).
- **`CLAUDE_HOME_SRC`** (`:93`) is the single source for both targets' seven entries. `link-claude-home.sh` `ENTRIES` is still a separate hand-written list. That predates this diff and the diff leaves it untouched.
- **`.claude-workflows-manifest`** now has two producers: `link-claude-home.sh:71`, which copies verbatim, and `install.sh:441-447`, which copies and appends keys. There is no in-repo consumer (`rg` finds only the producers, the tests and docs).
- `cc-isolated.sh` and `link-claude-home.sh` are unchanged (`git diff --stat 712c626..d0fdd04` on both is empty). `PAYLOAD` (`:69`) is unchanged.

Dependencies still flow from the volatile parts (the installer, docs) toward the stable ones (the payload list, the manifest format). No cycle is introduced.

## Findings

#### 1. Shared helpers still speak for the devcontainer caller on their abort path

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:149-151` (`review_diff`), `:116-119` (`assemble`); host call sites `:335`, `:372`
**Move:** 3 (module boundary / shared-helper contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
    *) echo "ERROR: could not diff payload item '$item' (diff exit $rc)." >&2
       echo "       The review diff is incomplete, so nothing was installed." >&2
       exit 1 ;;
```
```
    echo "       The image payload would be incomplete. Fix the path, or edit" >&2
    echo "       CLAUDE_HOME_SRC in this script. Nothing was installed." >&2
    exit 1
```

F3 asked for one `review_diff` consumed the same way by both targets. Its success path does that (return 0/1). Its trouble path still `exit`s the script with wording written for the only caller it used to have. When the host target reaches it (the fact-check's E3 case, a dangling per-file link under `hooks/`), target 1 may already have installed and blessed. The message then says "nothing was installed", names neither the target nor the offending path, and contradicts `host_refuse`'s target-scoped wording (`:275`). The helper owns both the exit policy and the message, so a target can't give its own recovery advice. That is the gap E3 reports.

**Recommendation:** have `review_diff` return a distinct status (for example 2) on trouble, printing the item and the failing path. Each target maps that status to its own abort line: `host_refuse` for the host target, the existing text for the devcontainer target. `assemble`'s text matters less, because a missing source already stops target 1 earlier in the same run. It could use the same treatment for consistency.

#### 2. `install_claude_home` holds seven responsibilities, and the install transaction has no single owner

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:279-459` (the whole function); transaction `:392-437`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
  # 2. Move whatever is there now (link or real, never with a trailing slash)
  #    into a fresh backup dir.
...
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
  fi

  # 3. Swap the new copies in.
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
      echo "ERROR: $dest/$name reappeared during the install; the new copy is left at $dest/.cw-new.$name." >&2
      exit 1
    fi
    mv "$dest/.cw-new.$name" "$dest/$name"
  done
```

The target function now does all of these in one 180-line body: destination resolution, skip rules, path guards, staging, the review pre-pass, the prompt, a three-phase copy/move/swap, provenance and the wiring reminder. F1 asked for per-target functions and got them. Inside the host target, though, the install transaction (steps 1–3) is inline, and only step 1 has an undo. Steps 2 and 3 have no rollback owner, so a failure between them leaves `~/.claude` partly emptied, with no restore message. The fact-check escalates that as E2 (correctness, owned by the other critics) and E7 (concurrent runs). The structural point: a later fix to the transaction has to be threaded through the middle of a function that also owns prompts and review output. That is where it would be easiest to get wrong.

**Recommendation:** extract `host_swap <dest> <backup>` (steps 1–3) with one contract: either every entry is new, or every moved entry is put back from `$backup`, and on failure it prints the exact `mv` commands to recover. The review pre-pass (`:342-369`) can become `host_review` in the same pass. The target function then reads as the plan's sequence of guard → stage → review → confirm → swap → stamp.

#### 3. Exit status is folded through a global, and targets can still end the run

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:461-464`; `:196`, `:388` (`DECLINED=1`); `:276`, `:405`, `:421`, `:434` (in-target `exit 1`)
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
DECLINED=0
install_devcontainer
install_claude_home
exit "$DECLINED"
```
```
host_refuse() {
  echo "ERROR: $1" >&2
  echo "       Nothing was installed into the host target." >&2
  exit 1
}
```

F1 recommended that the main sequence "call the targets in order and fold their results into the exit status", so that a new target is one new function and one line. Here the targets report a decline by writing the global `DECLINED`, and they report errors by exiting the process. That works today only because the host target is last. Decision 037's own revisit trigger (`037:64`, "add it as a third target in the same run, not as a flag") would put a target after it, and a `host_refuse` would then silently skip that target. `DECLINED` is also referenced inside `install_devcontainer` (`:196`) before the global is initialized (`:461`), which is an ordering dependency on top-level code.

**Recommendation:** have each target return 0 (installed, skipped or unchanged), 1 (declined) or 3 (error), and have the main sequence fold those into the documented 0/1/2 exit status. If that is deferred, add a one-line comment at `:461` saying a target that can `exit` must run last.

#### 4. The CLI contract is restated in three places, which have already drifted

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:40-43` (`usage`); `README.md:21-24`; `docs/decisions/037-bare-host-copy-install.md:31-32`
**Move:** 3 (public surface)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
Target 2 is SKIPPED, with a message and no effect on the exit status, when
--yes is given, when stdin is not a terminal, or when running inside a
Claude Code session (CLAUDECODE set). It only installs for a human at a
terminal who read the diff.
```
(`install.sh:40-43`)
```
target only installs for a human at a terminal. It is skipped with `--yes`, from a
script with no TTY, and inside a Claude Code session. `install.sh --help` has the
```
(`README.md:22-23`)
```
  - It is skipped, with a message, when `--yes` is given or stdin is not a TTY.
```
(`037:32`)

F4 predicted this: if the contract lives in several places, the copies drift. They already have. 037's skip list omits CLAUDECODE (fact-check Claim 24). `--help` and the README both say the target "only installs for a human at a terminal". The script's own comment (`:290-292`) and 037's stress-test mitigation say `script` plus `env -u` defeats that, which is why fact-check Claim 2 rates it Incorrect and escalates it as E1. The README does point to `--help`, but it restates the rules first, so a reader gets two sources that can disagree.

**Recommendation:** make `usage()` the single statement, with the wording aligned to `:290-292` ("stops accidental runs; a deliberate pty wrapper gets through"). Cut the README paragraph down to "two targets, each with its own diff and y/N; see `install.sh --help`". Have 037 give the rationale and link to `--help` instead of listing the skip conditions.

#### 5. The name derivation is implemented but not pinned by a test

**Severity:** Informational
**Location:** `test/install-host.bats:175-199` (T6); `test/link-claude-home-wiring.bats:270`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-automated-gate

**Evidence:**
```
  for n in CLAUDE.md skills workflows guides patterns hooks scripts; do
    [ -e "$CLAUDE_HOME_DIR/$n" ]
    [ ! -L "$CLAUDE_HOME_DIR/$n" ]
  done
```
```
  grep -qE '^CLAUDE_HOME_SRC=\(.* scripts( |\))' "$REPO_ROOT/devcontainer-config/install.sh"
```

F2's recommendation came with the test that would pin it: "every staged top-level entry reaches the destination". T6 instead iterates its own hard-coded list of the seven names. If the loop at `install.sh:248-250` regressed to a hand-written list, T6 would still pass, and an eighth `CLAUDE_HOME_SRC` entry would not be checked. The FP-066 subset-install failure is then guarded by the code alone. The wiring test's grep pins only that `scripts` is present.

**Recommendation:** in T6, derive the expected names from the `CLAUDE_HOME_SRC=(...)` line of the copied `install.sh` (or from `ls` of an `assemble`d stage) instead of restating them. Separately, and not in this diff, `link-claude-home.sh` `ENTRIES` is a third copy of the list. A consistency test between it and `CLAUDE_HOME_SRC` basenames would close that one.

#### 6. The manifest is additive, but two appended keys are weaker than 037's revisit trigger assumes

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:410-417`, `:439-447`; `docs/decisions/037-bare-host-copy-install.md:64`
**Move:** 7 (data contract)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  rm -f "$dest/.claude-workflows-manifest"
  cp "$stage/.manifest" "$dest/.claude-workflows-manifest"
  {
    echo "installed_by=host-tty"
    echo "installed_parent=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ' || echo unknown)"
    echo "installed_at=$stamp"
  } >> "$dest/.claude-workflows-manifest"
```
```
    backup="$bkroot/$stamp"
    if [ -e "$backup" ]; then backup="$backup.$$"; fi
```

F5 is satisfied on format. `commit=`, `dirty=` and `assembled_from=` come verbatim from the same `assemble` that feeds `link-claude-home.sh`, and the new keys are appended, so a reader written for either producer parses both. Two semantics are weaker than they look, though:
- `installed_parent` is best-effort. It records `bash` or `sh` under a compound-command `script` wrapper (fact-check Claim 22 / E4). Yet 037's revisit trigger ("install is traced to an agent session") is the only planned consumer of this data.
- `installed_at` is the backup stamp, but on the collision path the backup directory is `<stamp>.<pid>`, so the two no longer match exactly.

Neither breaks anything today, because nothing reads the file. They matter as soon as the DD [9] staleness hook or the 037 trace is built.

**Recommendation:** mark `installed_parent` as advisory in 037 (or drop it, rather than keep a field that looks like an audit trace). Write the real backup path as its own key (`backup=`), so a trace does not have to reconstruct it from `installed_at`.

#### 7. The 016/022/023/035 boundaries were kept

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:69`, `:93`, `:333-335`; `docs/decisions/035-install-sh-gating.md` (Note, 2026-09-23)
**Move:** 4 (layer violations)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  HOST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/cw-host-stage.XXXXXX")"
  local stage="$HOST_TMP/payload"
  assemble "$stage"
```

- **016:** `PAYLOAD` is unchanged. `cc-isolated.sh` and `link-claude-home.sh` are untouched. The host target stages into `mktemp`, not `$SRC/claude-home`, so it never changes the devcontainer build context or its review. The launcher gains no dependency on `~/.claude`.
- **022/023:** the host target uses the same `assemble` and the same `CLAUDE_HOME_SRC`, so `scripts` and `hooks/lib` always travel with the hooks. The guide's §1 rewrite documents why.
- **035:** a Consequences note records the wider blast radius. Both install.sh commits (`6793b79`, `1514518`) carry `Live-verified: no — …` trailers naming the plan-step-9 host check.
- **037:** shape D is implemented as decided: two prompts, no target flags, Gemini recipes removed, `settings.json` never written, and the wiring change only announced (`:453-458`).

Placement in `devcontainer-config/` is still the misnomer F6 accepted. Nothing here changes that trade-off.

## What Looks Good

- **Real per-target functions over shared helpers.** `install_devcontainer` is the old linear flow moved nearly verbatim into a function. The host target doesn't thread a single branch through it, which was F1's main concern.
- **One derivation for the entry names** (`:248-250`), iterated by all six host loops. The host cannot install a subset.
- **The symlink-aware review wraps `review_diff` instead of forking it.** The pre-pass only prints and counts, then the same helper produces the content diff.
- **Skip rules run before any read or stage** (`:293-304`), so the devcontainer path's non-interactive behavior and the old tests stay hermetic.
- **Move-aside, not `rm -rf` + `cp -r`**, with guards against writing through a link into the checkout, placed before anything is staged.
- **`settings.json` stays out of the installer**, which leaves link-claude-home's jq as the only merger (FP-161).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Shared helpers' abort path speaks for the devcontainer caller | Minor | `install.sh:149-151`, `:116-119` | High |
| 2 | Host target function is monolithic; the swap transaction has no rollback owner | Minor | `install.sh:279-459`, `:392-437` | Medium |
| 3 | Exit status folded via a global; a target can `exit` the run | Minor | `install.sh:461-464`, `:276` | Medium |
| 4 | CLI contract restated in three places, already drifted | Minor | `install.sh:40-43`, `README.md:21-24`, `037:31-32` | High |
| 5 | Name derivation not pinned by a test | Informational | `test/install-host.bats:175-199` | High |
| 6 | Manifest additive, but `installed_parent` and `installed_at` are weaker than 037 assumes | Informational | `install.sh:410-417`, `:439-447` | Medium |
| 7 | 016/022/023/035 boundaries kept | Informational | `install.sh:69`, `:333-335` | High |

Rubric mapping: no Structural (🔴) and no Coupling (🟡) findings. All seven are 🟢 Consider.

## Overall Assessment

The implementation keeps the structure the plan-time review asked for. There are two target functions over shared helpers. The entry names are derived once from `CLAUDE_HOME_SRC`, and the host review wraps `review_diff` instead of copying it. The manifest is additive and compatible with `link-claude-home.sh`. The 016 layering and the 022/023 payload assembly are untouched, and 035's gating discipline (note plus `Live-verified:` trailers) was followed. No dependency points the wrong way.

What remains is internal to `install_claude_home`. The single most important structural concern is finding 2: the copy/move/swap transaction is inline in a 180-line function, and only its first phase has an undo. It is the seam where the fact-check's E2/E7 correctness escalations land, and it should get one owner before plan step 9 runs on the user's live `~/.claude`. Findings 1 and 3 are the smaller contract leaks F1 and F3 were meant to prevent. They are fixable in place with status codes instead of in-helper `exit`s. Finding 4 is doc consolidation, and fixing it also clears the fact-check's E1. None of these needs a restructure.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes. Implementation reviewed against plan-time F1–F6 and decisions 016/022/023/035/037.
- Out of scope: the correctness and severity of the partial-install residue (E2/E7), the TTY-bypass security posture (E1/E4) and macOS portability (E8). Those belong to the security and correctness critics and to the fact-check. They are cited here only for their structural seam.
- Escalate: nothing new. Finding 2 corroborates E2 structurally, and the orchestrator should weigh it with E2 before plan step 9.
