// Test fixture for TC-C1.1: Behavioral claim
// The comment says "returns null" but the code returns undefined

/**
 * Looks up a user by ID.
 * Returns null on empty input.
 */
function getUser(id) {
  if (!id) {
    return undefined; // <-- contradicts docstring
  }
  return { id, name: "test" };
}

module.exports = { getUser };
