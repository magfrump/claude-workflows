# RPI: Wire branch-strategy step-7 promote gate to requesting-user-input checklist

Status: complete
Relevant paths: workflows/branch-strategy.md, patterns/requesting-user-input.md

## Research

### Task
The integration-branch-refresh step 7 ("Promote only through the approval gate") in
`workflows/branch-strategy.md` currently describes the most irreversible-for-others operation in the
repo — force-pushing over the shared `dev` — but the approval itself is only prose ("requires explicit
human approval per the Operating Modes gate"). Wire that gate to the shipped
`patterns/requesting-user-input.md` checklist so the approval is solicited with a structured prompt
carrying **signifier**, **conceptual model**, and **error recoverability** content. This gives the
round-1 cli-input template (the requesting-user-input checklist) its first *load-bearing* call-site —
load-bearing because the action is irreversible, so error-recoverability is the property that matters.

### Prior art
- **`patterns/requesting-user-input.md`** — the checklist. "Using this pattern in new workflows"
  prescribes the wiring: (§1) add a cross-reference at the call-site citing the checklist; (§2) add a
  `Done when…` item asserting the prompt carried all three properties; (§3) for irreversible/
  outward-facing actions, treat error-recoverability as load-bearing — the prompt must name the point
  of no return. Its "Example caller" currently lists only RPI step 4.
- **`workflows/research-plan-implement.md`** step 4 (Annotate, lines 369–373) — the existing model
  call-site. Cross-references the checklist in prose and carries a matching `Done when…` item. That is
  the *recoverable* gate (approval can be walked back); branch-strategy step 7 is the *irreversible*
  counterpart.
- **`workflows/branch-strategy.md`** step 7 (lines 250–261) — the gate to wire. Already states the
  operation is irreversible-for-others and requires explicit human approval per Operating Modes; it
  just lacks a conforming prompt and an auditable `Done when…` item. Its `Done when…` checklist is at
  lines 278–284.

### Invariants to preserve
- Do not weaken existing `/away`-mode gating language. The "Do **not** force-push… requires explicit
  human approval per the Operating Modes gate" paragraph stays intact — the structured prompt is *how*
  that approval is solicited, not a replacement for the gate. The human picking "Promote now" IS the
  explicit approval the gate requires.
- Match the file's `Done when…` and cross-reference conventions (mirror RPI step 4's wording shape).
- Same relative link as RPI uses: `../patterns/requesting-user-input.md#the-checklist`.

## Plan
1. **branch-strategy.md step 7** — after the existing "Do not force-push…" paragraph (kept verbatim),
   add (a) a cross-reference sentence requiring the approval prompt to satisfy the checklist, flagging
   error-recoverability as load-bearing per §3; (b) a concrete conforming prompt with three named
   options, a per-option consequence clause, and a closing "cannot be cleanly undone… capture the SHA"
   line; (c) a sentence mapping the prompt's parts to the three properties.
2. **branch-strategy.md `Done when…`** — add an item asserting the promotion prompt carried all three
   properties (signifier / conceptual model / error recoverability), naming the point of no return.
3. **requesting-user-input.md** — expand the single "Example caller" into "Example callers" listing
   both: RPI step 4 as the *recoverable* case and branch-strategy step 7 as the *irreversible-for-
   others* case where error-recoverability is load-bearing (§3). This makes the pattern document both
   poles and records branch-strategy as the load-bearing call-site.

## Verification
- Markdown renders; new prompt is a readable blockquote; ordering/conventions match the file.
- The conforming prompt visibly satisfies all three checklist properties; the mapping sentence makes
  that auditable.
- Existing force-push gating language is unchanged (grep the "requires explicit human approval"
  sentence still present).
- Only the two in-scope files touched (plus this doc under docs/working/).
