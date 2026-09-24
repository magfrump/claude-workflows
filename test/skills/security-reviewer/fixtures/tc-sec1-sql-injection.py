import sqlite3

from flask import Flask, g, jsonify, request

app = Flask(__name__)
DB_PATH = "/var/lib/shop/catalog.db"


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(_exc):
    db = g.pop("db", None)
    if db is not None:
        db.close()


@app.get("/api/products")
def list_products():
    category = request.args.get("category", "all")
    sort = request.args.get("sort", "name")
    limit = min(int(request.args.get("limit", 50)), 200)

    sql = "SELECT id, name, price, stock FROM products"
    params = []
    if category != "all":
        sql += " WHERE category = ?"
        params.append(category)
    sql += f" ORDER BY {sort} LIMIT ?"
    params.append(limit)

    rows = get_db().execute(sql, params).fetchall()
    return jsonify([dict(r) for r in rows])
