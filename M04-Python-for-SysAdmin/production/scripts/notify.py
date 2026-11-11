# notify.py ส่งแจ้งเตือนผ่าน LINE Messaging API, Slack webhook และอีเมล
import smtplib
from email.message import EmailMessage
from pathlib import Path
import requests
import yaml

CONFIG = Path(__file__).resolve().parent.parent / "configs" / "alert-config.yaml"
LINE_PUSH = "https://api.line.me/v2/bot/message/push"

def send_line(cfg, text):
    r = requests.post(LINE_PUSH, timeout=10,
                      headers={"Authorization": f"Bearer {cfg['token']}"},
                      json={"to": cfg["to"], "messages": [{"type": "text", "text": text[:5000]}]})
    r.raise_for_status()

def send_slack(cfg, text):
    requests.post(cfg["webhook"], json={"text": text}, timeout=10).raise_for_status()

def send_email(cfg, subject, text):
    msg = EmailMessage()
    msg["Subject"], msg["From"], msg["To"] = subject, cfg["user"], cfg["to"]
    msg.set_content(text)
    with smtplib.SMTP(cfg["host"], cfg["port"], timeout=15) as s:
        s.starttls()
        s.login(cfg["user"], cfg["password"])
        s.send_message(msg)

def notify(subject, text):
    """ส่งทุกช่องทางที่ตั้งค่าไว้ คืน list ของช่องทางที่ส่งไม่สำเร็จ"""
    cfg = yaml.safe_load(CONFIG.read_text()) if CONFIG.exists() else {}
    failed = []
    for name, send in (("line", lambda c: send_line(c, f"{subject}\n{text}")),
                       ("slack", lambda c: send_slack(c, f"*{subject}*\n{text}")),
                       ("email", lambda c: send_email(c, subject, text))):
        c = cfg.get(name) or {}
        if not any(c.values()):
            continue
        try:
            send(c)
        except Exception as e:
            failed.append(f"{name}: {e}")
    return failed
