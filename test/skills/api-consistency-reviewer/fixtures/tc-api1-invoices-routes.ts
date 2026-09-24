import { Router, Request, Response } from "express";
import { db } from "../db";
import { requireAuth } from "../middleware/auth";

export const router = Router();

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 200;

interface Page<T> {
  data: T[];
  next_cursor: string | null;
}

function parseLimit(raw: unknown): number {
  const n = Number(raw ?? DEFAULT_LIMIT);
  if (!Number.isFinite(n) || n <= 0) return DEFAULT_LIMIT;
  return Math.min(n, MAX_LIMIT);
}

function encodeCursor(id: string): string {
  return Buffer.from(id, "utf8").toString("base64url");
}

function decodeCursor(cursor: unknown): string | undefined {
  if (typeof cursor !== "string" || cursor.length === 0) return undefined;
  return Buffer.from(cursor, "base64url").toString("utf8");
}

async function paginate<T extends { id: string }>(
  table: string,
  accountId: string,
  req: Request,
): Promise<Page<T>> {
  const limit = parseLimit(req.query.limit);
  const after = decodeCursor(req.query.cursor);
  const rows: T[] = await db(table)
    .where({ account_id: accountId })
    .modify((q) => {
      if (after) q.where("id", ">", after);
    })
    .orderBy("id", "asc")
    .limit(limit + 1);
  const hasMore = rows.length > limit;
  const data = hasMore ? rows.slice(0, limit) : rows;
  return {
    data,
    next_cursor: hasMore ? encodeCursor(data[data.length - 1].id) : null,
  };
}

// GET /v1/customers?limit=&cursor=
router.get("/v1/customers", requireAuth, async (req: Request, res: Response) => {
  res.json(await paginate("customers", req.auth.accountId, req));
});

// GET /v1/orders?limit=&cursor=
router.get("/v1/orders", requireAuth, async (req: Request, res: Response) => {
  res.json(await paginate("orders", req.auth.accountId, req));
});

// GET /v1/products?limit=&cursor=
router.get("/v1/products", requireAuth, async (req: Request, res: Response) => {
  res.json(await paginate("products", req.auth.accountId, req));
});

// GET /v1/orders/:id
router.get("/v1/orders/:id", requireAuth, async (req: Request, res: Response) => {
  const order = await db("orders")
    .where({ account_id: req.auth.accountId, id: req.params.id })
    .first();
  if (!order) {
    res.status(404).json({ error: { code: "not_found", message: "Order not found" } });
    return;
  }
  res.json(order);
});

// BEGIN CHANGE UNDER REVIEW
// GET /v1/invoices?page=&per_page=
router.get("/v1/invoices", requireAuth, async (req: Request, res: Response) => {
  const page = Math.max(1, Number(req.query.page ?? 1));
  const perPage = Math.min(Number(req.query.per_page ?? 25), 100);
  const base = db("invoices").where({ account_id: req.auth.accountId });
  const [{ count }] = await base.clone().count({ count: "*" });
  const items = await base
    .clone()
    .orderBy("id", "asc")
    .offset((page - 1) * perPage)
    .limit(perPage);
  res.json({ items, total: Number(count), page, per_page: perPage });
});
// END CHANGE UNDER REVIEW
