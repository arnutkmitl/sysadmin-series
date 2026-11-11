import express from "express";

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.get("/", (_req, res) => {
  res.json({
    app: "hello-docker",
    version: process.env.APP_VERSION ?? "dev",
    host: process.env.HOSTNAME,
  });
});

app.get("/health", (_req, res) => {
  res.send("ok");
});

app.listen(port, () => {
  console.log(`listening on ${port}`);
});
