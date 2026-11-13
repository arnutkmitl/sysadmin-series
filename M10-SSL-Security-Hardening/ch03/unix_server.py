# /opt/api/unix_server.py  HTTP server ที่รับคำขอผ่าน unix socket แทน port TCP (หัวข้อ 3.4)
import http.server
import os
import socketserver

SOCK = "/run/api/api.sock"


class Handler(http.server.SimpleHTTPRequestHandler):
    def address_string(self):
        return "unix"


class Server(socketserver.UnixStreamServer):
    def get_request(self):
        req, _ = super().get_request()
        return req, ("unix", 0)


if os.path.exists(SOCK):
    os.unlink(SOCK)
os.chdir("/opt/api")
with Server(SOCK, Handler) as s:
    os.chmod(SOCK, 0o666)
    s.serve_forever()
