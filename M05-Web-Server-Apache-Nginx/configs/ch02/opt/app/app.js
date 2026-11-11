// /opt/app/app.js แอปตัวอย่างที่ฟังเฉพาะ 127.0.0.1:3000 ให้ Nginx เป็นด่านหน้า
const http = require("http");
http.createServer((req, res) => {
  res.setHeader("Content-Type", "application/json");
  res.end(JSON.stringify({
    app: "demo",
    path: req.url,
    client: req.headers["x-real-ip"] || req.socket.remoteAddress,
    forwarded_for: req.headers["x-forwarded-for"] || null,
    proto: req.headers["x-forwarded-proto"] || "http",
  }) + "\n");
}).listen(3000, "127.0.0.1", () => console.log("listening on 127.0.0.1:3000"));
