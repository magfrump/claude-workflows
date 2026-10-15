Commit: 1a3d432a

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u5`, branch `feat/build-loop-u5`)
**Scope:** `git diff b5eaedf6..1a3d432a` (commits 8cff4877, 1a3d432a): `docs/dev-cycle.md`, `skills/dev-cycle/SKILL.md`, `docs/roadmap.md`, `docs/working/questions.md`, the rubric's iteration-3 section, the two new override-log rows, and both commit messages. The review reports added in 1a3d432a are artifacts and were checked only as the rubric's sources.
**Checked:** 2026-10-14
**Total claims checked:** 21
**Summary:** 17 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable
**Commit:** 1a3d432a
**Replication:** k=1 (narrow check after the final pass)

Hallucination log read (`docs/reviews/hallucination-patterns.md`). None of its five patterns (measured values quoted from artifact sets that lack them, a file-to-symbol association) matches a claim here. The commit-hash and row-number claims were each checked against `git log` or the file's lines.

Executed runs (all from the scratch directory `/home/node/.claude/jobs/00bcf178/tmp/u5/fc-narrow/`, each under `timeout`, with `GIT_CONFIG_GLOBAL=/dev/null`; logs under `logs/`):

- E1 `--settings` on `docs/dev-cycle.md` as committed at 1a3d432a, in a throwaway repo whose main holds only that file. 2026-10-15T05:37:31Z, exit 0. Log: `logs/settings-1.out`.
- E2 `variants.sh`: ten crafted settings files (bold, listed, numbered and fenced copies; text after the never, reader and policy lines; a fence after the never line; the never line at EOF). 2026-10-15T05:37:43Z, exit 0. Log: `logs/variants.out`.
- E3 `paste-test.sh`: Q-156's paste, taken verbatim from 1a3d432a with only the checkout path changed, run in fresh throwaway clones whose `main` is 1a3d432a and whose working-tree `install.sh` is a stub. Nine cases. 2026-10-15T05:38:27Z, script exit 0. Log: `logs/paste.out`.
- E4 `wtcfg-test.sh`: whether a `core.attributesFile` in `config.worktree` shapes `git archive` under repo_git's flags and is seen by `git config --local --get`. 2026-10-15T05:38:45Z, exit 0. Log: `logs/wtcfg.out`.
- E5 `replace-test.sh`: whether `git archive <commit>` honors a replace ref. 2026-10-15T05:39:04Z. The script's exit 2 comes from its graft half, which tar broke by reading git's deprecation hints from the merged stream. That half was not needed and was not used. Log: `logs/replace.out`.

---

## Claim 1: "Each key may appear on one line only, outside code blocks (a copy is found by its letters alone, so a bold or listed copy counts too); the never and reader lines need a blank line or the file's end after them; a trailing CR is ignored."

**Location:** `docs/dev-cycle.md:16-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SETTINGS_AWK's copy count and next-line flag, and how read_settings and reader_settings use them, for the five keys. It does not establish anything about markup that adds letters (a checked task box, a tag), which can still hide a copy. The header calls that best effort and the sentence does not claim otherwise.

The copy count drops everything but letters and folds case. Fenced lines are skipped before the count:

```awk
# scripts/lib/dev-cycle-read.sh:619-628
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  ...
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } else if (c[k] == 2) l2[k] = NR }
}
```

(excerpt ends :628; the awk program continues to its END block at :633, which was read)

Only the never line and the reader lines act on the next-line flag: `elif [[ "${next[$k]}" != 1 ]]; then why="line ${first[$k]} is followed by a non-blank line outside a fence` (`scripts/lib/dev-cycle-read.sh:677`) and `if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]` (`scripts/build-loop.sh:809`). The policy and slots branches never read `next`, as the full read_settings at `scripts/build-loop.sh:785-840` shows.

E2 confirms each part:
- A `**Build-loop policy:**` copy gives `more than one line starts "Build-loop policy:" (lines 1 and 3)`.
- `- Self-merge never:` and `1. Build-loop slots:` copies each count as a second copy.
- A copy inside a fence is ignored (`slots 4 set`).
- Text after the never line gives `never malformed: ... followed by a non-blank line outside a fence`, and text after a reader line gives `readers malformed`.
- Text after the policy and slots lines is accepted.
- A never line at EOF is accepted.

E1 parses the committed file cleanly: `slots 3 set: line 9`, `never workflows/ ... global-instructions/ set: line 11`, `readers 2-roots 2-homes set`, and `policy review unset` (the interim suffix, as intended). The new prose line itself does not register as a copy.

**Evidence:** `scripts/lib/dev-cycle-read.sh:613-633`, `scripts/lib/dev-cycle-read.sh:655-704`, `scripts/build-loop.sh:785-840`, `logs/settings-1.out`, `logs/variants.out`

---

## Claim 2: "Under both policies the N rules refuse a change to ... or any brief beyond the brief's own Status line, and any symlink, gitlink or `.git*` path"

**Location:** `docs/dev-cycle.md:30-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nrules' pathform and mode tests, which run for every brief regardless of policy. It does not establish pathform's other refusals (characters outside NAMECHARS, a leading `-` or `/`), which the sentence does not list. The sentence's follow-on about stopped and merge-entry outcomes was reviewed before b5eaedf6 and was not re-checked.

```bash
# scripts/build-loop.sh:1144-1145
if ! pathform "$6"; then DENY="not an allowed path form (letters, digits and . _ - / only; no leading - or /; no empty, . or .. part; no part starting .git)"
elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="a symlink, gitlink or other non-file entry on one side (only modes 100644 and 100755 land)"
```

(excerpt ends :1145; nrules continues to :1164, which was read)

The header says the same: "The N rules, under either policy: a path pathform refuses (a part starting .git, any case: .github/); a mode other than 100644 or 100755 on either side (a symlink or gitlink)" (`scripts/build-loop.sh:356-358`).

**Evidence:** `scripts/build-loop.sh:1141-1164`, `scripts/build-loop.sh:356-366`

---

## Claim 3: "Step 10 dispatches into the slots less the loops this session runs ... a blocked, stopped, capped or ready-for-review one, or a stalled one held, waits on you and is not counted."

**Location:** `docs/dev-cycle.md:39-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the wording against SKILL.md steps 8 and 10. It does not establish step 8's rule that a skipped brief keeps its slot (`skills/dev-cycle/SKILL.md:668-669`), which the bullet does not mention. Step 8 says "ready" where the doc says "ready-for-review". Under self-merge a ready brief is merged at once rather than waiting, so the doc's narrower word is the accurate one.

Step 10: "Fill free slots (`--settings`' `slots` less the loops this session runs)" (`skills/dev-cycle/SKILL.md:772-773`). Step 8: "each counted once (a blocked, stopped, capped or ready one, or a stalled one held, waits on the user and is not counted)" (`skills/dev-cycle/SKILL.md:652-654`). The stalled hold is step 7's: "the session keeps it out of step 10 until that entry is answered" (`skills/dev-cycle/SKILL.md:573-574`).

**Evidence:** `skills/dev-cycle/SKILL.md:569-576`, `skills/dev-cycle/SKILL.md:647-654`, `skills/dev-cycle/SKILL.md:768-775`

---

## Claim 4: "So in this repo self-merge can land only files outside those directories and off the floor: docs the floor does not protect, `README.md`, `runs/`, `archive/`, and any path under a new top-level name."

**Location:** `docs/dev-cycle.md:55-57` (same list at `docs/working/questions.md:122` Q-103 [2] and `:373` Q-149 [1])
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the top-level entries at 1a3d432a against the never line and the floor's dot-path and instruction-file classes. It does not establish which individual files under `docs/`, `runs/` or `archive/` the floor refuses ("off the floor" and "docs the floor does not protect" defer to it).

Top-level entries at 1a3d432a (paraphrased — no quote available because the claim is about directory layout, from `git ls-tree --name-only 1a3d432a`):
- Dot entries: `.apir5-probe.sh`, `.apir5-probe2.sh`, `.evidence-config.example`, `.gitattributes`, `.gitignore`, `.shellcheckrc`. All are floor dot paths.
- Instruction files: `AGENTS.md`, `GEMINI.md`. Both are floor.
- On the never line: the ten directories at `docs/dev-cycle.md:11`.
- Left over: `README.md`, `archive`, `docs`, `runs`.

So the list is complete. A new top-level name matches no never glob, and the floor refuses it only if it is a dot path or an instruction name.

**Evidence:** `docs/dev-cycle.md:11`, `docs/dev-cycle.md:55-57`, `git ls-tree --name-only 1a3d432a`

---

## Claim 5: Roadmap: "`git_state_gate` does not check `refs/replace/` (nor `core.attributesFile`, U5 final security F1), so `.manifest` can record a commit whose content the image does not hold"

**Location:** `docs/roadmap.md:76-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git_state_gate's key regex and repo_git's flags. It does not establish the impact path through `.manifest`, which the earlier review established.

```bash
# devcontainer-config/install.sh:208
GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.)'
```

The gate reads only those keys (plus a non-empty `info/attributes`). repo_git sets only `core.hooksPath` and `core.fsmonitor`: `git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"` (`devcontainer-config/install.sh:181`). Neither touches `core.attributesFile`.

**Evidence:** `devcontainer-config/install.sh:180-182`, `devcontainer-config/install.sh:208-252`

---

## Claim 6: Rubric iteration-3 section (counts, the two Incorrect clusters, rows A12-A15 and C22-C31 with their sources)

**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:117-142`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each row's source IDs and tiers against the final replicate, merged, security and api-consistency reports. It does not establish the "Its result is below" result, which this report and the narrow security check provide. r1 claim 42 and r3 claim 49 (commit bodies) are not mapped to a row, but both point to the already-existing override rows 829-830.

Replicate totals are `**Total claims checked:** 44`, `47` and `50` in the r1, r2 and r3 reports, matching "44/47/50". The merged report lists exactly two Incorrect clusters: Claim 1 (graft, `r1=Mostly accurate · r2=— · r3=Incorrect`) and Claim 2 (three override rows, `r1=Incorrect · r2=Mostly accurate · r3=Mostly accurate`). Each source ID resolves to a non-Verified replicate claim on the same subject (paraphrased — no quote available because the check spans fifteen rows across five reports; the mapping was read from each report's `## Claim N` headings and `**Verdict:**` lines):
- A12 → r3 36b, r1 32.
- A15 → r1 41, r2 45, r3 46-47.
- C22 → r1 14, r1 26, r3 28.
- C23 → r1 10b, r2 11, r3 10.
- C24 → r1 27, r1 28b, r2 31b, r3 32.
- C25 → r2 36, r3 38.
- C26 → r2 26.
- C27 → r2 29b.
- C29 → r1 17, r2 18.
- C31 → r1 4.

The critic rows match the critics' summary tables:
- A13 is security F1, Medium.
- A14 is api F1, Inconsistent.
- C25's api half is F3.
- C28 is F2.
- C30 is F4.

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-14-u5-final.md:1-120`, `docs/reviews/code-fact-check-report-2026-10-14-u5-final-r{1,2,3}.md` (claim headings), `docs/reviews/security-review-2026-10-14-u5-final.md:112-114`, `docs/reviews/api-consistency-review-2026-10-14-u5-final.md:112-117`

---

## Claim 7: The two new override rows (b5eaedf6/659a1c61 commit bodies; install.sh following a local `core.attributesFile`)

**Location:** `docs/reviews/override-log.md:832-833`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rows' source IDs and line citations. It does not establish the second row's "install.sh's payload diff shows a dropped file before the y prompt" beyond the security report's own executed note.

Row 832 cites "final fact-check r1 claim 41, r2 claim 45, r3 claims 46-47". r3 claim 47 is the 659a1c61 body, and the others are the b5eaedf6 "three override rows" body. Row 833's citations resolve as follows:
- `install.sh:180-182` is `repo_git() {` through its closing brace.
- `:208` is the `GIT_EXEC_KEYS_RE` line.
- `:279-280` is `if ! repo_git -c tar.umask=022 archive --format=tar "$commit" -- "$@" \` / `| tar -xpf - -C "$dir/.extract"; then`.

The row's "refuses a local `core.attributesFile`" matches the paste's `--local` test (Claim 15c).

**Evidence:** `docs/reviews/override-log.md:832-833`, `devcontainer-config/install.sh:180-182`, `:208`, `:279-280`, `docs/reviews/security-review-2026-10-14-u5-final.md:42-46`

---

## Claim 8: Q-103 F11: "`checkout_gate` closes checkout conversions, `core.symlinks` false, sparse checkout and untracked nested repositories for the gate. Still open (known issue A5): start files under a symlinked directory, a FIFO start, other names one file has on a case-insensitive filesystem whose `core.ignoreCase` is false, and a checkout file swapped between the gate's check and the walk's read; and instruction files outside the repo that the container cannot see (the host's own)."

**Location:** `docs/working/questions.md:95`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the closed list against checkout_gate and the open list against A5's "Still open there" sentence. checkout_gate also refuses `core.ignoreCase` true and a gitlink checked out with files, which the closed list does not name. The list is a subset, not a misstatement. This verdict does not establish the walk-level (non-gate) gaps A5 also lists.

checkout_gate refuses three settings: `"core.symlinks false: ..." "core.ignoreCase true: ..." "core.sparseCheckout true: a sparse checkout"` (`scripts/build-loop.sh:1243-1244`). It also refuses an untracked nested repository: `CHECKOUT_WHY="the checkout holds an untracked nested repository, whose instruction files the walk does not read"` (`:1266`). For conversions it has: `CHECKOUT_WHY="a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)"` (`:1294`). A5 reads: "Still open there: start files under a symlinked directory, a FIFO start, other names one file has on a case-insensitive filesystem whose `core.ignoreCase` is false, and a checkout file swapped between the gate's check and the walk's read" (`docs/working/known-issues-dev-cycle.md:18`). That is word for word the entry's open list.

**Evidence:** `scripts/build-loop.sh:1233-1295`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 9: "**Also routed here during the build** (rows are override-log rows in `docs/reviews/override-log.md`, by line; the U2b3a item is from the plan's U2b3a bullet and the U4c item from SKILL.md's D6 Rule)"

**Location:** `docs/working/questions.md:104`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two named non-row sources. It does not establish that every other item cites a row number: the U3a1 item and the first half of the U3a2 item carry only a unit name, though both have override rows (638 and 671).

The plan's U2b3a sub-bullet reads "Residual: a hostile loop can edit the worktree registry in the shared common dir (Q-103)" (`docs/working/plan-build-loop-handoff.md:293`). SKILL.md's D6 Rule reads "a hostile process of this uid still reaches the shell itself, through PATH, exported functions or the session's settings: the residual the plan and Q-103 accept" (`skills/dev-cycle/SKILL.md:43-44`). Row 638 (`feat/build-loop-u3a1`, "store_check does not re-hash objects a decision reaches only through history") and row 671 (`feat/build-loop-u3a2`, "A planted `core.bare=true` with the main worktree's index deleted") back the two unit-named items.

**Evidence:** `docs/working/questions.md:104-117`, `docs/working/plan-build-loop-handoff.md:293`, `skills/dev-cycle/SKILL.md:36-46`, `docs/reviews/override-log.md:638`, `:671`

---

## Claim 10: Q-103 [2]: "lands ... when every changed path is in its `Paths:` line or is one of the brief's own files, and is off the floor and the never line; a path refusal falls to [1]'s entry, a conflict ends stopped and an environment refusal is retried"

**Location:** `docs/working/questions.md:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SKILL.md step 7's self-merge branch and srules' allowlist. It does not establish what happens after [1]'s entry (a deny that refuses again under `--approved` is filed as stopped, per step 7), which the cell does not claim.

Step 7: "A refusal of the paths ... falls through to review: a merge entry as below ... A conflict is `stopped`. Any other refusal (no identity, MAIN_WT's state, a moved main, a failed read) is the environment's ... tried again next iteration." (`skills/dev-cycle/SKILL.md:585-592`). srules: `[[ "$2" != "$3" ]] || ! ownfile "$2" "$1" "$4" || return 0` before the `Paths:` check (`scripts/build-loop.sh:1209`).

**Evidence:** `skills/dev-cycle/SKILL.md:577-592`, `scripts/build-loop.sh:1202-1217`

---

## Claim 11: Q-149 [1]: "self-merge lands only docs the floor does not protect, `README.md`, `runs/`, `archive/` and paths under a new top-level name"

**Location:** `docs/working/questions.md:373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same evidence and residue as Claim 4.

The wording is the same as `docs/dev-cycle.md:56-57` (quoted in Claim 4), checked against the same top-level listing.

**Evidence:** `docs/dev-cycle.md:55-57`, `git ls-tree --name-only 1a3d432a`

---

## Claim 12: Q-149 "**If the answer differs:** an edit to the never line in `docs/dev-cycle.md` ..., to its Never-line prose there and Q-103 [2], and to its test line in `test/scripts/build-loop-read.bats`."

**Location:** `docs/working/questions.md:379`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the places that state this repo's never-line width. It does not establish anything about SKILL.md or other repos, which state no width.

The test line exists: `[[ "$(line never)" == "never workflows/ scripts/ test/ hooks/ devcontainer-config/ skills/ guides/ patterns/ templates/ global-instructions/ set: ...` (`test/scripts/build-loop-read.bats:80`). Two more lines of Q-103 state the never line's contents and would go false under [2] or [3]:
- F58: "The release paste runs `devcontainer-config/install.sh` before it shows its diff, so that directory is on this repo's never line (Q-149)." (`docs/working/questions.md:101`)
- The last "also routed" item: "which is why this repo's never line holds `scripts/`, `test/`, `hooks/` and `devcontainer-config/` (row 682, Q-149)" (`docs/working/questions.md:117`).

Precise version: "... to its Never-line prose there, to Q-103 [2], its F58 bullet and its last 'also routed' item, and to its test line ...".

**Evidence:** `docs/working/questions.md:101`, `:117`, `:122`, `:379`, `docs/dev-cycle.md:11`, `:41-60`, `test/scripts/build-loop-read.bats:80`

---

## Claim 13: Q-151 "**If the answer differs:** [2] is a change to the skill's slot counts in steps 8 and 10."

**Location:** `docs/working/questions.md:409`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two slot counts in SKILL.md. It does not establish any change [2] would need in `build-loop.sh`, which counts no slots.

Step 8 leaves a blocked brief uncounted ("a blocked, stopped, capped or ready one ... is not counted", `skills/dev-cycle/SKILL.md:653-654`). Step 10 subtracts only "the loops this session runs" (`:773`), and a blocked loop has ended. Holding the slot changes both counts.

**Evidence:** `skills/dev-cycle/SKILL.md:647-654`, `skills/dev-cycle/SKILL.md:768-775`

---

## Claim 14: Q-156: "M is `8cff4877aa30a9417b48bd792ef60319502d7e78`, the last commit on `feat/build-loop-u5` that changes anything the release installs; the branch's later commits change only `docs/`"

**Location:** `docs/working/questions.md:470`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste's path set at 1a3d432a. It does not establish that main stays at b279a2ba until the merge (the paste's `differs from M` refusal covers that).

Command: `git log --format='%h %s' -3 1a3d432a -- .gitattributes devcontainer-config global-instructions guides hooks patterns scripts skills workflows`. It printed `8cff4877 fix(dev-cycle): step 10 files constraints-doc-missing once, open or answered` first, then 659a1c61 and 771a5d02. `git diff --name-only 8cff4877 1a3d432a | grep -v '^docs/'` printed nothing. Both commands ran in `/workspace/.claude/wt-build-loop-u5` and exited 0 at about 2026-10-15T05:38Z. Output is quoted here because it is two lines. In E3 the unmodified paste with M=8cff4877 passed the `differs from M` loop on a clone at 1a3d432a (`== clean` → `STUB-INSTALL-RAN`, exit 0). 8cff4877 changes only `skills/dev-cycle/SKILL.md`, which the "Paths changed" and "Gate code changed" lists already name.

**Evidence:** `docs/working/questions.md:470-476`, `logs/paste.out`

---

## Claim 15a: Q-156 paste: "with only `rev-parse`, `for-each-ref` and `config --get` ... and replace refs ignored, it checks ... that no replace ref exists ... and no graft file ... and that the root `.gitattributes` and every directory the release installs from are the same tree at HEAD as at M"

**Location:** `docs/working/questions.md:491`, `:494`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the replace-ref, graft, local-attributesFile and path-drift refusals and the git subcommands the paste runs. HEAD (15b) and the config breadth (15c) are verdicted separately. This verdict does not establish install.sh's own behavior after the paste.

The paste's git calls are `git rev-parse ...`, `git for-each-ref refs/replace/` and `git config --local --get core.attributesFile`, under `export GIT_NO_REPLACE_OBJECTS=1` (`docs/working/questions.md:494`). E3 results:
- `replace-ref` → `release refused: replace refs present`, exit 1.
- `grafts` → `release refused: info/grafts present`, exit 1.
- `local-attributesFile` → `release refused: core.attributesFile set`, exit 1.
- `main-moved-scripts` (a new file under `scripts/` on a moved main) → `release refused: scripts differs from M`, exit 1.
- `main-moved-no-path-change` → the stub ran.

E5 confirms the replace-ref reason: `git archive` of the commit printed `fake` for a blob replaced by a replace ref. The `export` lives inside the paste's subshell, so install.sh's own archive does not inherit it.

**Evidence:** `docs/working/questions.md:491-495`, `logs/paste.out`, `logs/replace.out`

---

## Claim 15b: Q-156 paste: "it checks that HEAD is main"

**Location:** `docs/working/questions.md:491`, `:494`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the paste's first test. It does not establish any harm: the released content is the same either way, since the path loop then compares trees.

```bash
# docs/working/questions.md:494 (first test of the paste)
test "$(git rev-parse HEAD)" = "$(git rev-parse refs/heads/main)" || { echo "release refused: HEAD is not main"; exit 1; }
```

(excerpt ends inside the one-line paste; the rest of the line, through `./devcontainer-config/install.sh`, was read)

The test compares commit IDs, not the branch HEAD names. In E3 (`head-not-main`), HEAD was a symbolic ref to another branch at main's commit. The paste passed and the stub ran (exit 0). Precise version: "that HEAD is at main's commit".

**Evidence:** `docs/working/questions.md:494`, `logs/paste.out`

---

## Claim 15c: Q-156 paste: "that the checkout's config sets no `core.attributesFile` (whose `export-ignore` or `export-subst` would change what the archive writes)"

**Location:** `docs/working/questions.md:491`, `:494`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what `git config --local --get core.attributesFile` sees against what install.sh's `git archive` follows, for `.git/config`, `config.worktree` and `include.path`. It does not establish system or global config, which are the user's own, nor git versions other than the sandbox's.

The test is `test -z "$(git config --local --get core.attributesFile)"` (`docs/working/questions.md:494`). `--local` reads only `$GIT_DIR/config` and does not follow includes. E3 results:
- `include-attributesFile`: `.git/config` holds `include.path` to a file setting `core.attributesFile`. Plain `git config --get` sees `/tmp/x-attrs`, but the paste passed and the stub ran. install.sh's own git_state_gate refuses any `include` key (`GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.)'`, `devcontainer-config/install.sh:208`), so this route stops at install.sh.
- `worktree-config-attributesFile`: `extensions.worktreeConfig true` plus `core.attributesFile` in `config.worktree`. Plain `git config --get` sees it, and the paste passed and the stub ran.

E4 shows the second route reaches the archive. Under repo_git's flags, `git archive HEAD -- scripts` listed only `scripts/a` when `config.worktree`'s attributes file said `scripts/b export-ignore`, and `git config --local --get core.attributesFile` printed nothing. git_state_gate reads `config.worktree` only for `GIT_EXEC_KEYS_RE` keys (`devcontainer-config/install.sh:220`), so no gate catches it. The payload diff remains the only backstop.

The refusal holds for a key set directly in `.git/config` (Claim 15a). The commit body and override row 833 say "local", which is accurate. The questions entry's "the checkout's config" is broader than the test. Either the entry should say "the checkout's `.git/config`", or the test should read `git config --get core.attributesFile` with system and global config off (for example `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null`). Whether that read is hook-free and whether it suffices is for the security check to confirm.

**Evidence:** `docs/working/questions.md:491`, `:494`, `devcontainer-config/install.sh:208-252`, `:279-280`, `logs/paste.out`, `logs/wtcfg.out`

---

## Claim 16: Q-156 "**If the answer differs:** each refusal names its cause. `differs from M`: main changed a released path after M ... `HEAD is not main`: put the host checkout on main first, knowing that a checkout runs any hook a sandbox planted. Replace refs, grafts or `core.attributesFile`: planted state; remove it and find out who wrote it before releasing."

**Location:** `docs/working/questions.md:498`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each of the paste's five refusal messages names its cause and has an explanation, and that the label is the grammar's. It does not establish that following the remedies is safe beyond the stated hook caveat.

The paste's five messages are `HEAD is not main`, `replace refs present`, `info/grafts present`, `core.attributesFile set` and `$p differs from M` (`docs/working/questions.md:494`). E3 printed four of them, and the HEAD one is reachable when HEAD's commit differs. The global instructions' entry grammar has the field `- **If the answer differs:** <what gets redone>`. A `git checkout` runs the `post-checkout` hook, so the caveat holds (paraphrased — no quote available because this is git's documented hook behavior, not repo code).

**Evidence:** `docs/working/questions.md:494-498`, `logs/paste.out`

---

## Claim 17: Step 10: "else one `you: judgment` entry, slug `constraints-doc-missing`, asking for `docs/constraints.md`, unless WT's questions files hold one with that slug, open or answered: D2"

**Location:** `skills/dev-cycle/SKILL.md:770-772`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers consistency with step 0.1's `image-off-main-C12` rule and what "WT's questions files" means in the skill. It does not establish a script check: step 10's dedupe is skill text that the orchestrator follows, and no script enforces it.

Step 0.1 says "file one `you: judgment` entry `image-off-main-C12` ..., unless WT's questions files hold one" (`skills/dev-cycle/SKILL.md:292-293`). That has the same predicate, with "open or answered" spelled out here. The skill names the two files as "WT's `docs/working/questions.md` or `questions-archive.md`" (`skills/dev-cycle/SKILL.md:340-341`), so an answered and archived Q-155 still counts. Q-155's [2] option ("Dispatch stays off until the roadmap item yields a way to write one", `docs/working/questions.md:457`) is the answer the old "open one" rule would have re-asked.

**Evidence:** `skills/dev-cycle/SKILL.md:285-296`, `:336-345`, `:768-775`, `docs/working/questions.md:446-458`

---

## Claim 18: Commit 8cff4877's body: step 10 "re-filed the constraints entry whenever no open one existed, so answering Q-155 [2] ... would bring the same question back next iteration. It now files one unless WT's questions files hold one with that slug, open or answered, as image-off-main-C12 does." Notes: "verified by the narrow k=1 check recorded in the rubric."

**Location:** commit `8cff4877`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the body against the commit's diff. The Notes line anticipates this check, and becomes true once its result is recorded in the rubric.

The diff replaces "unless an open one with that slug exists" with "unless WT's questions files hold one with that slug, open or answered" (`git diff b5eaedf6..1a3d432a -- skills/dev-cycle/SKILL.md`). This check verifies the new wording (Claim 17).

**Evidence:** `skills/dev-cycle/SKILL.md:770-772`, `git show 8cff4877`

---

## Claim 19: Commit 1a3d432a's body (paste pins M=8cff4877 and refuses a local `core.attributesFile`; settings prose fixes; Q-103 fixes; "Q-149 and Q-151 name every place a change touches"; roadmap adds `core.attributesFile`; reports, rubric section, "two override rows")

**Location:** commit `1a3d432a`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers each listed change against the commit's diff. It does not re-verdict the content claims, which Claims 1-17 cover.

Every listed change is in the diff:
- M=8cff4877.
- The `config --local --get` test.
- No graft-honoring reason.
- The "If the answer differs" label.
- The four settings-prose fixes.
- F11, the header and [2].
- The Q-149 and Q-151 lines.
- The roadmap clause.
- Two override-log lines added (`docs/reviews/override-log.md | 2 +`).

One phrase overstates: "Q-149 and Q-151 name every place a change touches". Q-149 omits Q-103's F58 bullet and its last "also routed" item (Claim 12). Commit history is immutable, so this belongs in the override log if it is kept.

**Evidence:** `git show --stat 1a3d432a`, `git log -1 --format=%B 1a3d432a`, `docs/working/questions.md:101`, `:117`, `:379`

---

## Claims Requiring Attention

### Incorrect
- **Claim 15c** (`docs/working/questions.md:491`, `:494`): "the checkout's config sets no `core.attributesFile`" is wider than the paste's `git config --local --get` test. A key in `config.worktree` (with `extensions.worktreeConfig`) passes the paste and changes install.sh's archive, as executed. A key behind `include.path` also passes the paste but is caught by install.sh's own gate. Fix: narrow the prose to `.git/config`, or read the key with system and global config off so `config.worktree` and includes are seen.

### Stale
- none

### Mostly Accurate
- **Claim 12** (`docs/working/questions.md:379`): Q-149's "If the answer differs" also needs Q-103's F58 bullet (`:101`) and its last "also routed" item (`:117`).
- **Claim 15b** (`docs/working/questions.md:491`): "checks that HEAD is main" compares commits. A different branch or a detached HEAD at main's commit passes. Say "HEAD is at main's commit".
- **Claim 19** (commit `1a3d432a`): "Q-149 and Q-151 name every place a change touches" overstates for Q-149. The commit is immutable, so record it as an override row if needed.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/code-fact-check-report-2026-10-14-u5-narrow.md, structured per the code-fact-check skill, first line `Commit: 1a3d432a`, header `**Replication:** k=1 (narrow check after the final pass)`.
- Answered: yes. All six focus areas were checked, with `--settings`, the paste and the archive behavior executed in throwaway repos.
- Out of scope: the review reports added in 1a3d432a, beyond their use as the rubric's sources; everything before b5eaedf6.
- Escalate: Claim 15c. A `config.worktree` `core.attributesFile` gets past both the paste and install.sh's gate, so the security check should confirm the route and the fix.
- Decisions I made: I counted the paste's `include.path` gap inside 15c rather than as its own claim, since install.sh refuses it. I verdicted 15b Mostly accurate because a commit-equal HEAD releases identical content.
