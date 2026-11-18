#!/usr/bin/env python3
"""Mock API server for KotlinDev fixtures.

Serves the JSON files in ../sample-data/ as REST endpoints using only
the Python 3 standard library (http.server). No dependencies.

Usage:
    python3 mock-server.py [--port 8080] [--host 127.0.0.1]

Endpoints:
    GET /health                 -> {"status": "ok"}
    GET /users                  -> sample-data/users.json
    GET /users/{id}             -> one user, or 404 JSON
    GET /notes                  -> sample-data/notes.json  (?userId= filters)
    GET /notes/{id}
    GET /products               -> sample-data/products.json (?category= filters)
    GET /products/{id}
    GET /game-scores            -> sample-data/game-scores.json (?levelId= filters)
    GET /game-scores/{id}
    GET /levels/{levelId}       -> sample-data/levels/{levelId}.json

All responses are JSON with `Access-Control-Allow-Origin: *` so a
browser, emulator, or desktop test client can call it freely.
Android emulator note: from inside the emulator, reach this server on
the host at http://10.0.2.2:<port>/ (not localhost).
"""
import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

DATA_DIR = Path(__file__).resolve().parent.parent / "sample-data"
COLLECTIONS = {
    "users": "users.json",
    "notes": "notes.json",
    "products": "products.json",
    "game-scores": "game-scores.json",
}


def load_collection(name):
    return json.loads((DATA_DIR / COLLECTIONS[name]).read_text(encoding="utf-8"))


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # concise logging
        print(f"{self.command} {self.path} -> {args[1] if len(args) > 1 else ''}")

    def send_json(self, payload, status=200):
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        parts = [p for p in parsed.path.split("/") if p]
        query = {k: v[0] for k, v in parse_qs(parsed.query).items()}

        if not parts or parts == ["health"]:
            return self.send_json({"status": "ok", "collections": list(COLLECTIONS)})

        if parts[0] == "levels" and len(parts) == 2:
            file = DATA_DIR / "levels" / f"{parts[1]}.json"
            if file.exists():
                return self.send_json(json.loads(file.read_text(encoding="utf-8")))
            return self.send_json({"error": "level not found", "id": parts[1]}, 404)

        name = parts[0]
        if name not in COLLECTIONS:
            return self.send_json({"error": "unknown endpoint", "path": parsed.path}, 404)

        items = load_collection(name)
        if len(parts) == 2:
            try:
                wanted = int(parts[1])
            except ValueError:
                return self.send_json({"error": "id must be an integer"}, 400)
            for item in items:
                if item.get("id") == wanted:
                    return self.send_json(item)
            return self.send_json({"error": f"{name[:-1]} not found", "id": wanted}, 404)

        # collection with simple equality filters (?userId=1, ?category=audio, ?levelId=level-001)
        for key, value in query.items():
            items = [i for i in items if str(i.get(key, "")).lower() == value.lower()]
        return self.send_json(items)


def main():
    ap = argparse.ArgumentParser(description="KotlinDev fixtures mock API server")
    ap.add_argument("--port", type=int, default=8080)
    ap.add_argument("--host", default="127.0.0.1")
    args = ap.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Serving fixtures from {DATA_DIR} at http://{args.host}:{args.port}/  (Ctrl+C to stop)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
