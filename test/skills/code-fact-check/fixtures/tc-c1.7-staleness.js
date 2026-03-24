// Test fixture for TC-C1.7: Staleness signal
// Comment references validateInput() but the function was renamed to sanitizeInput()

/**
 * Main request handler.
 * Calls validateInput() to clean user data before processing.
 */
function handleRequest(data) {
  const clean = sanitizeInput(data); // renamed from validateInput
  return process(clean);
}

function sanitizeInput(data) {
  if (typeof data !== "string") return "";
  return data.trim().slice(0, 1000);
}

function process(data) {
  return { result: data };
}

module.exports = { handleRequest, sanitizeInput, process };
