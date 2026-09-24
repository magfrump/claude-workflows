import base64
import pickle
import time

from flask import Flask, make_response, render_template, request

app = Flask(__name__)
PREFS_COOKIE = "prefs"
DEFAULT_PREFS = {"theme": "light", "page_size": 25, "pinned": []}


def load_prefs():
    raw = request.cookies.get(PREFS_COOKIE)
    if not raw:
        return dict(DEFAULT_PREFS)
    try:
        return pickle.loads(base64.urlsafe_b64decode(raw))
    except Exception:
        return dict(DEFAULT_PREFS)


def save_prefs(resp, prefs):
    blob = base64.urlsafe_b64encode(pickle.dumps(prefs)).decode()
    resp.set_cookie(PREFS_COOKIE, blob, max_age=60 * 60 * 24 * 365, samesite="Lax")
    return resp


@app.get("/dashboard")
def dashboard():
    prefs = load_prefs()
    return render_template("dashboard.html", prefs=prefs, now=time.time())


@app.post("/prefs")
def update_prefs():
    prefs = load_prefs()
    if request.form.get("theme") in ("light", "dark"):
        prefs["theme"] = request.form["theme"]
    size = request.form.get("page_size", "")
    if size.isdigit() and 10 <= int(size) <= 100:
        prefs["page_size"] = int(size)
    return save_prefs(make_response("", 204), prefs)
