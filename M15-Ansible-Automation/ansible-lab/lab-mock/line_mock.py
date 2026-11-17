#!/usr/bin/env python3
# /home/admin/ansible-lab/lab-mock/line_mock.py
# ปลายทางจำลองของ LINE Messaging API สำหรับ Lab: รับ POST /v2/bot/message/push แล้วบันทึก body ลง log
# ใช้แทน api.line.me ระหว่างทดสอบ ห้ามใช้กับระบบจริง
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

LOG = sys.argv[2] if len(sys.argv) > 2 else "/tmp/line-mock.log"


class H(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
        auth = "Bearer ..." if self.headers.get("Authorization", "").startswith("Bearer ") else "ไม่มี"
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(json.dumps({"path": self.path, "auth": auth, "body": json.loads(body or "{}")},
                               ensure_ascii=False) + "\n")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b"{}")

    def log_message(self, *a):
        pass


HTTPServer(("0.0.0.0", int(sys.argv[1]) if len(sys.argv) > 1 else 8099), H).serve_forever()
