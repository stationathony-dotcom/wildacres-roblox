"""Petit pont Studio <-> disque (remplace Rojo, dont le téléchargement est bloqué).

Lance : python tools/sync.py   (écoute sur 127.0.0.1:34873)
Studio (via MCP ou la barre de commande) lit/écrit les scripts par HTTP :
  GET  /list                  -> JSON {chemin_studio: classe}
  GET  /file?p=Chemin.Studio  -> source du script
  POST /file?p=Chemin.Studio&c=Classe  (corps = source) -> écrit le fichier
  GET  /banc?f=nom             -> tools/bancs/nom.luau (à lancer par loadstring)
  POST /doc?f=NOM.md          (corps = texte) -> écrit docs/NOM.md (fiches générées par les bancs)

Correspondance : ServerScriptService.Systemes.World <-> src/ServerScriptService/Systemes/World.lua
  Script -> .server.lua, LocalScript -> .client.lua, ModuleScript -> .lua
"""

import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src")
ROOT = os.path.normpath(ROOT)
SUFFIX = {"Script": ".server.lua", "LocalScript": ".client.lua", "ModuleScript": ".lua"}


def studio_to_file(path: str, cls: str) -> str:
    parts = path.split(".")
    if any(p in ("", "..") or "/" in p or "\\" in p for p in parts):
        raise ValueError("chemin invalide")
    return os.path.join(ROOT, *parts[:-1], parts[-1] + SUFFIX.get(cls, ".lua"))


def list_files() -> dict:
    out = {}
    for dirpath, _, files in os.walk(ROOT):
        for f in files:
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, ROOT).replace(os.sep, ".")
            for cls, suf in (("Script", ".server.lua"), ("LocalScript", ".client.lua"), ("ModuleScript", ".lua")):
                if rel.endswith(suf):
                    out[rel[: -len(suf)]] = cls
                    break
    return out


def find_file(path: str):
    for cls in ("Script", "LocalScript", "ModuleScript"):
        f = studio_to_file(path, cls)
        if os.path.isfile(f):
            return f
    return None


class H(BaseHTTPRequestHandler):
    def _send(self, code: int, body: str, ctype: str = "text/plain; charset=utf-8"):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        u = urlparse(self.path)
        q = parse_qs(u.query)
        if u.path == "/banc" and "f" in q:
            # tools/bancs/<f>.luau : loadstring(H:GetAsync(".../banc?f=reference"))() depuis Studio
            name = q["f"][0]
            if not name.replace("_", "").isalnum():
                return self._send(400, "nom invalide")
            f = os.path.join(ROOT, "..", "tools", "bancs", name + ".luau")
            if not os.path.isfile(f):
                return self._send(404, "absent")
            with open(f, encoding="utf-8") as fh:
                return self._send(200, fh.read())
        if u.path == "/list":
            return self._send(200, json.dumps(list_files()), "application/json")
        if u.path == "/file" and "p" in q:
            f = find_file(q["p"][0])
            if not f:
                return self._send(404, "absent")
            with open(f, encoding="utf-8") as fh:
                return self._send(200, fh.read())
        self._send(404, "?")

    def do_POST(self):
        u = urlparse(self.path)
        q = parse_qs(u.query)
        if u.path == "/doc" and "f" in q:
            name = q["f"][0]
            if not name.endswith(".md") or "/" in name or "\\" in name or ".." in name:
                return self._send(400, "nom invalide")
            n = int(self.headers.get("Content-Length", 0))
            d = os.path.join(ROOT, "..", "docs")
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, name), "w", encoding="utf-8", newline="\n") as fh:
                fh.write(self.rfile.read(n).decode("utf-8"))
            return self._send(200, "ok")
        if u.path != "/file" or "p" not in q:
            return self._send(404, "?")
        cls = q.get("c", ["ModuleScript"])[0]
        try:
            f = studio_to_file(q["p"][0], cls)
        except ValueError as e:
            return self._send(400, str(e))
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n).decode("utf-8")
        old = find_file(q["p"][0])
        if old and old != f:
            os.remove(old)
        os.makedirs(os.path.dirname(f), exist_ok=True)
        with open(f, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(body)
        self._send(200, "ok")

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 34873
    print(f"sync prêt : http://127.0.0.1:{port}  ({ROOT})", flush=True)
    ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
