// Test fixture for TC-C2.1: Verified verdict
// Comment accurately describes the behavior

/**
 * Throws TypeError if name is empty.
 */
function greet(name) {
  if (!name) {
    throw new TypeError("name must not be empty");
  }
  return `Hello, ${name}!`;
}

module.exports = { greet };
