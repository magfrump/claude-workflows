import express, { Request, Response, NextFunction } from "express";
import { db } from "./db";
import { verifySession } from "./session";

interface AuthedRequest extends Request {
  user?: { id: string; orgId: string; role: "member" | "admin" };
}

const router = express.Router();

async function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const token = req.cookies?.session;
  const user = token ? await verifySession(token) : null;
  if (!user) {
    return res.status(401).json({ error: "unauthenticated" });
  }
  req.user = user;
  next();
}

router.get("/invoices", requireAuth, async (req: AuthedRequest, res: Response) => {
  const invoices = await db.invoice.findMany({
    where: { orgId: req.user!.orgId },
    select: { id: true, number: true, total: true, status: true },
  });
  res.json(invoices);
});

router.get("/invoices/:id", requireAuth, async (req: AuthedRequest, res: Response) => {
  const invoice = await db.invoice.findUnique({
    where: { id: req.params.id },
    include: { lineItems: true, billingContact: true },
  });
  if (!invoice) {
    return res.status(404).json({ error: "not found" });
  }
  res.json(invoice);
});

export default router;
