# serial.py  อ่าน serial ของใบรับรองที่ VIP ส่งมาสำหรับ web.lab.test (รันบน lb1)
import socket, ssl
ctx = ssl.create_default_context(cafile="/opt/pebble/certs/lab-root.pem")
with ctx.wrap_socket(socket.create_connection(("192.168.56.75", 443)), server_hostname="web.lab.test") as s:
    print(s.getpeercert()["serialNumber"])
