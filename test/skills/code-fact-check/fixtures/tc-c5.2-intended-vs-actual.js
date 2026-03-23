// Test fixture for TC-C5.2: Documentation describes intended vs actual behavior
// Docstring says retries 3 times, but code retries 2 times (off-by-one)

/**
 * Fetches data from the API with retry logic.
 * Retries 3 times before giving up.
 */
async function fetchWithRetry(url) {
  let lastError;
  // Off-by-one: starts at 1, so it tries at 1 and 2 = only 2 retries
  for (let attempt = 1; attempt < 3; attempt++) {
    try {
      const response = await fetch(url);
      return await response.json();
    } catch (err) {
      lastError = err;
    }
  }
  throw lastError;
}

module.exports = { fetchWithRetry };
