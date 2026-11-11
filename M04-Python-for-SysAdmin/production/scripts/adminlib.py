# adminlib.py ส่วนกลางของ Script ในบทที่ 6: ค่าตั้ง, logging, สถานะ และอีเมล HTML
import json
import logging
import os
import smtplib
from email.message import EmailMessage
from pathlib import Path
import yaml
from notify import notify  # noqa: F401  ให้ Script import notify จาก adminlib ได้

BASE = Path(__file__).resolve().parent.parent          # ~/python-admin

def own(path):
    """ถ้ารันด้วย sudo ให้ไฟล์เป็นของเจ้าของโฟลเดอร์ python-admin รอบที่รันด้วยผู้ใช้ปกติจะเขียนต่อได้"""
    if os.geteuid() == 0 and Path(path).exists():
        os.chown(path, BASE.stat().st_uid, BASE.stat().st_gid)
    return path

def load_config(name):
    """อ่าน configs/<name> เป็น dictionary"""
    return yaml.safe_load((BASE / "configs" / name).read_text())

def get_logger(name):
    """logger ที่เขียนลง logs/admin-toolkit.log ไฟล์เดียวทั้งชุด"""
    (BASE / "logs").mkdir(exist_ok=True)
    logfile = BASE / "logs" / "admin-toolkit.log"
    logfile.touch()
    own(logfile)
    logging.basicConfig(filename=logfile,
                        format="[%(asctime)s] [%(name)s] [%(levelname)s] %(message)s",
                        datefmt="%Y-%m-%d %H:%M:%S", level=logging.INFO)
    return logging.getLogger(name)

def changed(key, value):
    """จำค่าล่าสุดของ key ใน logs/state.json คืน True เมื่อค่าเปลี่ยนจากรอบก่อน
    รอบแรกที่ยังไม่มีค่าเดิมและค่าเป็น OK ไม่นับว่าเปลี่ยน จะได้ไม่แจ้งว่ากลับมาปกติทั้งที่ไม่เคยพัง"""
    path = BASE / "logs" / "state.json"
    state = json.loads(path.read_text()) if path.exists() else {}
    old = state.get(key, "OK")
    state[key] = value
    path.write_text(json.dumps(state, indent=2))
    own(path)
    return old != value

def send_html_email(subject, html):
    """ส่งรายงาน HTML ด้วยค่า email ใน alert-config.yaml คืน False ถ้าไม่ได้ตั้งค่า"""
    cfg = (load_config("alert-config.yaml") or {}).get("email") or {}
    if not cfg.get("host"):
        return False
    msg = EmailMessage()
    msg["Subject"], msg["From"], msg["To"] = subject, cfg["user"], cfg["to"]
    msg.set_content("รายงานนี้เป็น HTML กรุณาเปิดด้วยโปรแกรมอีเมลที่แสดง HTML ได้")
    msg.add_alternative(html, subtype="html")
    with smtplib.SMTP(cfg["host"], cfg["port"], timeout=15) as s:
        s.starttls()
        s.login(cfg["user"], cfg["password"])
        s.send_message(msg)
    return True
