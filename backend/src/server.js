const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const mongoose = require("mongoose");
require("dotenv").config();

const connectDatabase = require("./config/database");
const applicationRoutes = require("./routes/applicationRoutes");
const authRoutes = require("./routes/authRoutes");
const companyRoutes = require("./routes/companyRoutes");
const cvRoutes = require("./routes/cvRoutes");
const profileRoutes = require("./routes/profileRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const messageRoutes = require("./routes/messageRoutes");

const app = express();
app.disable("x-powered-by");
app.use((_req, res, next) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  next();
});
const uploadsDirectory = path.join(__dirname, "..", "uploads");
fs.mkdirSync(path.join(uploadsDirectory, "cv"), { recursive: true });

const allowedOrigins = process.env.CORS_ORIGIN?.split(",").map((origin) => origin.trim()).filter(Boolean);
app.use(cors({ origin: allowedOrigins?.length ? allowedOrigins : false }));
app.use(express.json({ limit: "1mb" }));

app.use("/api/applications", applicationRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/company", companyRoutes);
app.use("/api/cv", cvRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/messages", messageRoutes);

app.get("/", (_req, res) => {
  res.json({ name: "Inklu API", status: "running" });
});

app.get("/health", (_req, res) => {
  const databaseConnected = mongoose.connection.readyState === 1;
  res.status(databaseConnected ? 200 : 503).json({ status: databaseConnected ? "ok" : "degraded", database: databaseConnected ? "connected" : "disconnected" });
});

app.use((error, _req, res, _next) => {
  if (error.code?.startsWith("LIMIT_") || error.code === "INVALID_FILE_TYPE") return res.status(400).json({ message: error.message || "Solicitud de archivo no válida" });
  console.error("Unhandled request error", error);
  res.status(500).json({ message: "Error interno del servidor" });
});

const PORT = process.env.PORT || 3000;
const startServer = async () => {
  try {
    if (!process.env.JWT_SECRET) throw new Error("JWT_SECRET is required");
    await connectDatabase();
    app.listen(PORT, () => console.log(`Inklu API running on ${PORT}`));
  } catch (error) {
    console.error("Unable to start Inklu API", error.message);
    process.exit(1);
  }
};
startServer();
