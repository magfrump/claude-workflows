// Test fixture for TC-C2.4: Incorrect verdict
// Docstring says it creates the directory, but code throws

const fs = require("fs");
const path = require("path");

/**
 * Writes data to the specified path.
 * Creates the directory if it doesn't exist.
 */
function writeData(filePath, data) {
  // Does NOT create the directory — will throw if missing
  fs.writeFileSync(filePath, JSON.stringify(data));
}

module.exports = { writeData };
