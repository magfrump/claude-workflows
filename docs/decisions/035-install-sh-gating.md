# 035 — Gate `install.sh` at commit time, not at install time

- **Goal**: decide how `devcontainer-config/install.sh` — host-executed, agent-writable, and the file that decides which diff the human reviews before blessing — comes under a gate.
- **Project state**: `main`, standalone · closes finding R1 of the 2026-09-12 code review, the last open item in `docs/working/questions.md` · not blocked; sequenced behind finding A7 (the gate must actually be installed).
- **Task status**: in-progress (decided 2026-09-12; implementation lands with the A7 fix)

## Context

The 2026-09-12 code review (`docs/reviews/code-review-rubric-2026-09-12-main-questions-closeout.md`) filed R1 🔴:
`install.sh` sits outside all three gates that cover its six siblings. It is not in `PAYLOAD`
(`install.sh:25`), so the `diff -ru` loop at `:83-99` never shows changes to itself; not in
`enforcement_files()` (`cc-isolated.sh:107-130`), so it is not manifest-hashed and not in the config
hash; and not in `live-verify-gate.sh:57`'s enforcement regex — commit `8980861` modified it with no
`Live-verified:` trailer. Its own header at `:7-14` asserts "edits here are inert", which is true of
every `PAYLOAD` entry and false of this file, which runs on the host and chooses the diff the human
reads. Pre-existing structural exposure; the 2026-09-12 diff put it in scope.

Full divergence, constraints and compatibility matrix: `docs/working/dd-install-sh-gating.md`.

## Options considered

14 candidates across four levers — where the review happens (3, 4, 5, 6, 13), who owns the file
(7, 9, 10), process (11), and detection (14) — plus do-nothing (0, 1), docs-only (2) and sequencing
(12). Four survived step-3 pruning: **[3]** commit-time regex, **[8]** provenance print, **[4]**
self-diff against a recorded copy, **[7]** move the installer off the repo.

## Decision and rationale

**Chosen: [3] — add `install\.sh` to `hooks/live-verify-gate.sh:57`'s enforcement regex**, so a commit
touching it requires a `Live-verified:` trailer, with two sub-fixes absorbed: **[2]** the header's
"edits here are inert" sentence is rewritten to name install.sh as the exception (hard constraint H5,
which no enforcement candidate satisfies on its own), and **[12]** the change lands together with the
A7 fix, because a hook declared in `hooks/wiring.json:62-72` but absent from live settings gates
nothing.

It is the only survivor that satisfies all five hard constraints. It is also the only cheap one that
satisfies **H2** — the enforcing code is served from the root-owned `0555` image payload (decision 022),
so an in-session edit to the repo copy does not change the code that runs until a human has run
install.sh, rebuilt and blessed. [8] and [4] both reduce to install.sh vouching for install.sh; [7] is
the only candidate that *closes* the exposure rather than making it loud, and it was declined on H7 —
nothing about it is checkable from this sandbox, and it splits 016's canonical-config-is-committed
property into two trust regimes.

The honest residual, conceded rather than hidden: **[3] does not close the hole, it makes an edit loud.**
Decided via Path B (`AskUserQuestion`) at 75% confidence; runner-up [8], axis of disagreement =
*loudness at commit time vs. loudness at execution time*. The project's stated preference along that
axis is already on the record — decision 45 chose a free-text commit trailer over an execution-time
hash check for exactly these files, on the grounds that "the failure to fix is the question going
*unasked*". [3] extends that same mechanism to a seventh file; [8] would have introduced a second one.

See alternatives considered → *Pruned candidates and why*, below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas
can grep this section to avoid regenerating already-pruned approaches.

`[0 status quo] / [1 do-nothing + override log]: ✗ on H5 — both leave the header asserting inertness for a file that is not inert, which is 015's "a boundary that silently degrades is worse than none".` `[2 docs-only]: absorbed, not discarded — it is a required sub-fix of every survivor, the way 016 absorbed its [1] loud-fail guard.` `[4 self-diff]: ✗ on H2 and dominated by [8] — the same unfixable self-reference at 4× the code plus a new dotfile under $DEST.` `[5 self-diff + manifest]: ⚠ on H3 — installs a copy of a file whose header says it is not installed, and re-blesses on every installer edit, for a threat that is host-side execution rather than installed bytes.` `[6 shim to the installed reviewer] / [13 review moves to --bless]: ✗ on S2 — two reviewers, two code paths [carried from 016-multi-project-devcontainer-central-config [4]: "two code paths and two trust regimes"]; [13] additionally ⚠ on H1, since --bless runs after the cp -r it would be gating.` `[7 move the installer off the repo]: ✗ on H7 and S2 — the strongest principle in the field and the only true closure, declined because it is unverifiable from this sandbox and splits the committed-canonical-config property; retained as a revisit trigger.` `[8 provenance print]: runner-up, not dead — ✗ on H2, but it covers the one path [3] cannot reach; see Stress-test mitigations.` `[9 signed manifest]: ✗ on H7, no key infrastructure on this host; served as the ideal-if-free space-widener.` `[10 root-owned 0444]: ⚠ — a root-owned file in a git worktree breaks checkout/stash for the human it protects.` `[11 social checklist]: ✗ on H7 and only ~ on H1 — a checklist is not an artifact the flow produces [same objection as 017's [8] skill: advisory, not a gate].` `[12 sequence behind A7]: absorbed as a sequencing requirement, not a rival.` `[14 tracked sha256 + guard]: ✗ on H2 — the checker is a repo file the same session can edit, so it reduces to [4] with more ritual.` `Prior pruning grep: matches found for [install, bless, gate, boundary, hash, manifest, verify] — [carried from 016 [4] hybrid central + blessed override: two code paths, two trust regimes] → soft constraint S2; [carried from 016 [11] raw CLI: "a silently-degrading boundary is worse than none"] → hard constraint H5.`

## Stress-test mitigations

- How to read: *Failure-driven* mitigation — the move enumerated a failure category the compatibility
  matrix missed: `live-verify-gate.sh` is a PreToolUse/Bash hook, so it sees only commits made through a
  hooked container session. A commit authored at the host shell, or in a session that unwired its hooks
  (decision 023 is explicit the wiring is "a default, not a boundary"), never trips it. This tagged [3]'s
  key downside `(mitig.)` and made **[8] a standing complement** rather than a rejected rival — it runs on
  the host at the exact moment [3] has no reach. [8] is not implemented now; it is the named fallback if
  the revisit trigger below fires.
- How to read: *Organizational survival* mitigation — held [3]'s risk at low rather than medium: the
  `Live-verified:` trailer ritual already exists for six sibling files under decision 45, and
  `git log --grep 'Live-verified: no'` is already the documented debt list, so a seventh file adds no new
  habit and no new concept.

## Consequences

**Easier.** Every `install.sh` edit now has to answer the same question its six siblings answer, through
a mechanism the human already knows. The debt list (`git log --grep 'Live-verified: no'`) becomes complete
for the boundary rather than complete-minus-one. The header stops making a false claim about its own file.

**Harder.** The regex's own comment (`live-verify-gate.sh:55-56`) currently says the set is "what
`enforcement_files()` hashes, as repo paths"; that correspondence stops being exact and has to be
reworded, so the next person keeping the two in step has one exception to carry. The exposure itself is
unchanged: an agent that edits `install.sh` and a human who blesses without reading still lose, and
`install.sh` remains outside the manifest and the config hash by design.

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision.
Future readers can grep this section when their context changes to see whether earlier decisions still apply.

`if a second operator gains host access → [7] becomes live, since "the reviewer must not live where the reviewed can write" stops being a solo-dev abstraction.` `if any commit touching devcontainer-config/install.sh lands with no Live-verified: trailer and no block after A7 is installed → [3]'s hypothesis is refuted; implement [8].` `if host-side commits touching install.sh appear in git log (author not a container session) → the failure-driven residual has materialised; implement [8] as the complement.` `if hooks/wiring.json's live-verify-gate entry is ever removed, or live settings lose it again → this decision is inert and R1 re-opens.` `if install.sh is ever added to PAYLOAD or enforcement_files() → H3 changed; re-run the matrix, [5] may become viable.`
