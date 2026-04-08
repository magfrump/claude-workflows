# Scope Exception: hypothesis-auto-expiry

## Integration with self-improvement.sh

The `auto_expire_hypotheses` function should ideally be called from Step 0 of
`scripts/self-improvement.sh`, before the manual hypothesis evaluation loop.
This would look like:

```bash
# Add before the "for PRIOR_ROUND in ..." loop (around line 281):
auto_expire_hypotheses "$ROUND"
```

This file is outside the allowed file scope for this task, so the integration
was not made. The function is currently exposed as a standalone invocation —
any script that sources `scripts/lib/si-functions.sh` can call
`auto_expire_hypotheses <current_round> [log_path]`.
