I couldn't run the check with the tool: permission to run the calculation was denied, so this figure has not been machine-checked.

**The draft has one derived figure:**

| Claim | Inputs | Draft says | Assessment |
|---|---|---|---|
| Daily sessions | 1.2 million daily active users × 4 sessions per user | ~4.8 million/day | **Looks right, not tool-checked.** 1.2 × 4 = 4.8, so 1.2M × 4 = 4.8M. |

The other two numbers (1.2 million daily active users and 4 sessions per day) are inputs, not results, so there is no math to check for them.

**A note on the method, separate from the math:** 4.8M is an average daily total. If the backend is sized from this number, you'll also need peak load (sessions per second at the busiest time) and room for growth. Daily totals usually understate what the system has to handle at its peak.

If you want this confirmed with the tool, allow the Bash command and re-run.
