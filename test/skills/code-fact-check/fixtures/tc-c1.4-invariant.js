// Test fixture for TC-C1.4: Invariant claim
// Comment says userId is never null, but there's a code path where it can be

function processRequest(req) {
  // userId is never null at this point
  const userId = req.session?.userId;

  // But req.session could be undefined (optional chaining returns undefined)
  // and even if session exists, userId could be missing
  return fetchUserData(userId);
}

function fetchUserData(userId) {
  if (!userId) {
    throw new Error("userId is required");
  }
  return { id: userId, data: {} };
}

module.exports = { processRequest, fetchUserData };
