const express = require("express");
const { users, resetTokens } = require("./store");
const { sendMail } = require("./mailer");

const router = express.Router();
const TOKEN_TTL_MS = 30 * 60 * 1000;

function makeToken(len = 32) {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let out = "";
  for (let i = 0; i < len; i++) {
    out += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return out;
}

router.post("/password/forgot", async (req, res) => {
  const user = await users.findByEmail(String(req.body.email || "").toLowerCase());
  if (user) {
    const token = makeToken();
    await resetTokens.put(token, { userId: user.id, expiresAt: Date.now() + TOKEN_TTL_MS });
    await sendMail(user.email, "Reset your password", `https://app.example.com/reset?token=${token}`);
  }
  res.status(202).json({ ok: true });
});

router.post("/password/reset", async (req, res) => {
  const entry = await resetTokens.get(String(req.body.token || ""));
  if (!entry || entry.expiresAt < Date.now()) {
    return res.status(400).json({ error: "invalid or expired token" });
  }
  await users.setPassword(entry.userId, req.body.password);
  await resetTokens.delete(req.body.token);
  res.json({ ok: true });
});

module.exports = router;
