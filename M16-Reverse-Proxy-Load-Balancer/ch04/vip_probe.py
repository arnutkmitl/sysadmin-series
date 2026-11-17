"""vip_probe.py SECONDS LOGFILE : ยิง https://web.lab.test ที่ VIP ทุก 0.2 วินาที (timeout 1 วินาที)
บันทึกเวลา ผล เครื่อง proxy และหลังบ้านที่ตอบ ใช้บน Host PC: python vip_probe.py 40 probe.txt
"""
import http.client, ssl, sys, time, socket
CA = "lab-root.pem"   # root ของ Pebble ที่คัดลอกมาจาก lb1
ctx = ssl.create_default_context(cafile=CA)
end = time.time() + float(sys.argv[1]); out = open(sys.argv[2], "w", encoding="utf-8")
t0 = time.time()
while time.time() < end:
    s = time.time()
    try:
        c = http.client.HTTPSConnection("192.168.56.75", 443, timeout=1, context=ctx)
        c.sock = ctx.wrap_socket(socket.create_connection(("192.168.56.75", 443), timeout=1), server_hostname="web.lab.test")
        c.request("GET", "/", headers={"Host": "web.lab.test"}); r = c.getresponse(); r.read()
        line = f"{s - t0:6.1f} {r.status} {r.getheader('X-LB')} {r.getheader('X-Backend')}"
    except Exception as e:
        line = f"{s - t0:6.1f} ERR {type(e).__name__}"
    out.write(line + "\n"); out.flush()
    time.sleep(max(0, 0.2 - (time.time() - s)))
