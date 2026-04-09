# Debugging Worked Examples

Three scenarios grounding the debugging defaults from CLAUDE.md. Reference these when forming hypotheses, deciding when to pivot, or choosing between root-cause and symptom fixes.

## (a) Good vs. Bad Hypothesis Formation

**Bug:** Users report "invalid date" errors when submitting forms with timezone offsets like `+05:30`.

**Bad hypothesis:** "Something is wrong with date parsing."
— Not falsifiable. No specific location, mechanism, or expected outcome. You can't design a test for "something."

**Refined hypothesis:** "`parseDate()` in `utils/date.ts:42` returns `null` for inputs containing `+HH:MM` because the regex `\d{4}-\d{2}-\d{2}` doesn't match the timezone suffix, causing the downstream `formatDate` call to throw."
— Names the function, the mechanism (regex mismatch), and a testable prediction (returns `null` for `+HH:MM` input).

**Test:** Call `parseDate("2026-04-08T10:00:00+05:30")` and check the return value.
If `null` → hypothesis confirmed → fix the regex.
If valid date → hypothesis refuted → record finding, form next hypothesis.

## (b) Three Failed Hypotheses → Pivot to RPI Research

**Bug:** API returns 500 on `POST /orders` intermittently. Stack trace points to `OrderService.create()`.

**Hypothesis 1:** "The database connection pool is exhausted under load."
Test: Check pool metrics during failure. Result: Pool is at 20% capacity. **Refuted.**

**Hypothesis 2:** "`inventory.reserve()` throws when quantity is zero because of a missing guard."
Test: Submit order with quantity=0. Result: Guard exists, returns 400 correctly. **Refuted.**

**Hypothesis 3:** "Race condition — two concurrent orders for the same item cause a unique constraint violation."
Test: Send two simultaneous orders for the same SKU. Result: Both succeed. **Refuted.**

**Pivot:** Three hypotheses refuted. Stop guessing. Pivot to RPI research phase:
- Re-read the full stack trace (not just the top frame)
- Run `git bisect` against the last known-good deploy
- The three refuted hypotheses document what the bug *isn't*, narrowing the search space

## (c) Root-Cause Fix vs. Symptom Fix

**Bug:** Users see stale profile data after updating their name. The UI shows the old name until a hard refresh.

**Symptom fix (avoid):** Add `window.location.reload()` after the update API call.
— Masks the problem. Causes a full page reload, degrades UX, and hides the real issue from future developers.

**Root-cause investigation:** The `updateProfile` mutation returns the updated user object, but the cache key `user:{id}` isn't invalidated. The `ProfileCard` component reads from the stale cache entry.

**Root-cause fix:** Invalidate the `user:{id}` cache entry in the `updateProfile` mutation's `onSuccess` handler.
— One-line change. No reload. The component re-renders naturally from the fresh cache. Future profile fields get the same fix for free.

**Litmus test:** If you'd need to apply the same fix in multiple places, or if removing it later would re-expose the bug, you're probably fixing the symptom.
