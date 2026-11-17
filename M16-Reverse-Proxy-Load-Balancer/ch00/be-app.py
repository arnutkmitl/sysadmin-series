#!/usr/bin/env python3
# /usr/local/bin/be-app.py
# แอปหลังบ้านของ Lab M16: ตอบชื่อเครื่องและ header ที่ proxy ส่งมา ใช้ทดสอบการกระจายโหลด
#   /          ชื่อเครื่อง, IP ที่เชื่อมต่อเข้ามา และ header ที่เกี่ยวกับ proxy
#   /health    ตอบ ok (ปิดได้ด้วยการสร้างไฟล์ /etc/be-app/down)
#   /slow?s=N  รอ N วินาทีก่อนตอบ ใช้จำลอง timeout
#   /error     ตอบ 500
import json
import os
import socket
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

PORT = int(os.environ.get("BE_PORT", "8080"))
NAME = os.environ.get("BE_NAME", socket.gethostname().split(".")[0])
SHOW = ("Host", "X-Real-IP", "X-Forwarded-For", "X-Forwarded-Proto", "X-Forwarded-Host", "Via")


class Handler(BaseHTTPRequestHandler):
    server_version = "be-app/1.0"

    def reply(self, code, body, ctype="text/plain; charset=utf-8"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("X-Backend", NAME)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        url = urlparse(self.path)
        if url.path == "/health":
            if os.path.exists("/etc/be-app/down"):
                return self.reply(503, "down\n")
            return self.reply(200, "ok\n")
        if url.path == "/slow":
            time.sleep(float(parse_qs(url.query).get("s", ["5"])[0]))
        if url.path == "/error":
            return self.reply(500, f"error from {NAME}\n")
        info = {"backend": NAME, "client": self.client_address[0], "path": self.path,
                "headers": {h: self.headers[h] for h in SHOW if self.headers[h]}}
        if "json" in self.headers.get("Accept", ""):
            return self.reply(200, json.dumps(info, ensure_ascii=False) + "\n", "application/json")
        lines = [f"backend: {NAME}", f"client: {self.client_address[0]}", f"path: {self.path}"]
        lines += [f"{k}: {v}" for k, v in info["headers"].items()]
        return self.reply(200, "\n".join(lines) + "\n")

    def log_message(self, fmt, *args):
        print(f"{self.client_address[0]} {fmt % args}", flush=True)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
