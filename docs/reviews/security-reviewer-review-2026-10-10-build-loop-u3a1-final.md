Commit: d10cfba8

# Security Review — feat/build-loop-u3a1, final confirming pass (full branch, main d5736445...d10cfba8)

**Scope:** `git diff main...HEAD` without docs/reviews: `scripts/build-loop.sh` (whole file read for context), `test/scripts/build-loop-check.bats`, plan step 7 notes
**Date:** 2026-10-10
**Based on:** the k=3 fact-check at d10cfba8 (`code-fact-check-report-build-loop-u3a1-final-r{1,2,3}.md`, 0 behavioral Incorrect); prior security reports i1 (F1 High, fixed) and i2 (F1 listing gaps, fixed; F2 race window, settled as override row 646).

**Method:** executed. I wrote five probes in throwaway repos under `scratchpad/u3a1-f/security/probes/` (`nl.sh`, `dot.sh`, `midx.sh`, `midx2.sh`, with logs). They ran against the worktree's `scripts/build-loop.sh` at d10cfba8 on git 2.39.5. Each probe follows the brief's probe-safety rule.

**Bottom line:** **No.** A same-uid writer acting before the run can still get an `ok` verdict that rests on bytes store_check never verified. The writer drops a forged second pack whose file name contains a newline (F1, executed, reproduced end to end). This is the i1 F1 attack under a new name. The i2 listing fixes do hold: a dot-named forged pack is refused (executed). The multi-pack-index pin is needed and it works, including for gate_git-shaped calls (executed; this settles the fact-check replicates' disagreement below).

---

## Trust Boundary Map

```
B1: .git/objects/pack dir entries (any name) → store_check listing (find -L | while read) → per-id copy count → "one copy" trusted
B2: .git/objects (packs via git's readdir + MRU) → store_check cat-file --batch + perl re-hash → $GATE_TMP/main, $GATE_TMP/call
B3: .git/objects (same store, other process) → brief_fields cat-file blob MAIN:PATH, own_blob, checkout_gate ls-tree → verdict fields
B4: .git/objects via GIT_OBJECT_DIRECTORY → gate_git (merge-tree, diff-tree, --batch-check) under harden's GIT_CONFIG_COUNT pairs → merge result
```

```
S1: pack dir file names        — runtime-mutable (same-uid writer) — UNTRUSTED toward the listing sink (line splitting)
S2: pack/.idx/.midx bytes      — runtime-mutable                   — UNTRUSTED toward verdict-integrity sinks
S3: harden's config pairs      — process env, set by this script   — trusted (caller env trusted by design)
```

The invariant everything rests on is that B1's list of copies equals the set git can reach in B2/B3. If the two agree, every read of a checked id returns the bytes B2 re-hashed. If they differ, B2 and B3 can pick different copies (pack MRU order differs per process), and that is the i1 F1 mechanism.

---

## Findings

#### F1. A pack file name holding a newline hides that pack's ids from the second-copy scan, so a forged second copy passes the gate

**Severity:** High
**Location:** `scripts/build-loop.sh` store_check, the pack listing (lines ~641-642)
**Boundary:** B1 → B2/B3
**Move:** #11 (bypass of the one-copy guardrail), #1
**Confidence:** High (executed, end to end)
**Legibility-target:** for-author + for-orchestrator-synthesis

Evidence (verbatim):
```
  { (cd "$o" && find -L pack -mindepth 1 -maxdepth 1 -name '*.idx' ! -type d) > "$GATE_TMP/idx" || exit 1
    while IFS= read -r r; do git show-index --object-format="$fmt" < "$o/$r" | awk '{ print $2 }' || exit 1; done < "$GATE_TMP/idx"
```
`find` prints each name followed by a newline, and `read -r` splits on newlines. A pack named `x<LF>y` (files `x<LF>y.idx`, `x<LF>y.pack`) therefore becomes two lines, `pack/x` and `y.idx`, which are read as `$o/pack/x` and `$o/y.idx`. The pack's real `.idx` is never read. If those two names do not exist, show-index fails and the check refuses (fail closed). A writer who places a valid but harmless idx at each name (`objects/pack/x`, `objects/y.idx`; git ignores both, since neither is a pack index in `pack/`) gets a clean scan. Git itself treats `x<LF>y.idx` as an ordinary pack: its readdir takes any name ending `.idx`.

Executed (`probes/nl.sh`, log `probes/nl.log`): i1's forged-pack recipe. A pack with a relabelled idx carries forged bytes under main's brief blob id G, with a newer mtime. That pack is installed as `x\ny.*` along with the two decoys:
```
== does git open the newline pack? count-objects -v
packs: 2
== cat-file blob main:B
Branch: feat/y
== gate verdict at HEAD
ok docs/working/briefs/2026-10-01-x.md 8ae68bbafc3b56e5c009c65815b2d61232bbed9e edba524726f19cea91ad8c51aa0c0618afc9d651
path docs/working/briefs/2026-10-01-x.md A work-feat-y.txt
== control: same pack under a plain name
refuse state objects: the default branch's commit or an object of its tree does not hash to its id, has a second copy in the object store, or could not be read
```
The brief on main says `Branch: feat/x`, and the baseline run in the same repo gave `ok ... A work-feat-x.txt`. With the newline pack in place, the gate approves the merge of **feat/y**, whose only evidence is the forged bytes. The control run proves the newline name is the only difference: the same pack under a plain name is refused. The actor and the effect are the same as i1 F1 (rated High): a verdict that rests on unverified bytes. Only the file name changes.

**Recommendation:** list NUL-separated: `find -L pack -mindepth 1 -maxdepth 1 -name '*.idx' ! -type d -print0 > "$GATE_TMP/idx"` and `while IFS= read -r -d '' r`. As a second layer, consider refusing (in store_check or state_gate) any `objects/pack/` entry not of the form `pack-<hex>.<ext>`. That turns the whole class of naming differences between git's readdir and the scan (dot names, control bytes, whatever is found next) into a refusal. Add a bats case that uses a newline-named forged pack with decoys.

Note on the loose-file half of the scan: the same newline splitting can only **add** lines there (awk prints a fragment for each part), so it can cause a false refusal but cannot hide a copy. Git also reads a packed copy before a loose one (`oid_object_info` tries packs first), so for a packed id a loose duplicate is never what git reads. No finding there.

#### F2. (Informational, routed) The multi-pack-index rationale is correct: a midx is a second route that the .idx listing does not show

**Severity:** Informational (confirms a comment the fact-check replicates disputed)
**Location:** harden's comment ("no multi-pack-index (a second route to an object, past store_check's listing)") and pair `core.multiPackIndex=false`; store_check comment
**Boundary:** B2/B4
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

Two fact-check replicates could not reproduce the rationale because they tested a midx-named pack whose `.idx` is gone, and that object is unreadable either way. The real second route is different: the midx's own OOFF table maps an id to a (pack, offset) without consulting the pack's `.idx`. `probes/midx.sh` swaps the midx entries of G and F (same pack, same size). Each `.idx` still lists G once:
```
== each pack .idx lists G once:
1
== cat-file blob G, core.multiPackIndex=true:
FORGED!
== cat-file blob G, core.multiPackIndex=false:
genuine
```
`probes/midx2.sh` ran end to end on the brief blob. With the pin, the gate reads the genuine brief (`ok ... A work-feat-x.txt`), while an unpinned `git cat-file` in the same repo reads `Branch: feat/y`. A gate_git-shaped call (`GIT_DIR` elsewhere, `GIT_OBJECT_DIRECTORY` real) reads forged bytes without the pair and genuine bytes with only `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.multiPackIndex GIT_CONFIG_VALUE_0=false`. So the pin reaches gate_git, whose `env -u` list keeps GIT_CONFIG_COUNT (callervar), and the KEY/VALUE variables are not local-env-vars. No change needed. The fact-check's "Unverified" on this rationale can be closed as **Accurate**.

---

## Verified closed (executed or traced at d10cfba8)

- **Dot-named forged pack** (i2 F1.1): `probes/dot.sh` reads forged bytes through `git cat-file`, and the gate refuses with `refuse state objects: ...` (executed). `find -name '*.idx'` matches a leading dot.
- **Symlinked fan-out dir / pack entry** (i2 F1.2): `find -L` descends through links, and a link loop or unreadable target makes find exit non-zero. That ends the brace group's pipeline under pipefail, so it fails closed (traced). store_check runs in `&&`/`if !` contexts where errexit is off, but each step carries an explicit `|| exit 1`/`|| return 1`, and the last pipeline's status is the return (traced).
- **Objects merge-tree "writes" that a writer pre-planted with forged bytes:** git freshens an existing id instead of rewriting it, so diff-tree would read the planted bytes. store_check's per-brief re-hash of `$tree` catches this (traced). This is the reason the result tree is re-hashed.
- **REF_DELTA base with two copies:** git 2.39 resolves a packed REF_DELTA base within the same pack (`find_pack_entry_one(base, p)`), so the result does not depend on MRU order (traced, as i2).
- **Reads before the tip's store_check** (marker_kind's `cat-file commit`, check_branch, check_brief's `git log -G`): each can only produce a skip or refuse line, never `ok`. The only `ok` paths print after `store_check "$sha" "$tree"` succeeds (traced in check_line). This agrees with the fact-check's note on the "Not checked" list, which is a documentation gap and not a security one.
- **Per-call judgement:** `$GATE_TMP/call` is overwritten per brief, and the scan judges `main` + `call`, so no refusal carries across briefs (traced).
- **Settled, not re-filed:** row 638 (history objects), row 646 (post-startup rewrite of main's objects / race). The code under them is unchanged since they were rowed.

## Untested bypass candidates (move #11)

- A FIFO named `*.idx` in `pack/`: show-index would block, and so would git's lookup. That is a hang (DoS), not an integrity failure, and a same-uid writer can kill the process anyway. Not executed.
- Case-insensitive filesystems (`objects/AB/...`): the loose scan's lowercase pattern would miss the file, but packed-first lookup and single-path loose names make it unreachable as a divergent copy. Traced only; /workspace is case-sensitive.
- An `.idx` whose `.pack` is missing, or a pack git skips for a version mismatch: the scan over-counts or show-index fails, which can only refuse. Traced.

## Endorsement Claims

- **Claim:** `core.multiPackIndex=false` in harden reaches every git call, gate_git included, and closes the midx route past the .idx listing.
  **Location:** `scripts/build-loop.sh` harden (`for kv in ... core.multiPackIndex=false`), gate_repo/callervar
  **Evidence:** executed (`probes/midx.sh`, `probes/midx2.sh`)
  **Verified:** midx OOFF swap read forged when unpinned and genuine when pinned, both in the real repo and in a gate_git-shaped env; the gate's verdict used genuine bytes.
  **Not verified:** a caller's own `git -c core.multiPackIndex=true` (GIT_CONFIG_PARAMETERS), which is trusted by design.
  **route: code-fact-check**

- **Claim:** a dot-named forged pack holding a second copy of main's object is refused at startup.
  **Location:** store_check listing
  **Evidence:** executed (`probes/dot.sh`)
  **Verified:** `refuse state objects: ...`, exit 2.
  **Not verified:** a dot-named pack whose name also holds a newline. F1 applies to it.
  **route: code-fact-check**

(The one-copy guardrail as a whole is **not** endorsed: F1.)

## Primitive sweep

Primitive: object-store enumeration/read used for an integrity decision
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| store_check pack listing `find -L ... > idx; while read` | S1 | none against newline | **F1** |
| store_check `show-index < "$o/$r"` | S2 | fail closed on read error | cleared (given a correct listing) |
| store_check loose `find -L . ... \| awk -F/` | S1 | lines only added | cleared (false refusal at worst) |
| store_check `cat-file --batch` + perl | S2 | re-hash | cleared |
| brief_fields / own_blob / checkout_gate `ls-tree` on MAIN | S2 | startup check + one-copy | F1 (divergent copy) |
| gate_git merge-tree / diff-tree / `--batch-check` | S2 | harden pairs (midx off verified) | F1 for the copy choice; per-brief re-hash of `$tree` |
| marker_kind, check_branch, merge bases, check_brief log -G | S2 | none | settled row 638 / non-ok outcomes only |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Newline in a pack file name hides its .idx from the one-copy scan; forged second copy yields `ok` | High | B1→B2/B3 | store_check pack listing | High (executed) |
| F2 | midx pin rationale confirmed (fact-check dispute resolved) | Informational | B2/B4 | harden comment | High (executed) |

## Overall Assessment

Except for F1, the design holds at d10cfba8. The startup and per-brief re-hash catches every single-copy rewrite I could construct. The dot-name and symlink gaps from i2 are closed. The midx pin is necessary and works across both repositories. F1 is a parsing bug in the copy listing, not a design gap: a newline-separated list of attacker-named files. It reopens i1 F1's exact effect, a gate `ok` for a branch the committed brief does not name, and that is reproduced. The fix is a few characters (`-print0` / `read -d ''`) plus one test. A name-form refusal for `objects/pack/` would also close future naming divergences. I would not land U3a1 with F1 open, because the branch's purpose is to close rows 492/503 against exactly this writer.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes — executed probes; one High bypass (F1) reproduced, i2 fixes confirmed closed, midx rationale confirmed.
- Out of scope: settled rows 638 and 646 (code unchanged under them); DoS-only candidates.
- Escalate: F1 blocks the merge as a High; the fact-check's "Unverified" midx rationale can be flipped to Accurate on the strength of probes/midx.sh.
- Decisions I made: rated F1 High to match i1 F1 (same effect) rather than Medium for needing decoy files; treated the decoys as trivially within the same-uid writer's reach.
