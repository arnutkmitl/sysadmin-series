import express from "express";
import mysql from "mysql2/promise";
import { createClient } from "redis";

const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  connectionLimit: 5,
});
const cache = createClient({
  url: `redis://${process.env.REDIS_HOST}:6379`,
  disableOfflineQueue: true, // Redis หลุดแล้วตอบ error ทันที ไม่รอคิว
});
// ไม่ดัก error แล้ว Node.js จะปิดตัวเองทันทีที่ Redis หลุด
cache.on("error", (err) => console.error("redis:", err.message));

const app = express();
app.use(express.json());

app.get("/", async (_req, res) => {
  const visits = await cache.incr("visits");
  res.json({ app: "capstone", version: process.env.APP_VERSION ?? "dev", visits });
});

app.get("/notes", async (_req, res) => {
  const [rows] = await db.query("SELECT id, body, created_at FROM notes ORDER BY id");
  res.json(rows);
});

app.post("/notes", async (req, res) => {
  const body = String(req.body?.body ?? "").slice(0, 200);
  if (!body) {
    res.status(400).json({ error: "body is required" });
    return;
  }
  const [result] = await db.execute("INSERT INTO notes (body) VALUES (?)", [body]);
  res.status(201).json({ id: (result as mysql.ResultSetHeader).insertId, body });
});

app.get("/health", async (_req, res) => {
  try {
    await db.query("SELECT 1");
    await cache.ping();
    res.send("ok");
  } catch (err) {
    res.status(503).send(`not ready: ${(err as Error).message}`);
  }
});

cache.connect().then(() => {
  app.listen(3000, () => console.log("capstone listening on 3000"));
});
