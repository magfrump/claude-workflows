// Test fixture for TC-C1.6: Reference claim
// Comment references an issue number — skill should check if it exists

/**
 * Workaround for issue #1234
 * The upstream library double-encodes UTF-8 strings in query parameters.
 * This pre-decodes before passing to the library.
 */
function sanitizeQuery(query) {
  try {
    return decodeURIComponent(query);
  } catch {
    return query;
  }
}

module.exports = { sanitizeQuery };
