# Pattern: Requesting User Input

## What this is

A small, reusable checklist that any workflow consults at the moment it must stop and ask the user a question — an approval gate, a clarifying question, a choice between approaches, a confirmation before something irreversible.

This is **not a workflow you run directly** — it's a reference, like [`orchestrated-review.md`](orchestrated-review.md). When a workflow's step says "ask the user X" or "the user reviews and approves," that step should require the prompt to satisfy the checklist below and cite this pattern. The goal is that a user can answer correctly *from the prompt alone*, without re-reading the plan, guessing what their answer will do, or fearing they can't take it back.

The checklist encodes three usability properties — **signifier**, **conceptual model**, and **error recoverability** (Don Norman's vocabulary, applied to a text prompt instead of a physical control). A prompt that satisfies all three is self-explanatory; a prompt that drops one is the common failure mode where the user approves something they didn't understand, picks an option whose consequences were invisible, or commits to a choice believing it was final when it wasn't.

## The checklist

Before sending any prompt that asks the user to decide, confirm, or choose, verify it carries all three:

- [ ] **Signifier** — the prompt makes the available actions and their input format *perceivable*. The user can see what the valid responses are (the options, or the expected input shape) without inferring them. No "what do I even type here?"
- [ ] **Conceptual model** — the prompt states what each choice *will cause*. The user understands the consequence of each option — what happens next, what gets changed, what becomes true — before they pick. No "what does approving this actually do?"
- [ ] **Error recoverability** — the prompt states whether and how the choice can be undone. The user knows if this is reversible, how to back out or correct a wrong answer, and how to abort entirely. No "is this my last chance — can I take it back?"

If any box can't be checked, the prompt is incomplete — fix the prompt before sending it, don't rely on the user to ask the follow-up.

## The three properties

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

## Worked example

Same prompt — a plan-approval gate — written badly and well.

**Badly written (drops all three):**

```
Plan is ready. Approve?
```

This fails on each property. *Signifier:* the response space is invisible — is the answer yes/no, or is the user expected to type corrections? *Conceptual model:* "approve" has no stated consequence — does approving start implementation immediately, or just unlock it? *Error recoverability:* nothing says whether approval is final or whether the user can still change the plan afterward.

**Well written (carries all three):**

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

*Signifier:* three named options, each an action. *Conceptual model:* each option states what runs next. *Error recoverability:* the interrupt path, the second pause point, and "nothing is pushed until you say so" tell the user the cost of approving is recoverable. A user can answer this from the prompt alone.

## Anti-patterns

- **Bare confirmation** — "Proceed? (y/n)" with no statement of what proceeding does or whether it's reversible. The user either over-trusts (says yes blind) or stalls to ask the follow-up the prompt should have answered.
- **Options without consequences** — a clean multiple-choice list where the labels name the choices but not their effects ("A / B / C"). Satisfies signifier, drops conceptual model.
- **Silent irreversibility** — asking for confirmation of a destructive or outward-facing action (force-push, delete, send) without flagging that it can't be undone. The most expensive failure, because the missing property is exactly the one that mattered.
- **No exit** — offering a fixed set of options with no "none of these / let me explain" path, forcing the user to pick a listed answer even when the right answer is "you've mis-framed the question."

## Using this pattern in new workflows

When a workflow step asks the user to decide, confirm, or choose:

1. Add a cross-reference at the call-site: "the prompt must satisfy the [requesting-user-input checklist](../patterns/requesting-user-input.md#the-checklist)."
2. Add a `Done when...` item (or equivalent gate condition) asserting the prompt carried all three properties, so the wiring is auditable rather than aspirational.
3. For prompts that gate an irreversible or outward-facing action, treat the error-recoverability property as load-bearing: the prompt must name the point of no return explicitly.

**Example callers:**

- [`workflows/research-plan-implement.md`](../workflows/research-plan-implement.md) step 4 (Annotate) — the plan-approval gate — requires its approval prompt and any clarification asked during the annotation cycle to satisfy this checklist. This is the *recoverable* case: the prompt's job is to make clear the choice can be walked back (approve-with-changes, not-yet, interrupt-after-any-commit).
- [`workflows/branch-strategy.md`](../workflows/branch-strategy.md) Integration branch refresh, step 7 (Promote only through the approval gate) — the gate that approves force-pushing the shared `dev`. This is the *irreversible-for-others* case, and the first call-site where error-recoverability is **load-bearing** per step 3 above: the prompt must name the point of no return — the force-push cannot be cleanly undone — rather than reassure that the choice is reversible.
