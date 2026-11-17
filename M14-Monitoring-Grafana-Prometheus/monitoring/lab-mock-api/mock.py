"""ปลายทางจำลองของ Telegram และ LINE สำหรับ Lab (ไม่ใช้ในงานจริง)
รับทุก POST แล้วพิมพ์ path และ body ลง log ตอบ {"ok": true}
"""
import json
from http.server import BaseHTTPRequestHandler, HTTPServer


class H(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode("utf-8", "replace")
        path = self.path.split("/bot")[0] + "/bot<TOKEN>/" + self.path.split("/")[-1] if "/bot" in self.path and "sendMessage" in self.path else self.path
        auth = "Bearer ***" if self.headers.get("Authorization") else "-"
        print(json.dumps({"path": path, "auth": auth, "body": body}, ensure_ascii=False), flush=True)
        if "sendMessage" in self.path:  # ตอบรูปแบบเดียวกับ Telegram Bot API จริง
            import time
            req = json.loads(body) if body.startswith("{") else {}
            out = json.dumps({"ok": True, "result": {
                "message_id": 1, "date": int(time.time()),
                "chat": {"id": int(req.get("chat_id", 0)), "type": "private"},
                "from": {"id": 1, "is_bot": True, "first_name": "lab"},
                "text": req.get("text", "")}}).encode()
        else:
            out = b'{"sentMessages":[{"id":"1","quoteToken":"lab"}]}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)

    def log_message(self, *a):
        pass


HTTPServer(("0.0.0.0", 8080), H).serve_forever()
