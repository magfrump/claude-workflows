// Test fixture for TC-C2.3: Stale verdict
// Comment describes old behavior; code has been updated

/**
 * Retries the operation up to 5 times with exponential backoff.
 * (Note: This was true before the recent refactor. Now it only retries 3 times.)
 */
async function withRetry(fn) {
  const MAX_RETRIES = 3; // changed from 5 in recent commit
  let attempt = 0;
  while (attempt < MAX_RETRIES) {
    try {
      return await fn();
    } catch (err) {
      attempt++;
      if (attempt >= MAX_RETRIES) throw err;
      await new Promise((r) => setTimeout(r, 100 * Math.pow(2, attempt)));
    }
  }
}

module.exports = { withRetry };
