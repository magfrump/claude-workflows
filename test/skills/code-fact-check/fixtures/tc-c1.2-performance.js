// Test fixture for TC-C1.2: Performance claim
// Comment says O(n) but the implementation is O(n^2)

/**
 * Finds duplicate entries in the list.
 * O(n) lookup using hash comparison.
 */
function findDuplicates(items) {
  const duplicates = [];
  // Actually O(n^2) due to nested loops
  for (let i = 0; i < items.length; i++) {
    for (let j = i + 1; j < items.length; j++) {
      if (items[i].id === items[j].id) {
        duplicates.push(items[i]);
      }
    }
  }
  return duplicates;
}

module.exports = { findDuplicates };
