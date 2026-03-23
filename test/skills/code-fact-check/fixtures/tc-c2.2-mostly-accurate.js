// Test fixture for TC-C2.2: Mostly accurate verdict
// Comment says O(n) but the sort makes it O(n log n)

/**
 * Returns unique items from the array.
 * O(n) deduplication.
 */
function unique(items) {
  // The sort is O(n log n), making the overall function O(n log n), not O(n)
  const sorted = [...items].sort();
  const result = [sorted[0]];
  for (let i = 1; i < sorted.length; i++) {
    if (sorted[i] !== sorted[i - 1]) {
      result.push(sorted[i]);
    }
  }
  return result;
}

module.exports = { unique };
