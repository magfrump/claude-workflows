// Test fixture for TC-C1.3: Architectural claim
// Comment claims "this is the only caller" — skill must grep to verify

// validateToken is the core auth check.
// This is the only caller of validateToken().
function authMiddleware(req, res, next) {
  const token = req.headers.authorization;
  if (validateToken(token)) {
    next();
  } else {
    res.status(401).send("Unauthorized");
  }
}

function validateToken(token) {
  return token && token.startsWith("Bearer ");
}

// Second caller — contradicts the "only caller" claim above
function wsAuthHandler(socket) {
  const token = socket.handshake.auth.token;
  return validateToken(token);
}

module.exports = { authMiddleware, validateToken, wsAuthHandler };
