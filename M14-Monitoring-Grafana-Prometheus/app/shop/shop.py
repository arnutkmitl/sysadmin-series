"""แอปตัวอย่าง shop พร้อม Custom Exporter (M14 บทที่ 4)

เปิดสองพอร์ต: 8000 คือหน้าเว็บของแอป และ 8001 คือ /metrics ให้ Prometheus อ่าน
"""
import random
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from prometheus_client import Counter, Gauge, Histogram, start_http_server

ORDERS = Counter("shop_orders_total", "จำนวนคำสั่งซื้อ", ["status"])
CART = Gauge("shop_active_carts", "จำนวนตะกร้าที่ยังไม่ชำระเงิน")
LATENCY = Histogram("shop_request_duration_seconds", "เวลาตอบสนองของแต่ละ Request",
                    buckets=(0.05, 0.1, 0.25, 0.5, 1, 2.5))


class Shop(BaseHTTPRequestHandler):
    def do_GET(self):
        start = time.perf_counter()
        time.sleep(random.uniform(0.01, 0.3))          # จำลองเวลาประมวลผล
        if self.path == "/order":
            ok = random.random() > 0.05                # ล้มเหลวประมาณ 5%
            ORDERS.labels(status="ok" if ok else "failed").inc()
            code = 200 if ok else 500
        else:
            code = 200
        CART.set(random.randint(0, 20))
        self.send_response(code)
        self.end_headers()
        self.wfile.write(b"shop\n")
        LATENCY.observe(time.perf_counter() - start)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    start_http_server(8001)
    ThreadingHTTPServer(("0.0.0.0", 8000), Shop).serve_forever()
