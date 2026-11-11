#!/usr/bin/env python3
# hello-admin.py ทักทายพร้อมชื่อเครื่องและเวลา
import socket
from datetime import datetime

host = socket.gethostname()
now = datetime.now().strftime("%Y-%m-%d %H:%M")
print(f"Hello {host}, ตอนนี้ {now}")
