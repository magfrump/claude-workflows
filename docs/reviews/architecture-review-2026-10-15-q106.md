Commit: 05b13d11

# Architecture Review — feat/q106-host-settings-merge

**Scope:** branch diff `184396ea..05b13d11` (9 files; in scope: `devcontainer-config/install.sh`, `devcontainer-config/link-claude-home.sh`, `hooks/lib/wiring-merge.jq`, plus decision 037's amendment and the plan's option table as design records)
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report.md` (jq program identical to the old inline one apart from comments and indent; the doc errors it found are in the guide and the plan's coverage table, not in the structure)

Scope check: **module structure** yes (a new module, `hooks/lib/wiring-merge.jq`, extracted from `link-claude-home.sh`); **public APIs** yes (that file's `jq --arg dir --slurpfile w -f` calling convention is now a contract with two callers); **data models** no (the `settings.json` and `wiring.json` shapes are unchanged); **cross-cutting** yes (what the commit gate covers, and the host target's install transaction). Scoped out: the README, the guide's prose, and the tests, except where they bear on structure (Finding 5).

## Dependency Map

Before the branch:

- `link-claude-home.sh` (image-baked, manifest-hashed, in `live-verify-gate.sh`'s `enforcement` regex) → `$SRC/hooks/wiring.json` (data, from the payload) plus an **inline** jq program.
- `install.sh` host target → `${new}hooks/wiring.json`, read only to set `wiring_changed` for the REMINDER. It never wrote `settings.json`.

After the branch:

- `link-claude-home.sh` → `$SRC/hooks/lib/wiring-merge.jq` + `$SRC/hooks/wiring.json`. Both come from the same image payload (`/opt/claude-workflows`), so the script and the program cannot drift apart in version.
- `install.sh` host target → `${new}hooks/lib/wiring-merge.jq` + `${new}hooks/wiring.json`: the `.cw-new.*` copies, hashed by `payload_hash` (`install.sh:904`) before the review and checked again after the y. It does **not** read the live `$dest/hooks/lib` copy, so an older installed program never merges a newer wiring.
- `wiring-merge.jq` → nothing (it is a pure jq transform; the caller does every write).
- Direction: two installers (`devcontainer-config/`) depend on a program that lives beside the data it interprets (`hooks/`). Nothing in `hooks/` depends back on `devcontainer-config/`, so there is no cycle. The installers become generic runners, and the knowledge of the wiring schema (the `{{CLAUDE_DIR}}` token, the `$dir/hooks/` provenance predicate, the permission-mode shape) now sits in one module next to the schema's only instance.

Gate and trust coverage of the merge logic: before, it was gated (inline in `link-claude-home.sh`) and hashed. After, it is ungated and hashed, in the same class as every other `hooks/**` file, including `guard-trusted-writes.py`, whose deny rules this program wires.

## Findings

#### 1. `install_claude_home` takes on a second write path, run by a mode flag and outside the swap transaction

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:986-1025, 1056-1075, 1112-1136` (inside `install_claude_home`, `:774-1171`, now 397 lines)
**Move:** 2 (responsibility boundaries), 7 (control coupling)
**Confidence:** Medium
**Legibility-target:** for-author

The host target used to do one thing: review a set of copied entries, then swap them in as one transaction (`host_rollback`). It now also prepares a merge, renders it for review, keeps two hashes, takes a separate backup and renames a file. That work is interleaved with the original steps, not added as a unit, and is steered by a captured flag (`files_changed`) that switches off the swap loops and the manifest write. The settings write also sits after the transaction, so a failure there leaves the entries installed and `settings.json` old (the plan accepts this as #17). Each future change to either concern (a new settings refusal rule, a new entry name) has to be threaded through both halves of a 400-line function. The local variable count (`s_why`, `s_old_hash`, `s_new_hash`, `s_view`, `snew`, `files_changed`, `swap_names`) shows the coupling.

**Evidence:**
```
  local s_view="$HOST_TMP/settings.view" files_changed="$changed" rc=0
```
```
  #    A settings-only change (Q-106) swaps no entry: swap_names stays empty.
  local stamp backup="" any=0 moved=() swapped=() swap_names=()
  if [ "$files_changed" -eq 1 ]; then swap_names=("${CLAUDE_HOME_NAMES[@]}"); fi
```
```
  if [ "$files_changed" -eq 1 ]; then
    {
      echo "installed_parent=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ' || echo unknown)"
```

**Recommendation:** This is not blocking. When this function is next touched, extract `settings_merge_prepare <dest> <new>` (it would set `s_why`/hashes and print the review block), `settings_merge_check`, and `settings_merge_apply <backup>`. `install_claude_home` would then call them at its three seams, and the settings path could be tested apart from the entry swap.

#### 2. The merge program leaves the commit gate, and the question the plan and commit say was raised was never filed

**Severity:** Minor
**Location:** `hooks/live-verify-gate.sh:83`; `docs/working/plan-q106-host-settings-merge.md` family 16; commit `188f5c3c` body; `docs/working/questions.md` (no entry)
**Move:** 1 (dependency direction), 4 (layer: the gate's boundary set)
**Confidence:** High (grep of both worktree and main `questions.md` and `roadmap.md` for `wiring-merge` / `merge program`: no match)
**Legibility-target:** for-author

`link-claude-home.sh` is an enforcement file, but what it writes into `settings.json` is now decided by a file outside the gate's regex. An edit to the merge semantics committed before this branch needed a `Live-verified:` trailer; the same edit after it needs none. Structurally this is consistent with the repo's existing split: `wiring.json` (which already decided the content) and every hook are hashed but ungated, and the gate's job is live-probe debt, while this program is fully exercised by `link-claude-home-wiring.bats` and T93–T98. So I do not think the gate must cover it. But the plan says "left as a question" and the commit says "raised as a question", and no Q entry exists. The decision is therefore only in a working doc and a commit body, and the regex test's rationale ("claude-home/ is an install-time (gitignored) payload ... the gate has no business matching them", `test/hooks/live-verify-gate.bats:117-119`) is silently stretched over code that now runs in an enforcement file's place.

**Evidence:**
```
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'
```
```
| 16 | Commit-gate coverage | The merge program moves out of `link-claude-home.sh` (gated) into `hooks/lib/` (not in the gate regex) | Still hashed by the trust manifest (claude-home) and shown in both installs' reviews. Adding it to the gate regex is gate code; left as a question | not covered by the commit gate (question) |
```
```
the host runs reviewed, hashed bytes. It leaves the commit gate's regex
(still hashed by the trust manifest); not added there to keep gate code
untouched, and raised as a question.
```

**Recommendation:** File the Q entry the commit promises (`Needs: you: judgment`), with options: [1] accept it as `hooks/**`-class (hashed, reviewed, bats-tested; record it in decision 037's amendment and the gate header comment); [2] add `^hooks/lib/wiring-merge\.jq$` to `enforcement` (a gate change, with its own bats pin); [3] gate it under a separate trailer. Interim: [1]. Or, if the merge goes ahead first, change the commit and plan wording to name the entry ID once it exists.

#### 3. Decision 037's pruning reason "a shared lib is a new coupling" is re-entered but not reconciled

**Severity:** Informational
**Location:** `docs/decisions/037-bare-host-copy-install.md:46` (pruned `[3 B]`), `:98-109` (amendment)
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

Formally, the branch does the thing 037 pruned: one shared module run by two code paths under two trust regimes (the container's image bless versus the host's review and y). In substance it avoids the costs that pruning named. (a) The shared unit is a pure transform with no exec or write builtins, so every side effect stays in the two callers, and both callers are gated. (b) In each regime the shared file sits *inside* that regime's own trust object (manifest-hashed `claude-home/`; the hash-checked `.cw-new` copy). Neither caller sources it from the agent-writable checkout, which was 016 [4]'s real objection ("re-opens exactly the agent-writable surface"). (c) It is not a second host-executed installer, which was [3 B]'s first reason. The amendment's "One program" bullet does not say any of this. A future DD that greps *Pruned candidates* will find "a shared lib is a new coupling" standing unqualified next to an implementation that has one.

**Evidence:**
```
`[3 B separate host script]: a second host-executed installer outside 035's gate, and a shared lib is a new coupling [carried from 016 [4]: two code paths, two trust regimes].`
```
```
- **One program.** The jq moved verbatim from `link-claude-home.sh` to `hooks/lib/wiring-merge.jq`. The container runs it from the image payload; the host target runs the hash-checked `.cw-new.hooks` copy it is about to install.
```

**Recommendation:** Add one sentence to the amendment's "One program" bullet: the shared unit is a side-effect-free jq filter read from each regime's own hashed payload, so [3 B]'s coupling objection (a shared *executable* lib sourced from the checkout) does not apply. Optionally, mark the pruned entry "see amendment 2026-10-15".

#### 4. The calling convention and its failure contract are re-implemented in each caller, with different preconditions

**Severity:** Informational
**Location:** `devcontainer-config/link-claude-home.sh:99-116`; `devcontainer-config/install.sh:994-1008`; `hooks/lib/wiring-merge.jq:9-12`
**Move:** 3 (module boundary), 5 (interface shape)
**Confidence:** Medium
**Legibility-target:** for-author

The module's public surface is the jq invocation (`--arg dir`, `--slurpfile w`, settings on stdin or as an argument; the caller writes, and a non-zero exit or empty output means "leave the file alone"). Each caller copies that contract: the existence checks, the `2>/dev/null` and the `-s` emptiness test. Their input preconditions differ. `install.sh` requires exactly one JSON object and refuses symlinks. `link-claude-home.sh` accepts anything `jq -e .` accepts and lets the program fail on a non-object. This is defensible, because the trust models differ: the container auto-writes, the host reviews. But a third caller, or a new `--arg` in the program, has to change both scripts in step, and nothing pins that the two contracts agree. The documented Usage line in the jq header is the only shared statement of it.

Trust-boundary cross-reference: the most recent security review, `docs/reviews/security-review-2026-10-15-cc-verify-spike.md` (Commit: `12fcb61c`), has `B2` (merged-tree payload files including `claude-home` → stage). This program now rides that payload, but `B2` belongs to the verify spike, not to this change. That security review predates this diff, so the boundary may be stale. This finding recommends no change that moves a boundary.

**Evidence:**
```
    if jq --arg dir "$DEST" --slurpfile w "$WIRING" -f "$MERGE" \
         "$SETTINGS" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
```
```
  elif [ -e "$settings" ] && ! jq -se 'length == 1 and (.[0] | type == "object")' "$settings" >/dev/null 2>&1; then
```
```
          jq --arg dir "$dest" --slurpfile w "${new}hooks/wiring.json" \
             -f "${new}hooks/lib/wiring-merge.jq" "$s_view" > "$snew") 2>/dev/null \
       || [ ! -s "$snew" ]; then
```

**Recommendation:** No code change needed now. If a third caller appears, make the program reject a non-object input itself (`if type != "object" then error("not an object") else . end` at the top), so the precondition lives in the module and not in each caller.

#### 5. The guide's hand-merge recipe is a second, divergent merge semantics, though the program now ships to the host

**Severity:** Informational
**Location:** `guides/bare-host-hook-wiring.md:59-73`; `hooks/lib/wiring-merge.jq:1-3`
**Move:** 7 (coupling: duplicate implementations of one concern)
**Confidence:** Medium
**Legibility-target:** for-author

The jq header claims "The one copy of this program", but the guide still teaches a manual merge that *adds* groups beside existing ones. That is the deep-equality-free version of the FP-161 double-fire the program exists to prevent. Every host install now places `wiring-merge.jq` at `~/.claude/hooks/lib/`, so the fallback could run the same program. Instead it keeps a semantics that no code implements. The fallback's audience has also shrunk: the "jq missing" refusal case cannot use a jq recipe either.

**Evidence:**
```
# The one copy of this program. Two callers run it:
```
```
Merge the output into `~/.claude/settings.json` by hand:
- For each event key under `hooks`, add these matcher groups beside any you already
  have.
```

**Recommendation:** Replace the hand recipe with `jq --arg dir "$HOME/.claude" --slurpfile w ~/.claude/hooks/wiring.json -f ~/.claude/hooks/lib/wiring-merge.jq ~/.claude/settings.json > tmp`, followed by review, then `mv`. Or keep it, but say it is for symlink-era installs only.

#### 6. `hooks/lib/` now mixes runtime hook libraries with an install-time program

**Severity:** Informational
**Location:** `hooks/lib/` (`usage-common.sh`, `wiring-merge.jq`)
**Move:** 2 (responsibility boundaries)
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

Until now, `hooks/lib/` held code that hooks source at runtime (`usage-common.sh`, used by `log-usage*.sh`). `wiring-merge.jq` is consumed by installers at install or container-start time, and its installed host copy has no host-side consumer. The placement is still the best one on offer, because it puts the program beside `wiring.json` and inside the payload both trust regimes already hash. It sets a precedent, though: install-time logic travelling in the runtime payload. That precedent is worth stating in the file's header (it partly is) before it is followed by something with side effects.

**Evidence:**
```
#   - devcontainer-config/link-claude-home.sh, at every container start
#     (decision 023), from the image's root-owned payload;
#   - devcontainer-config/install.sh's host target (Q-106 [2]), from the
#     reviewed, hash-checked copy it is about to install, before the y.
```

**Recommendation:** None required. If more install-time programs appear, give them their own directory (for example `hooks/install/`) so `hooks/lib/` stays "sourced by hooks".

## What Looks Good

- **Option choice.** Of the plan's four options, the payload filter file is the least coupled. A `--settings-only` mode would have the host execute a container script, a second host-executed script and close to the pruned [3 B]. Running `link-claude-home.sh` unchanged relies on a side effect of its link loop. Copying the jq is the drift class FP-161 came from.
- **Dependency direction.** The installers depend on the payload, and the payload depends on nothing. The host runs the reviewed `.cw-new` copy, not the installed one, and the container runs the copy baked beside its own script. Neither caller can pair a program with a wiring of another version.
- **Cohesion.** The schema interpreter now lives with the schema. A change to `wiring.json`'s shape and the matching change to its merge now land in one directory and one review hunk, and the change is shown in *both* installs' reviews.
- **Settings inside the existing bless, not a new prompt.** The settings change rides the target's existing review, y, agent gate and backup root. It adds no fourth boundary, which keeps 037's one-boundary-per-target model.
- **A pure shared unit.** The shared module has no side effects, so the "two trust regimes" share only data-to-data logic.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `install_claude_home` takes on a second write path behind a mode flag, outside the transaction | Minor | `devcontainer-config/install.sh:986-1136` | Medium |
| 2 | Merge program leaves the commit gate; the promised question was not filed | Minor | `hooks/live-verify-gate.sh:83`; plan family 16 | High |
| 3 | 037's "shared lib is a new coupling" pruning re-entered without reconciliation | Informational | `docs/decisions/037-bare-host-copy-install.md:46, 102` | High |
| 4 | Calling convention and preconditions duplicated across two callers | Informational | `link-claude-home.sh:99-116`; `install.sh:994-1008` | Medium |
| 5 | Guide's hand-merge recipe is a divergent second semantics | Informational | `guides/bare-host-hook-wiring.md:59-73` | Medium |
| 6 | `hooks/lib/` mixes runtime libs and an install-time program | Informational | `hooks/lib/` | Low |

## Overall Assessment

The change keeps, and on balance improves, structural integrity. It removes what would otherwise be a second merge implementation, points both installers at one pure module that sits with its schema, and keeps the host write inside the existing review boundary. On the brief's main question: the payload-file approach does **not** reintroduce, in substance, the coupling 037 pruned. That pruning objected to a second host-executed installer and a shared *executable* lib under two trust regimes, with the agent-writable checkout in the path. Here the shared unit is side-effect free and is read from each regime's own hashed copy. The real structural cost is gate coverage (Finding 2). Logic that decides `settings.json` contents moved from a gated enforcement file into the ungated `hooks/**` class. That class is coherent with how the repo already treats `wiring.json` and the hooks, but it is a decision, and it currently lives only in a plan row and a commit body that say a question was raised when none was. Filing that Q entry (or folding the answer into 037's amendment, alongside Finding 3's sentence) is the single most important follow-up. Finding 1 is fixable in place whenever `install_claude_home` is next touched. No finding is Structural or Coupling, so nothing blocks the merge on architecture grounds.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report at /workspace/.claude/wt-q106/docs/reviews/architecture-review-2026-10-15-q106.md per the architecture-review skill, `Commit: <HEAD short sha>` first line.
- Answered: yes — considered 037/016 [4] re-entry, dependency direction, gate-coverage change and the plan's option table
- Out of scope: security of the hash/re-check windows, jq semantics (covered by the fact-check), and the guide/README wording errors the fact-check found
- Escalate: Finding 2: the Q entry promised in commit 188f5c3c ("raised as a question") does not exist in questions.md
- Decisions I made: rated gate coverage Minor rather than Coupling, because `wiring.json` and the hooks were already in the ungated-but-hashed class (alternative: Coupling, as a widened bypass of an enforcement file's behaviour)
