# Pattern: Requesting User Input

## What this is

A small, reusable checklist that any workflow consults at the moment it must stop and ask the user a question — an approval gate, a clarifying question, a choice between approaches, a confirmation before something irreversible.

This is **not a workflow you run directly** — it's a reference, like [`orchestrated-review.md`](orchestrated-review.md). When a workflow's step says "ask the user X" or "the user reviews and approves," that step should require the prompt to satisfy the checklist below and cite this pattern. The goal is that a user can answer correctly *from the prompt alone*, without re-reading the plan, guessing what their answer will do, or fearing they can't take it back.

The checklist encodes four usability properties — **signifier**, **conceptual model**, and **error recoverability** (Don Norman's vocabulary), plus **context continuity** (the usability principle of keeping system status visible across a transition) — all applied to a text prompt instead of a physical control. A prompt that satisfies all four is self-explanatory; a prompt that drops one is the common failure mode where the user approves something they didn't understand, picks an option whose consequences were invisible, commits to a choice believing it was final when it wasn't, or has to scroll back through prior output to reconstruct what they're even deciding about.

## The checklist

Before sending any prompt that asks the user to decide, confirm, or choose, verify it carries all four:

- [ ] **Signifier** — the prompt makes the available actions and their input format *perceivable*. The user can see what the valid responses are (the options, or the expected input shape) without inferring them. No "what do I even type here?"
- [ ] **Conceptual model** — the prompt states what each choice *will cause*. The user understands the consequence of each option — what happens next, what gets changed, what becomes true — before they pick. No "what does approving this actually do?"
- [ ] **Error recoverability** — the prompt states whether and how the choice can be undone. The user knows if this is reversible, how to back out or correct a wrong answer, and how to abort entirely. No "is this my last chance — can I take it back?"
- [ ] **Context continuity** — the prompt restates the carried context the answer depends on: what's already been decided and what state the answer operates on. The user can decide from the prompt alone, without scrolling back through prior output to reconstruct the situation. No "wait, what are we deciding about again?"

If any box can't be checked, the prompt is incomplete — fix the prompt before sending it, don't rely on the user to ask the follow-up.

## The four properties

### Signifier

A signifier is a perceivable cue that communicates *what action is possible and how to take it*. For a CLI prompt this means the response space is explicit on the face of the prompt:

- For a multiple-choice prompt (e.g. `AskUserQuestion`): every selectable option is shown with a label that names the action, not just an index. "Approve plan as written" beats "Option 1."
- For a free-text prompt: the expected format is shown — units, example value, or constraints. "Enter a timeout in seconds (e.g. `30`)" beats "Enter timeout."
- The *default* and how to accept it are visible when one exists. "(press Enter to keep `main`)" beats a silent default.

The test: a user who has never seen this workflow can tell what they're allowed to type or pick from the prompt alone.

### Conceptual model

The conceptual model is the user's understanding of *how the system works and what their answer will change*. The prompt supplies it by stating the consequence of each available choice:

- What happens immediately after each option (what runs, what gets written, what gets skipped).
- What state changes — files touched, commits made, external calls fired.
- For an approval gate: what the user is actually approving, in terms of downstream effect, not just "the plan."

The test: for each option, the user can finish the sentence "if I pick this, then ______" without opening another document.

### Error recoverability

Error recoverability is how easily the user can *undo a mistake*. The prompt makes the cost of a wrong answer visible up front:

- Whether the action is reversible, and if so how (e.g. "you can re-edit the plan after approving — implementation pauses again at the test gate").
- How to back out without choosing any of the offered options (the abort/cancel path — e.g. `AskUserQuestion` always offers "Other," and many gates allow "none of these, let me explain").
- For an irreversible action, say so explicitly and name the point of no return ("this pushes to the shared remote and cannot be unpushed cleanly").

The test: the user knows, before answering, whether a wrong pick is a quick correction or a permanent commitment.

### Context continuity

Context continuity is the prompt carrying its own context forward across the transition to the user, so the decision doesn't require re-reading what came before. By the time a workflow stops to ask, the relevant output may have scrolled away, or the user may be returning after a break. The prompt restates the state the answer operates on:

- What has already been decided or established that this choice builds on — the plan that was approved, the branch that was selected, the values gathered so far.
- The current state the answer acts against — what exists now, what's pending, what the last step produced.
- Enough of the prior result that the user need not scroll back to it — the relevant numbers, names, or paths appear in the prompt itself, not only in output above it.

The test: a user returning to the terminal after a break can answer correctly from the prompt alone, without scrolling up to rebuild the context.

## Preferred mechanism

The four properties are requirements on the prompt, not a choice of tool — but the tool you reach for decides how much of the work is structural versus prose you have to remember to write. **Default to `AskUserQuestion` for any decision or approval gate; fall back to a free-text prompt only when the answer is genuinely open.**

`AskUserQuestion` builds two of the four properties into its shape:

- **Signifier comes for free.** Each option is a labelled action, so the response space is perceivable by construction — there is no way to render the prompt *without* showing the user what they can pick. A hand-rolled prompt has to state its options in prose, and the *Bare confirmation* and *Options without consequences* anti-patterns are exactly what happens when that prose is skipped.
- **The conceptual model gets a dedicated slot.** Each option carries a description, which is where its consequence belongs — "if I pick this, then ______." The structure reserves the space; you still have to fill it with the real downstream effect rather than restating the label.
- **The exit path is structural.** Every `AskUserQuestion` carries an automatic "Other" option, so the user is never trapped in a fixed set — the *No exit* anti-pattern can't occur. (Error recoverability still needs the reversibility/point-of-no-return statement written in; "Other" only covers the escape-from-the-options half.)

What the structure does **not** supply is **context continuity** — `AskUserQuestion` has no slot that restates the carried state the answer depends on. Put that in the question text, and put each option's consequence in its description; the tool provides the slots, not the substance.

Reserve the free-text path for answers that are genuinely open — a value, a name, a free-form correction, an explanation — that don't reduce to a small set of named choices. `AskUserQuestion` allows only two to four options per question; when the real answer space is wider than that, or unbounded, forcing it into four buckets misrepresents the decision. There, use a free-text prompt and satisfy all four properties in prose, following [the checklist](#the-checklist).

The two paths compose within one gate: a common shape is an `AskUserQuestion` whose listed options cover the expected choices while "Other" absorbs the open case — the user picks a named action when one fits and types a free answer when none does.

### Comparison-heavy gates: route per-option detail to `preview`

`AskUserQuestion` gives each option a third slot beyond label and description: `preview`, content rendered natively when that option is focused. The description is meant to be the one-line consequence — "if I pick this, then ______" — but on a gate whose options differ on *comparison data* (relative effort or cost, risk, diff size, multi-axis tradeoffs), that data tends to get crammed into the description until it is no longer a line but a paragraph the user can't scan. Route the comparison data to `preview` instead: the description stays the scannable consequence shown in the option list, and the per-option detail lives in the on-focus surface, surfaced exactly when the user is weighing that one option.

This splits the conceptual-model property across two registers rather than dropping it. The consequence is always visible (description), and the supporting detail that justifies it — the scorecard row, the effort estimate, the risk notes, the tradeoff cells — is one focus-keystroke away (preview), rendered natively rather than flattened into prose. The test from [Conceptual model](#conceptual-model) still has to pass on the description alone; preview earns its place only by carrying the comparison detail that would otherwise overload that line.

**Scope it to gates that are genuinely comparison-heavy.** This is a recommendation for gates whose options carry multi-axis data the user must weigh against each other — not a blanket mandate to populate `preview` on every prompt. Two named cases:

- **DD's step-4 human consult** ([`workflows/divergent-design.md`](../workflows/divergent-design.md), Path B): each option is a surviving candidate that differs from its siblings along a whole scorecard row. The description carries the candidate's key downside plus its falsifiable hypothesis; `preview` is the natural home for that candidate's scorecard row and stress-test detail, so the option list stays scannable while the full comparison is a focus away.
- **RPI plan approval** ([`workflows/research-plan-implement.md`](../workflows/research-plan-implement.md) step 4) when approve-as-written / approve-with-changes / not-yet differ on concrete effort or diff size: `preview` can hold the per-option diff summary or step count that distinguishes them.

For a gate whose options *don't* differ on comparison data — a plain confirm/decline, or a yes/no/not-yet whose consequence fits in a line — the description alone carries the conceptual model, and an empty or padded `preview` is just noise. Don't add it.

**Preview is a property of the prompt — keep it non-interactive-safe.** Like the four properties themselves, `preview` exists only on a path that actually issues an `AskUserQuestion` to a human; a decision that a non-interactive or overnight run resolves statically has no prompt, hence no preview surface. DD makes this concrete: only Path B (tradeoff unclear, human present) prompts — Path A (one approach dominates) and Path C (SI loop / overnight) render a static decision block and proceed without ever blocking. So the comparison data has two homes depending on the path: `preview` on the human-present prompt, and the static decision block on the paths that never prompt. Don't treat preview as the channel that carries comparison data to a non-interactive run — that is the static block's job; preview has nothing to render against there.

## Worked example

Same prompt — a plan-approval gate — written badly and well.

**Badly written (drops all four):**

```
Plan is ready. Approve?
```

This fails on each property. *Signifier:* the response space is invisible — is the answer yes/no, or is the user expected to type corrections? *Conceptual model:* "approve" has no stated consequence — does approving start implementation immediately, or just unlock it? *Error recoverability:* nothing says whether approval is final or whether the user can still change the plan afterward. *Context continuity:* nothing restates which plan, how many steps, or what was decided to get here — if the plan output has scrolled away, the user must scroll back to reconstruct what "approve" even refers to.

**Well written (carries all four):**

```
The plan (docs/working/plan-export.md) has 5 steps; approving it starts
implementation in /away mode — I'll write tests, then code, committing
after each step. Pick one:
  - Approve as written        → I begin step 1 now
  - Approve with changes      → tell me the edits; I revise the plan, then begin
  - Not yet — I have questions → nothing runs; we keep discussing

You can still interrupt after any commit, and the test-first gate pauses
again for review before implementation code is written. Nothing is pushed
until you say so.
```

*Signifier:* three named options, each an action. *Conceptual model:* each option states what runs next. *Error recoverability:* the interrupt path, the second pause point, and "nothing is pushed until you say so" tell the user the cost of approving is recoverable. *Context continuity:* the prompt names the plan file, its step count, and the mode it will run in, so the decision needs nothing scrolled back. A user can answer this from the prompt alone.

## Anti-patterns

- **Bare confirmation** — "Proceed? (y/n)" with no statement of what proceeding does or whether it's reversible. The user either over-trusts (says yes blind) or stalls to ask the follow-up the prompt should have answered.
- **Options without consequences** — a clean multiple-choice list where the labels name the choices but not their effects ("A / B / C"). Satisfies signifier, drops conceptual model.
- **Silent irreversibility** — asking for confirmation of a destructive or outward-facing action (force-push, delete, send) without flagging that it can't be undone. The most expensive failure, because the missing property is exactly the one that mattered.
- **No exit** — offering a fixed set of options with no "none of these / let me explain" path, forcing the user to pick a listed answer even when the right answer is "you've mis-framed the question."
- **Context amnesia** — a prompt that assumes the user still has the prior output on screen ("Approve the above?", "Which of these do you want?") and restates none of it. After a long-running step whose output has scrolled away — or for a user returning after a break — the answer can't be given without scrolling back. Satisfies the other properties on paper but fails the moment the context isn't already visible.

## Using this pattern in new workflows

When a workflow step asks the user to decide, confirm, or choose:

1. Add a cross-reference at the call-site: "the prompt must satisfy the [requesting-user-input checklist](../patterns/requesting-user-input.md#the-checklist)."
2. Add a `Done when...` item (or equivalent gate condition) asserting the prompt carried all four properties, so the wiring is auditable rather than aspirational.
3. For prompts that gate an irreversible or outward-facing action, treat the error-recoverability property as load-bearing: the prompt must name the point of no return explicitly.

**Example callers:**

- [`workflows/research-plan-implement.md`](../workflows/research-plan-implement.md) step 4 (Annotate) — the plan-approval gate — requires its approval prompt and any clarification asked during the annotation cycle to satisfy this checklist. This is the *recoverable* case: the prompt's job is to make clear the choice can be walked back (approve-with-changes, not-yet, interrupt-after-any-commit).
- [`workflows/branch-strategy.md`](../workflows/branch-strategy.md) Integration branch refresh, step 7 (Promote only through the approval gate) — the gate that approves force-pushing the shared `dev`. This is the *irreversible-for-others* case, and the first call-site where error-recoverability is **load-bearing** per step 3 above: the prompt must name the point of no return — the force-push cannot be cleanly undone — rather than reassure that the choice is reversible.
