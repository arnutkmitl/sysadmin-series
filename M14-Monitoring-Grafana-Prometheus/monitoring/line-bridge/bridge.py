"""Webhook bridge: Alertmanager -> LINE Messaging API push message (M14 บทที่ 3)

Alertmanager ส่ง JSON มาที่ POST /alert แล้ว bridge แปลงเป็นข้อความสั้นหนึ่งข้อความ
ส่งต่อด้วย POST https://api.line.me/v2/bot/message/push
ค่าที่ต้องตั้ง (ตัวแปรสภาพแวดล้อม):
  LINE_TOKEN_FILE  ไฟล์ที่เก็บ Channel access token
  LINE_TO          User ID หรือ Group ID ปลายทาง (ขึ้นต้นด้วย U หรือ C)
  LINE_API         (ไม่บังคับ) URL ของ API ใช้เปลี่ยนไปที่ปลายทางจำลองตอนทดสอบ
"""
import json
import os
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

API = os.environ.get("LINE_API", "https://api.line.me/v2/bot/message/push")
TO = os.environ["LINE_TO"]
TOKEN = open(os.environ["LINE_TOKEN_FILE"], encoding="utf-8").read().strip()
ICON = {"firing": "🔥", "resolved": "✅"}


def render(payload):
    lines = []
    for a in payload.get("alerts", [])[:5]:
        lab, ann = a.get("labels", {}), a.get("annotations", {})
        lines.append(f"{ICON.get(a.get('status'), '')} [{a.get('status', '').upper()}] "
                     f"{lab.get('alertname')} ({lab.get('severity', '-')})\n"
                     f"{ann.get('summary', lab.get('instance', ''))}")
    extra = len(payload.get("alerts", [])) - 5
    if extra > 0:
        lines.append(f"... และอีก {extra} รายการ")
    return "\n\n".join(lines)[:4900]  # LINE จำกัดข้อความละ 5000 ตัวอักษร


def push(text):
    body = json.dumps({"to": TO, "messages": [{"type": "text", "text": text}]}).encode()
    req = urllib.request.Request(API, data=body, method="POST", headers={
        "Content-Type": "application/json", "Authorization": f"Bearer {TOKEN}"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return r.status


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/alert":
            self.send_error(404)
            return
        payload = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
        try:
            status = push(render(payload))
            print(f"pushed {len(payload.get('alerts', []))} alert(s) -> LINE status {status}", flush=True)
            self.send_response(200)
        except Exception as e:  # Alertmanager จะส่งซ้ำเองเมื่อได้ 5xx
            print(f"push failed: {e}", flush=True)
            self.send_response(502)
        self.end_headers()

    def log_message(self, *args):
        pass


HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
