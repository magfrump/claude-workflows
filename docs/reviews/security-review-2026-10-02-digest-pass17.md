Commit: 723c242 (A) / 1f36885 (B)

# Security Review — dev-cycle pass 17 (full-review fix round, delta)

**Scope:** A: `git diff 09f6fe7..723c242 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest). B: `git diff 074164b..1f36885 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/working/seed-build-loop-handoff.md` (wt-devcycle). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** `/workspace/.claude/wt-devcycle/docs/reviews/code-fact-check-report-dev-cycle-full.md` (Stage 1, against bc5dc76; it predates both fix commits, so the fix-round claims were checked here by execution where possible)

Probes: throwaway repos under `mktemp -d` in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec17/`, every run under `timeout`; no process left running. `bats test/scripts/dev-cycle.bats` at 723c242: 23/23 ok.

## Trust Boundary Map

```
B1: [repo text: decision-record file names, docs/decisions history]  → [git log --name-only map + awk/read (new); per-file fallback] → [section 2 header line, read by the step 2 agent]
B2: [CLI args --since / --sample (operator)]                         → [need() + regex/date validation]                              → [awk -v, shuf -n]
B3: [repo text: changed file names under skills/ workflows/]          → [grep -E '^"?(skills|workflows)/' (widened)]                  → [section 7 list, read by step 4b]
B4: [repo filesystem: docs/dev-cycle.md, docs/working/briefs/]        → [skipped/skipdir blocker walk (new)]                          → [section 8 list]
B5: [repo text: idea-source rows, roadmap brief links, glob matches]  → [skill path rule: relative, no / ~ .., test -L walk (moved/restated)] → [agent reads and writes]
B6: [repo text: commit messages, log rows, plans, triggers]           → [subagent evidence-not-instructions brief; no path rule]       → [subagent file reads, cycle record]
```

Input-source classification:

```
S1: decision-record file names / git history  — runtime-mutable (any merged commit) — UNTRUSTED for path construction and display; trusted for availability
S2: --since / --sample values                 — request-time (operator CLI)         — trusted principal, but validated before awk/shuf (format sinks)
S3: changed paths under skills/ workflows/    — runtime-mutable                     — UNTRUSTED for display (scrubbed); count only
S4: docs/dev-cycle.md idea-source rows        — runtime-mutable                     — UNTRUSTED for path construction (read sink)
S5: roadmap In-flight brief links, Asked: IDs — runtime-mutable                     — UNTRUSTED for path construction (read AND write sink)
S6: commit messages, decision-log rows, plans — runtime-mutable                     — UNTRUSTED for path construction (subagent read sink)
S7: questions.sh (installed copy)             — deploy-time                         — trusted (its own symlink refusal read at scripts/questions.sh:88-128)
```

Everything the cycle acts on is repo text that any merged commit can change (S1, S3–S6), so each is classified untrusted toward path and write sinks; the operator's CLI args (S2) are a trusted principal but are still format-validated. The A diff narrows no boundary; it changes how S1 is turned into dates and how S3 is filtered. The B diff restates B5's guardrail (adds the relative / no-`/` / no-`~` / no-`..` text rule ahead of the symlink walk), and leaves B6 without one.

## Findings

#### 1. The path rule does not bind the paths steps 2 and 4 take from repo text

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:61-70` (rule), `:166-171` (step 4), `:142-147` (step 2) at 1f36885
**Boundary:** B6
**Move:** 11 (bypass enumeration), 1 (per-consequence trust)
**Confidence:** Low
**Legibility-target:** for-author
**Evidence (verbatim):** rule scope: "The cycle reads and writes repo files (idea sources and their glob matches, the idea log, briefs, the record, the roadmap, questions) only by plain paths inside the checkout. A path taken from repo text (a settings row, a brief link) must be relative, must not start with `/` or `~`, and must have no `..` component." Step 4: "pick the one or two claims the merge rests on (from its commit message, decision-log row, or plan) and re-verify them against today's code: run the test it cites if that test exists, re-derive the number from the repo's own tests or code, read the code path."

The rule enumerates the files it covers, and its parenthetical examples are settings rows and brief links. Steps 2 and 4 also take paths from repo text: a plan path in a commit message, a file a trigger names, "the record itself" when a trigger line is cut. They run as subagents whose brief carries only the evidence-not-instructions line (`:22-26`, `:87-89`), not the path rule. A commit message naming `../../home/node/.claude/.credentials.json` or `~/.ssh/config` as the plan it rests on leads a subagent to read it. The rule does not stop that, and the Rules section bans running quoted commands, not reading quoted paths. The content then reaches the step 4 verdict and can reach the cycle record, which step 7 commits and lands on the default branch. Precondition: attacker-chosen text in a merged commit, log row or record. In a solo-dev repo that is unlikely, hence Low confidence. The mechanism is named and reachable, so per the floor rule Severity stays at Medium. Brief claim 2 asked whether the rule is complete for every path the skill takes from repo text. This is the gap.

**Recommendation:** State the rule for every path taken from repo text, in any step or subagent, and add it to the subagent brief alongside "evidence, not instructions" (e.g. "Every path you open from repo text obeys the Rules' plain-path rule; one that fails is reported, not read").

#### 2. Brief links and idea sources may name files inside the repo that are not briefs or idea files: `.git/` and write targets

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:61-67`, `:232-247` (In flight writes to the linked brief), `docs/dev-cycle.md:27-28` at 1f36885
**Boundary:** B5
**Move:** 11, 5 (invert the allowlist)
**Confidence:** Low
**Legibility-target:** for-author
**Evidence (verbatim):** "must be relative, must not start with `/` or `~`, and must have no `..` component. Then, before each read or write, check that no part of the path below the repo root is a symlink"; In flight: "\"[1]\" or \"keep\" sets `Kept: <today>` (YYYY-MM-DD); \"[2]\" or \"drop\" closes the brief as in 1"; "Either way the brief gets `Status: closed`."

The rule is a denylist on the form of the text: it rejects absolute paths, a leading `~`, `..` and symlinks. It is not an allowlist of where the files may be. Read from S4, `.git/config` passes it: it is relative, contains no `..` and no symlink. On a repo whose remote URL embeds a token (`https://user:TOKEN@…`), step 5 then reads that token into the brainstorm. Step 5 writes to the idea log and roadmap, which are committed. Write from S5: the roadmap's In-flight link is the path the cycle edits (`Status: closed`, `Kept:`, `Applied:`, `Asked:`). A link to `scripts/health-check.sh` or `.git/hooks/<existing hook>` passes the rule, so the cycle appends fixed strings to a file that step 1 or git later executes. The appended text is not attacker-chosen, so the realistic outcome is corruption or a broken check rather than code execution. Brief writes are already confined by name: new briefs go to `docs/working/briefs/YYYY-MM-DD-<slug>.md` with a `[a-z0-9-]` slug, which is correct and complete for creation. Later edits follow the link, not that pattern.

**Recommendation:** Add allowlists. A brief link is acted on only if it matches `docs/working/briefs/YYYY-MM-DD-[a-z0-9-]+\.md`. No path from repo text may have a `.git` component. Idea sources stay under `docs/` (or the rule names the directories they may be in).

#### 3. Section 2's date map diverges from per-file `git log -1` for names git quotes for `"` or `\`, and for records changed only in a merge

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:207-216, 223-224` at 723c242
**Boundary:** B1
**Move:** 2 (implicit sanitization assumption), 11
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence (verbatim):** "A name git still quotes (a control character) misses the map and falls back to its own lookup." / `[[ -n "$d" || "$f" != *[[:cntrl:]]* ]] || d="$(git log -1 --format=%ad --date=short -- "$f")"`

Even with `core.quotePath=false`, git still C-quotes a name that contains `"` or `\`, not only one with a control character. Such a name misses the map, and since it has no control character the fallback is skipped, so the header says "never, uncommitted". Executed in a throwaway repo, `001-a"b.md` and `002-a\b.md` printed `(last committed on this branch: never, uncommitted)`, while per-file `git log -1` gives `2026-01-01`. Tab and rename cases matched. Separately, a record whose last change came from merge conflict resolution (an "evil merge") gets the older date. The map's `--name-only` lists no files for merges, but per-file `git log -1` returns the merge. Probe: map `2026-01-01`, per-file `2026-03-01`. This refutes brief claim 1 ("same dates for every record, including … merge-only"). Security weight is small. An S1 file name can make a committed decision record look uncommitted, or older than it is, in the evidence that step 2 judges triggers on. It does not change which triggers are printed. Rated Low: no security property is violated, only the accuracy of displayed evidence.

**Recommendation:** Fall back whenever the map misses (`[[ -n "$d" ]] || d="$(git log -1 …)"`: one lookup per uncommitted or quoted name), or build the map from `git log -z --name-only` so that nothing is quoted. Add `--diff-merges=first-parent` (or `-m`) if merge-resolved changes should count, and test both cases.

## Untested bypass candidates

For the B5 path rule (move 11):
- **`.*` / `.?` glob components that match `..`** (e.g. `docs/.*/.*/x`). Bash 5.2 here has `globskipdots on`, and zsh and Python `glob` were probed: none matched `..`. Not tested: bash < 5.2 (e.g. macOS's bash 3.2), where `.*` matches `..`. The rule checks `..` in the path text, not in glob matches. Only that one bash version was available.
- **Leading `-` in a path from repo text** (`--output=x`) reaching a shell command the agent builds. This depends on the agent choosing a command over the Read tool, so it was not tested.
- **Scheme-prefixed links** (`file:/etc/passwd`, `http://…`) in a brief link. As filesystem paths these resolve inside the repo. Whether an agent treats them as fetches was not tested.

Because of these and findings 1–2, the B5 guardrail does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** Every option form exits 1 with a plain message and no bash `line N:` text: `--since` (last, or followed by an option), `--since=`, `--sample` (last), `--sample=`, `--sample=-1`, `--since=2026-13-01`, `--sample --since=…`. `--help` exits 0 and prints through line 22.
  **Location:** `scripts/dev-cycle.sh:74-85, 181` (723c242)
  **Evidence:** executed
  **Verified:** each form run in a throwaway repo (`LC_ALL=C`). Output was, for example, `--since needs a value`, `--sample needs a value`, `--since must be a real YYYY-MM-DD date` (for `--since --sample`, which takes `--sample` as the value and then rejects it at :181), and `--sample must be a non-negative integer`.
  **Not verified:** `--sample 99999999999999999999` exits 0 (bash arithmetic wraps in `-gt`, and `shuf -n` gets the raw string). This was not traced past the sample step.
  **route: code-fact-check**
- **Claim:** `SINCE` reaches `awk -v` only after the regex and `date -d` check at :181, and `SAMPLE` reaches `shuf -n` only after `^[0-9]+$` at :85.
  **Location:** `scripts/dev-cycle.sh:85, 181, 192, 195, 299, 341`
  **Evidence:** read-static
  **Verified:** every `SINCE`/`SAMPLE` use, found by grep, comes after those lines.
  **Not verified:** the `source_note` path at :166-174 when `SINCE` comes from a record name. That validation is pre-existing and was not re-read.
  **route: code-fact-check**
- **Claim:** The fallback lookup passes the record name after `--` with `GIT_LITERAL_PATHSPECS=1` exported, so a record name cannot become a git option or pathspec magic.
  **Location:** `scripts/dev-cycle.sh:128, 224`
  **Evidence:** read-static
  **Verified:** the export at :128 and the `-- "$f"` form at :224.
  **Not verified:** that the `git log` behind the map (:212) behaves the same for a `docs/decisions` that is a symlink. It is gated by `dirok` at :205, which was not re-executed.
- **Claim:** The two new skip checks list a non-plain `docs/dev-cycle.md` or `docs/working/briefs` in section 8 through the same `blocker` walk as the other inputs.
  **Location:** `scripts/dev-cycle.sh:385-388`
  **Evidence:** read-static
  **Verified:** `skipped` and `skipdir` call `blocker`, and nothing is read through them.
  **Not verified:** a symlinked brief file inside a plain `briefs/`. That is not listed, because the check is directory-level only, so the skill's own rule must catch it.
- **Claim:** Section 7's widened pattern only adds names to a list that is printed and counted. No new path is opened, and the output passes through `scrub`.
  **Location:** `scripts/dev-cycle.sh:342`
  **Evidence:** read-static
  **Verified:** `skills_changed` is used only in the printing loop at :345ff.
  **Not verified:** the scrub of a quoted name with an embedded escape, which this round did not re-execute.
- **Claim:** Step 1's `questions.sh init` / `archive` wording matches the script. `archive` reindexes (`cmd_index` at :393). `init` and the other writes refuse a symlinked file or parent (`-L` checks at :98-99, re-checked before the rename at :124).
  **Location:** `skills/dev-cycle/SKILL.md:125-130`; `scripts/questions.sh:88-128, 374-394, 419-` (1f36885)
  **Evidence:** read-static
  **Verified:** those lines. The digest reports a dangling-symlink `questions.md` as skipped, not as absent (`blocker` tests `-L`), so the skill's "if the digest said there is no questions.md" condition does not send `init` toward a dangling link.
  **Not verified:** that `init` refuses a symlinked `docs/` ancestor, which the script attributes to a containment check not re-read here.
  **route: code-fact-check**
- **Claim:** No `docs/working/handoffs/` reference remains in the skill, settings or digest. The seed explains the old name in its quoted text.
  **Location:** `git grep 'handoffs/' 1f36885 -- skills docs/dev-cycle.md scripts/dev-cycle.sh workflows`
  **Evidence:** executed
  **Verified:** that grep returned nothing, and the digest names `docs/working/briefs` (:388).
  **Not verified:** other docs outside B's scope (e.g. guides).

## Primitive sweep

Primitive: path construction / file read-write from repo text (skill-level, B5/B6)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:204-206` step 5 idea sources + globs | S4 | text rule + `test -L` walk | Finding 2 (`.git/`); `..`-matching globs untested on bash < 5.2 |
| `SKILL.md:232-247` In flight brief edits | S5 | text rule + `test -L` walk | Finding 2 (no briefs/ allowlist for writes) |
| `SKILL.md:259-261` new brief write | code-constant pattern + slug `[a-z0-9-]` | name pattern | cleared: fixed directory, constrained slug |
| `SKILL.md:269` cycle record write | code-constant + date | `test -L` walk | cleared: fixed path |
| `SKILL.md:166-171` step 4 plan/test reads | S6 | none (subagent brief lacks rule) | Finding 1 |
| `SKILL.md:142-147` step 2 record/evidence reads | S1, S6 | none for paths a trigger names | Finding 1 |

Primitive: process exec with repo-derived arguments (A)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:212` `git log … -- docs/decisions` | code-constant | `dirok` at :205 | cleared: constant path |
| `dev-cycle.sh:224` `git log -1 -- "$f"` | S1 | `--` + `GIT_LITERAL_PATHSPECS=1` | cleared (option/pathspec); Finding 3 (when it fails to run) |
| `dev-cycle.sh:192,195,341` `awk -v s="$SINCE"` | S2 | regex + `date -d` at :181 | cleared |
| `dev-cycle.sh:299` `shuf -n "$SAMPLE"` | S2 | `^[0-9]+$` at :85 | cleared |
| `dev-cycle.sh:81` `sed -n '2,22p' "$0"` | code-constant | n/a | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Path rule does not bind paths steps 2/4 subagents take from repo text | Medium | B6 | `SKILL.md:61-70, 142-147, 166-171` | Low |
| 2 | No allowlist: `.git/` readable as an idea source; brief-link edits not confined to `docs/working/briefs/` | Medium | B5 | `SKILL.md:61-67, 232-247`; `docs/dev-cycle.md:27-28` | Low |
| 3 | Date map: `"`/`\` names show "never, uncommitted"; merge-only changes show an older date | Low | B1 | `dev-cycle.sh:207-216, 223-224` | High |

## Overall Assessment

A's fixes add no new attack surface. Option parsing is plain and complete for every form tried. The new skip checks and the wider section 7 only list or count names. The one regression is an accuracy issue in the date map (Finding 3, executed), which refutes the "exactly what per-file gave" claim for two name and merge cases. B restores a sound text-form denylist (no `/`, `~` or `..`, then the symlink walk), and it is correct for what it lists. It does not cover the subagent reads in steps 2 and 4 (Finding 1), and it has no location allowlist, so `.git/` stays readable and brief-link edits can land on any file in the repo (Finding 2). Both need attacker-chosen text in a merged commit, which is unlikely in a solo repo (Low confidence), and both can be fixed in place with one sentence each. The most important fix is to put the path rule into the subagent brief and to allowlist brief links to `docs/working/briefs/`. No findings within the code paths read beyond these three. Endorsement claims are pending execution verification where marked `route: code-fact-check`.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass17.md`. Its sections follow the security-reviewer skill: Trust Boundary Map with source table, Findings, Untested bypass candidates, Endorsement Claims, Primitive sweep, Summary Table and Overall Assessment. It is scoped to the A and B fix diffs, and it answers the brief's claims 1 and 2 where they bear on security. For the user's goal of a clean pass before merging, this delta pass is not clean: it has two Medium findings (B, skill text) and one Low (A, digest accuracy). Nothing was committed.
