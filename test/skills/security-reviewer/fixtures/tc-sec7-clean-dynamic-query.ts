import { Router, Request, Response } from "express";
import { pool } from "./pg";
import { requireAuth, AuthedRequest } from "./auth";

const router = Router();

const SORT_COLUMNS: Record<string, string> = {
  created: "o.created_at",
  total: "o.total_cents",
  status: "o.status",
};

router.get("/orders", requireAuth, async (req: Request, res: Response) => {
  const user = (req as AuthedRequest).user;
  const sortKey = String(req.query.sort ?? "created");
  const column = SORT_COLUMNS[sortKey] ?? SORT_COLUMNS.created;
  const direction = req.query.dir === "asc" ? "ASC" : "DESC";
  const limit = Math.min(Math.max(parseInt(String(req.query.limit ?? "20"), 10) || 20, 1), 100);

  const clauses = ["o.customer_id = $1"];
  const params: unknown[] = [user.id];

  if (typeof req.query.status === "string" && req.query.status.length > 0) {
    params.push(req.query.status);
    clauses.push(`o.status = $${params.length}`);
  }

  params.push(limit);
  const sql =
    `SELECT o.id, o.status, o.total_cents, o.created_at FROM orders o ` +
    `WHERE ${clauses.join(" AND ")} ` +
    `ORDER BY ${column} ${direction} ` +
    `LIMIT $${params.length}`;

  const { rows } = await pool.query(sql, params);
  res.json(rows);
});

export default router;
