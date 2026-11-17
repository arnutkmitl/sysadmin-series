# check_sni.py  ต่อ lb1:443 ด้วย SNI ทีละโดเมน แล้วพิมพ์ subject, issuer, วันหมดอายุ และรุ่น TLS
# ใช้บน Host PC: python check_sni.py  (lab-root.pem อยู่โฟลเดอร์เดียวกัน)
import socket, ssl
ctx = ssl.create_default_context(cafile="lab-root.pem")
for d in ["web.lab.test", "api.lab.test"]:
    with socket.create_connection(("192.168.56.71", 443)) as s, ctx.wrap_socket(s, server_hostname=d) as t:
        c = t.getpeercert()
        print(d, "->", dict(x[0] for x in c["subject"]), "issuer", dict(x[0] for x in c["issuer"])["commonName"], "until", c["notAfter"], t.version())
