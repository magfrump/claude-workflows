// Test fixture for TC-C6.1: Multiple claims across a file for output format testing
// Contains 8+ checkable claims of varying accuracy

const fs = require("fs");

// Cache TTL is 10 minutes
const CACHE_TTL = 600; // seconds — this is correct (600s = 10min)

// Maximum retry count is 5
const MAX_RETRIES = 3; // incorrect — comment says 5, code says 3

/**
 * Returns null when the file is not found.
 */
function readConfig(path) {
  try {
    return JSON.parse(fs.readFileSync(path, "utf8"));
  } catch {
    return undefined; // returns undefined, not null
  }
}

/**
 * O(1) lookup by key.
 */
function getFromCache(cache, key) {
  return cache[key]; // correct — object property access is O(1) average
}

// This is the only function that writes to disk
function writeToDisk(path, data) {
  fs.writeFileSync(path, JSON.stringify(data));
}

// Also writes to disk — contradicts "only function" claim above
function appendLog(path, entry) {
  fs.appendFileSync(path, entry + "\n");
}

/**
 * Sorts items in ascending order.
 * Uses quicksort for O(n log n) performance.
 */
function sortItems(items) {
  // Array.sort in V8 uses Timsort, not quicksort — but O(n log n) is correct
  return [...items].sort((a, b) => a - b);
}

/**
 * Creates the output directory if it doesn't exist.
 */
function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true }); // correct — does create the dir
  }
}

module.exports = {
  CACHE_TTL,
  MAX_RETRIES,
  readConfig,
  getFromCache,
  writeToDisk,
  appendLog,
  sortItems,
  ensureDir,
};
