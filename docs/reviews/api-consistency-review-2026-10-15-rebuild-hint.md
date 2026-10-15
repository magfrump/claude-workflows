Commit: cb56299c

# API Consistency Review — fix/rebuild-hint-recreate (iteration 1)

**Scope:** `git diff 9660d4f6..cb56299c` (cc-isolated.sh, init-firewall.sh, guides/cc-isolated-usage.md, two bats files), plus the user-facing text around it in both scripts and both guides
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-rebuild-hint.md (k=1)

The public surface here is the CLI guidance a user reads and copies: the `rebuild_hint` first line, the probe-failure lead-ins, the fail-closed `ERROR:` block, init-firewall.sh's fail-closed hint, `cc-isolated --help`, the `--bless` "Next:" line, and the two guides that write out the same recipe.

## Baseline Conventions

- **Recovery recipe (the guides set the baseline).** `guides/cc-isolated-usage.md:957` and `guides/devcontainer-setup.md:399-400` both say: "`cc-isolated --probe-only <repo>` (recreates/always recreates it from the blessed config and re-probes), then `cc-isolated <repo>`". init-firewall.sh:349-350 prints the same two steps on two lines. Order: probe-only first, then launch. Placeholder: `<repo>`.
- **Vocabulary.** The guides use "recreate" for the container (`devcontainer up --remove-existing-container`) and keep "rebuild" for the *image* (central-image rebuild, the cached-layer note at devcontainer-setup.md:388, `--register`'s "next launch rebuilds that project's image" at :85). The fact-check report confirms the distinction matters: `--probe-only` always recreates, a plain launch recreates only on a hash mismatch.
- **Lead-in shape.** Error blocks end with an imperative sentence and a colon, followed by the indented hint (`Recreate it (the ~/.claude volume and your repo are not affected):` at cc-isolated.sh:918, existing before this diff).

## Name-Pattern Audit

This diff adds no new public names: no flags, functions, env vars, or exit codes. The only identifiers it adds are a test stub variable (`STUB_FW_BRICKED`) and a test name, both private to the bats suite. What it does change is the wording of user-facing strings, so the audit below covers each changed or added *phrase* against the phrases closest to it.

| New phrase | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `cc-isolated --probe-only WS && cc-isolated WS` | CLI recipe | "`cc-isolated --probe-only <repo>` …, then `cc-isolated <repo>`" (×2); two-line form | `guides/cc-isolated-usage.md:957`, `guides/devcontainer-setup.md:399-400`, `devcontainer-config/init-firewall.sh:349-350` | Consistent: same command, same order. The `&&` is a stricter way to write "then" |
| `# the supported path: recreates from the blessed config, re-probes, then launches` | hint comment | "recreates the container from the blessed config and re-probes"; "# recreates it from the blessed config, re-probes" | `guides/cc-isolated-usage.md:957`, `init-firewall.sh:349` | Consistent |
| `Recreate it with:` (×2 lead-ins) | lead-in | `Recreate it (the ~/.claude volume and your repo are not affected):` | `devcontainer-config/cc-isolated.sh:918` | Consistent |
| `RECREATE REPO's container …` | usage table (guide) | `--probe-only` header line `(re)build WS from the blessed config` | `devcontainer-config/cc-isolated.sh:13` | Inconsistent: the guide now says RECREATE but `--help` still says "(re)build" (Finding 2) |
| `# recreates it from the blessed config, re-probes` | init-firewall hint | `# rebuilds from it and probes as node` (`--bless` Next: line) | `devcontainer-config/cc-isolated.sh:316` | Inconsistent: the same `--probe-only` command carries "rebuilds" in the `--bless` output (Finding 3) |
| `which recreates it with both set` | guide row | plain-launch hash-mismatch recreate | `cc-isolated.sh:897-899` | Consistent: in this row's state `/etc/cc-config-hash` is empty, so the hashes mismatch and a plain launch does recreate |

## Findings

#### 1. The unverified-config NOTE and the `--help` header still say a plain launch rebuilds, which the hint now correctly says it may not

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-isolated.sh:877-878`, `devcontainer-config/cc-isolated.sh:60-62` (printed by `--help`), `guides/cc-isolated-usage.md:955`
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** the user of a plain `cc-isolated <repo>` launch on a container whose first verification failed closed

Evidence (cc-isolated.sh:877-878, printed at launch whenever the receipt is missing):
> `echo "      This run is that verification: the container is rebuilt from it, and the"`

Evidence (header, printed by `cc-isolated --help`):
> `# unverified config says so, rebuilds the container so the probe exercises the new`

Evidence (guide :955):
> `The launch rebuilds and verifies; if it fails, read the \`PROBE FAIL\` line.`

The rebuild_hint comment this diff adds says the opposite: "a plain launch recreates only when the baked config hash differs, so a fail-closed container built from the blessed config would be reused, not recovered". The fact-check report rates the NOTE Incorrect (high). In the fail-closed state there is no receipt and the hash matches, so the NOTE runs and the container is reused. Here is what the user sees on a relaunch after a failed first verification: first the NOTE ("the container is rebuilt"), then the new hint ("recreate it with --probe-only"). The two messages disagree within the same run. The `--help` sentence and guide row :955 make the same claim. This is the same misleading claim the unit was opened to fix (A4), sitting a few lines from the code it changed. The unit should absorb it.

**Recommendation:** Reword all three so they state the condition. For example, the NOTE could say "a container built from an earlier config is recreated from it; the self-probe must pass …". The `--help` sentence could say "recreates a container built from an older config". Guide :955 could say "A launch recreates the container if it predates the bless, then verifies; if a failed verification left the container closed, run `cc-isolated --probe-only <repo>` first". One sentence each, in the files the unit already touches.

#### 2. `cc-isolated --help` still says `(re)build` for `--probe-only`, while the guide's copy of that table now says RECREATE

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-isolated.sh:13`
**Move:** 2 (naming against the grain) / 7 (asymmetry between `--help` and the guide's copy of it)
**Confidence:** High
**Legibility-target:** a user reading `cc-isolated --help` next to guides/cc-isolated-usage.md

Precedent: "recreate" for `--probe-only` used in `guides/cc-isolated-usage.md:25`, `guides/devcontainer-setup.md:309,400`, `devcontainer-config/init-firewall.sh:349`, `devcontainer-config/cc-isolated.sh:885`

Evidence:
> `#   cc-isolated --probe-only [WS]        # (re)build WS from the blessed config, run the`

guides/cc-isolated-usage.md:20-28 is the guide's copy of this usage block, and the diff changed it to "RECREATE REPO's container". The source block it mirrors, which `usage()` prints for `--help`, was not changed. The guide and the binary now describe the same flag in different words, and C5 exists to remove exactly that kind of drift.

**Recommendation:** Change line 13 to `# recreate WS's container from the blessed config, run the`. The usage bats test only pins the EXIT STATUS block, so the change won't break it.

#### 3. The `--bless` "Next:" line still says `--probe-only` "rebuilds"

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:316`
**Move:** 2
**Confidence:** High
**Legibility-target:** a user who has just run `--bless` / `install.sh` and is following its Next: line

Precedent: `# recreates it from the blessed config, re-probes` used in `devcontainer-config/init-firewall.sh:349`; "always recreates the container" in `guides/devcontainer-setup.md:309`

Evidence:
> `echo "  Next: cc-isolated --probe-only <repo>   # rebuilds from it and probes as node"`

This is the third copy of the same command-plus-comment that the user can see, and it is now the only one that says "rebuilds". It sits in the same file and comes from the same edit pass as the init-firewall comment the diff changed. Here "rebuilds" happens to be true, because after a bless the image layer does change, but the other two copies describe the *container* action, so this one should match them.

**Recommendation:** `# recreates its container from it and probes as node`.

#### 4. Guide :841 says `--probe-only` "always rebuilds first"

**Severity:** Minor
**Location:** `guides/cc-isolated-usage.md:841-842`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a guide reader at "Blessed is not verified"

Precedent: "always recreates" used in `guides/devcontainer-setup.md:309,400`, `guides/cc-isolated-usage.md:25` (as changed in this diff)

Evidence:
> `both. Run the verification explicitly after any boundary change — it always rebuilds`

The fact-check report rates this Mostly accurate, because "rebuilds" here means recreates. The diff edits this same file twice, at :25 and :963, and skips this line, which leaves the file contradicting itself on the term it is standardizing.

**Recommendation:** "it always recreates the container first".

#### 5. The init-firewall hint is two separate commands with no `&&`; the launcher hint chains them

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:349-350`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** a user copying the recovery recipe from inside the container

Evidence:
> `echo "         cc-isolated --probe-only <repo>    # recreates it from the blessed config, re-probes" >&2`
> `echo "         cc-isolated <repo>                 # then start the session" >&2`

Both forms give the same order and the same commands, and the guides use prose ("then"). Copying the init-firewall lines one at a time without checking the first one's exit status is still safe, because the plain launch re-probes and refuses to start a session. So the only cost is the difference in shape. init-firewall's `<repo>` placeholder is correct, since the container cannot know the host path. No change needed. Note it only if a later pass consolidates the recipe text.

#### 6. The provenance/config-identity hint is printed during a `--probe-only` run and tells the user to run `--probe-only` again

**Severity:** Informational (pre-existing, out of scope)
**Location:** `devcontainer-config/cc-isolated.sh:667-671`, `:681-685` (calls `rebuild_hint` at `:564`)
**Move:** 4 (error-message consistency)
**Confidence:** Medium
**Legibility-target:** a user whose `--probe-only` just failed on image provenance or config identity

Evidence:
> `echo "  not the one you blessed. Recreate it with:" >&2`

Under `--probe-only` the container has just been recreated (`:887`), so if it still fails these checks, the cause is the build or the config rather than a stale container, and following the hint repeats the same run. The fact-check report rates this Mostly accurate and pre-existing: the old hint named a plain relaunch, which repeated it in the same way. This is outside the unit's A4/C4/C5 scope, so leave it to a follow-up and record it in the override log rather than absorbing it.

#### 7. "rebuild" remains where an image rebuild is actually meant, and in internal names

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:478,898,534-557` (`rebuild_hint`), `guides/cc-isolated-usage.md:956`, `guides/devcontainer-setup.md:85,114`, `test/cc-isolated-functions.bats` test `"--probe-only always rebuilds before probing"`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** maintainers deciding how far to take the recreate/rebuild sweep

Evidence (cc-isolated.sh:898, quoted in guide :956):
> `echo "Blessed config changed since this container was built — rebuilding it."`

These are correct as they stand or are private names. A hash change alters a baked build arg, so the image is in fact rebuilt. `rebuild_hint` is a function name that `devcontainer-setup.md:406` and `init-firewall.sh:345` refer to by name, so renaming it would ripple through both for no user benefit. The bats test name is the one cheap cleanup ("always recreates before probing"), but it is not user-facing. Leave the rest as is.

## What Looks Good

- The new hint line matches the guides' recipe exactly: same command, same order, same "from the blessed config, re-probes" phrasing. The `&&` makes the failed-probe gate explicit, and the comment explains why (`--probe-only` exits non-zero on a failed probe; the fact-check report verifies this).
- All three lead-ins (provenance, config identity, fail-closed) now use the same imperative, "Recreate it", matching the existing fail-closed block.
- The `--probe-only` comment at :885 and init-firewall's comment and hint now use the guides' word.
- The guide row at :963 now says "recreates it", which is accurate for that state (empty hash, so a mismatch, so a recreate).
- Each wording change is pinned by a test, and the tests fail on the old text (`!= *"rebuilds"*`). The new fail-closed regression test also checks the premise: no `--remove-existing-container`, and no `claude` call.
- No flag, exit code, or by-hand assignment block changed, so scripts that call the launcher are unaffected. This change is wording only, as the fact-check report confirms.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | NOTE / `--help` / guide :955 claim a plain launch rebuilds; contradicts the new hint in the fail-closed state | Inconsistent | `cc-isolated.sh:877-878`, `:60-62`; `cc-isolated-usage.md:955` | High |
| 2 | `--help` says `(re)build` for `--probe-only`; guide copy says RECREATE | Inconsistent | `cc-isolated.sh:13` | High |
| 3 | `--bless` Next: line says `--probe-only` "rebuilds" | Minor | `cc-isolated.sh:316` | High |
| 4 | Guide says `--probe-only` "always rebuilds first" | Minor | `cc-isolated-usage.md:841` | High |
| 5 | init-firewall two-line recipe vs `&&` chain | Informational | `init-firewall.sh:349-350` | Medium |
| 6 | Hint during `--probe-only` repeats the run (pre-existing; defer) | Informational | `cc-isolated.sh:667-685` | Medium |
| 7 | Remaining image-"rebuild" wording and `rebuild_hint` name are correct or internal | Informational | various | Medium |

## Overall Assessment

The changed strings are consistent with each other and with the guides' recipe: same command, same step order, and "recreate" for the container action. The unit stops short of covering everything a user sees on this topic, though. Two Inconsistent findings remain within the unit's own scope. The `--help` text still says "(re)build" while the guide's copy of it says RECREATE, and the NOTE, the `--help` header paragraph and guide :955 still claim a plain launch rebuilds, which is the A4 claim this diff exists to fix. In the fail-closed state the user sees that NOTE and then the new hint in the same run. Findings 1–4 should be absorbed: each is a one-line wording edit in a file the unit already touches, and none changes behaviour. Finding 6 is pre-existing and belongs in the override log as a Defer. Findings 5 and 7 need no action. Nothing is Breaking.

## Goal-Alignment Note

The goal is for the hint to stop sending a user whose firewall failed closed back into a launch that cannot recover them. The diff meets that goal for the hint itself and its lead-ins. Finding 1 is the remaining gap. The same run still prints a NOTE saying the container "is rebuilt", and `--help` and guide :955 say the same thing, so a user who trusts those texts over the hint still forms the wrong expectation. Absorbing Findings 1–4 finishes the vocabulary sweep (C4/C5) across all the user-facing copies. Finding 6 and the cached-CC-layer refresh (security i2 #2) remain out of scope.
