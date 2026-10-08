const express = require("express");
const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const router = express.Router();
const User = require("../models/User");
const Candidate = require("../models/Candidate");
const Company = require("../models/Company");
const { verifyRui } = require("../services/conadisService");
const { validateName, validateEmail, validatePhone, validatePassword } = require("../validation");

const publicUser = (user) => ({ id: user._id, name: user.name, email: user.email, phone: user.phone, role: user.role, active: user.active });
const issueToken = (user) => jwt.sign({ id: user._id.toString(), role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
const hashPassword = (password, salt = crypto.randomBytes(16).toString("hex")) => { const hash = crypto.scryptSync(password, salt, 64).toString("hex"); return `${salt}:${hash}`; };
const verifyPassword = (password, storedPassword) => { const [salt, storedHash] = String(storedPassword || "").split(":"); if (!salt || !storedHash) return false; const hash = crypto.scryptSync(password, salt, 64).toString("hex"); const expected = Buffer.from(storedHash, "hex"); const actual = Buffer.from(hash, "hex"); return expected.length === actual.length && crypto.timingSafeEqual(expected, actual); };
const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
const mobileRedirect = () => process.env.MOBILE_AUTH_REDIRECT_URI || "inklu://auth/google";
const googleCallback = () => process.env.GOOGLE_REDIRECT_URI || "https://inklu-api.onrender.com/api/auth/google/callback";

async function sendPasswordResetEmail({ to, name, resetUrl }) {
  if (!process.env.RESEND_API_KEY || !process.env.RESEND_FROM_EMAIL) throw new Error("Password reset email service is not configured");
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: process.env.RESEND_FROM_EMAIL,
      to: [to],
      subject: "Restablece tu contraseña de Inklu",
      html: `<div style="font-family:Arial,sans-serif;max-width:560px;margin:auto"><h2>Recupera tu acceso a Inklu</h2><p>Hola ${String(name || "")},</p><p>Recibimos una solicitud para cambiar tu contraseña.</p><p><a href="${resetUrl}" style="display:inline-block;padding:12px 18px;background:#6D28D9;color:#fff;text-decoration:none;border-radius:8px">Restablecer contraseña</a></p><p>Este enlace vence en 30 minutos. Si no solicitaste el cambio, puedes ignorar este correo.</p></div>`
    })
  });
  if (!response.ok) throw new Error(`Resend error ${response.status}: ${await response.text()}`);
}

router.post("/register", async (req, res) => {
  try {
    const { name, email, phone, password, role, country, accreditationType, accreditationNumber, ruc } = req.body;
    const normalizedName = String(name || "").trim();
    const normalizedEmail = String(email || "").trim().toLowerCase();
    const normalizedPhone = String(phone || "").trim();
    const normalizedConadis = String(accreditationNumber || "").trim();
    const normalizedRuc = String(ruc || "").trim();

    if (!normalizedName || !normalizedEmail || !normalizedPhone || !password) return res.status(400).json({ message: "Nombre, email, teléfono y contraseña son obligatorios" });
    if (role === "candidate" && !validateName(normalizedName)) return res.status(400).json({ message: "El nombre solo puede contener letras, espacios, guiones y apóstrofes" });
    if (role === "company" && (normalizedName.length < 2 || normalizedName.length > 150 || !/[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]/.test(normalizedName))) return res.status(400).json({ message: "Ingresa un nombre de empresa válido" });
    if (!validateEmail(normalizedEmail)) return res.status(400).json({ message: "Ingresa un correo electrónico válido" });
    if (!validatePhone(normalizedPhone)) return res.status(400).json({ message: "El teléfono debe contener solo números (7 a 15 dígitos)" });
    if (!validatePassword(password)) return res.status(400).json({ message: "La contraseña debe tener 8 a 128 caracteres e incluir mayúscula, minúscula, número y carácter especial" });
    if (!["candidate", "company"].includes(role)) return res.status(400).json({ message: "Rol no válido" });

    let conadisRecord = null;
    if (role === "candidate") {
      if (String(country || "").trim() !== "PE") return res.status(400).json({ message: "Inklu funciona actualmente en Perú" });
      if (String(accreditationType || "").trim() !== "Carné CONADIS" || !/^\d{6}$/.test(normalizedConadis)) return res.status(400).json({ message: "Registra el RUI de exactamente 6 dígitos numéricos de tu carné CONADIS" });
      conadisRecord = await verifyRui(normalizedConadis);
      if (!conadisRecord.valid) return res.status(422).json({ message: "El RUI no pudo ser validado en el registro CONADIS." });
    } else if (normalizedRuc && !/^\d{11}$/.test(normalizedRuc)) {
      return res.status(400).json({ message: "El RUC debe contener exactamente 11 dígitos" });
    }

    if (await User.findOne({ email: normalizedEmail })) return res.status(409).json({ message: "El email ya está registrado" });
    const user = await User.create({ name: normalizedName, email: normalizedEmail, phone: normalizedPhone, password: hashPassword(password), role, active: true, authProvider: "password" });

    let profile;
    if (role === "candidate") {
      profile = await Candidate.create({ userId: user._id, name: user.name, email: user.email, phone: user.phone, country: "PE", candidateType: "CONADIS", accreditationType: "Carné CONADIS", accreditationNumber: normalizedConadis, disabilityType: conadisRecord.tipoDiscapacidad });
    } else {
      profile = await Company.create({ userId: user._id, name: user.name, email: user.email, phone: user.phone, ruc: normalizedRuc || undefined });
    }

    res.status(201).json({ message: "Registro correcto", user: publicUser(user), token: issueToken(user), profileId: profile._id, ...(role === "candidate" ? { conadisVerified: true, disabilityType: conadisRecord.tipoDiscapacidad } : {}) });
  } catch (error) {
    console.error("Registration error", error.message);
    res.status(500).json({ message: "Error registrando usuario" });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = String(email || "").trim().toLowerCase();
    if (!validateEmail(normalizedEmail) || !password) return res.status(400).json({ message: "Ingresa un correo y contraseña válidos" });
    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !user.active || !verifyPassword(password, user.password)) return res.status(401).json({ message: "Email o contraseña incorrectos" });
    res.json({ message: "Login correcto", user: publicUser(user), token: issueToken(user) });
  } catch (error) {
    console.error("Login error", error.message);
    res.status(500).json({ message: "Error iniciando sesión" });
  }
});

router.get("/google/start", (req, res) => {
  if (!process.env.GOOGLE_CLIENT_ID || !process.env.GOOGLE_CLIENT_SECRET) return res.status(503).send("Google OAuth no está configurado en el backend.");
  const state = jwt.sign({ redirectUri: mobileRedirect() }, process.env.JWT_SECRET, { expiresIn: "10m" });
  const params = new URLSearchParams({ client_id: process.env.GOOGLE_CLIENT_ID, redirect_uri: googleCallback(), response_type: "code", scope: "openid email profile", access_type: "offline", prompt: "select_account", state });
  res.redirect(`https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`);
});

router.get("/google/callback", async (req, res) => {
  try {
    const { code, state, error } = req.query;
    if (error) return res.status(400).send("La autenticación con Google fue cancelada.");
    if (!code || !state) return res.status(400).send("Respuesta de Google incompleta.");
    const statePayload = jwt.verify(state, process.env.JWT_SECRET);
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: new URLSearchParams({ code: String(code), client_id: process.env.GOOGLE_CLIENT_ID, client_secret: process.env.GOOGLE_CLIENT_SECRET, redirect_uri: googleCallback(), grant_type: "authorization_code" }) });
    if (!tokenResponse.ok) throw new Error(`Google token error ${tokenResponse.status}`);
    const googleTokens = await tokenResponse.json();
    const userResponse = await fetch("https://openidconnect.googleapis.com/v1/userinfo", { headers: { Authorization: `Bearer ${googleTokens.access_token}` } });
    if (!userResponse.ok) throw new Error(`Google userinfo error ${userResponse.status}`);
    const googleUser = await userResponse.json();
    if (!googleUser.email || !googleUser.email_verified) return res.status(403).send("Google no entregó un correo verificado.");
    const user = await User.findOne({ email: String(googleUser.email).trim().toLowerCase() });
    if (!user || !user.active) return res.status(404).send("No existe una cuenta Inklu asociada a este correo. Regístrate primero y luego podrás iniciar sesión con Google.");
    if (user.googleSub && user.googleSub !== googleUser.sub) return res.status(409).send("La cuenta de Google no coincide con la cuenta vinculada.");
    user.googleSub = googleUser.sub;
    user.authProvider = "google";
    await user.save();
    const appToken = issueToken(user);
    const redirectUri = statePayload.redirectUri || mobileRedirect();
    const separator = redirectUri.includes("?") ? "&" : "?";
    res.redirect(`${redirectUri}${separator}${new URLSearchParams({ token: appToken, userId: String(user._id), role: user.role }).toString()}`);
  } catch (error) {
    console.error("Google OAuth error", error.message);
    res.status(500).send("No se pudo completar el inicio de sesión con Google.");
  }
});

router.post("/forgot-password", async (req, res) => {
  try {
    const normalizedEmail = String(req.body.email || "").trim().toLowerCase();
    if (!validateEmail(normalizedEmail)) return res.status(400).json({ message: "Ingresa un correo electrónico válido" });
    const user = await User.findOne({ email: normalizedEmail, active: true });
    if (!user) return res.json({ message: "Si existe una cuenta con ese correo, recibirás instrucciones para restablecer tu contraseña." });
    const rawToken = crypto.randomBytes(32).toString("hex");
    user.resetPasswordTokenHash = sha256(rawToken);
    user.resetPasswordExpiresAt = new Date(Date.now() + 30 * 60 * 1000);
    await user.save();
    const base = process.env.PASSWORD_RESET_BASE_URL || "https://inklu-api.onrender.com/api/auth/reset-password";
    const resetUrl = `${base}?token=${encodeURIComponent(rawToken)}`;
    try {
      await sendPasswordResetEmail({ to: user.email, name: user.name, resetUrl });
    } catch (emailError) {
      user.resetPasswordTokenHash = undefined;
      user.resetPasswordExpiresAt = undefined;
      await user.save();
      throw emailError;
    }
    res.json({ message: "Si existe una cuenta con ese correo, recibirás instrucciones para restablecer tu contraseña." });
  } catch (error) {
    console.error("Forgot password error", error.message);
    res.status(503).json({ message: "El servicio de recuperación de contraseña no está disponible en este momento." });
  }
});

router.get("/reset-password", (req, res) => {
  const token = String(req.query.token || "");
  if (!token) return res.status(400).send("Enlace de recuperación inválido.");
  const appUrl = `inklu://reset-password?token=${encodeURIComponent(token)}`;
  res.status(200).send(`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>Inklu</title></head><body style="font-family:Arial,sans-serif;text-align:center;padding:40px"><h2>Restablecer contraseña</h2><p>Abre este enlace desde tu dispositivo para continuar en Inklu.</p><p><a href="${appUrl}" style="display:inline-block;padding:12px 18px;background:#6D28D9;color:#fff;text-decoration:none;border-radius:8px">Abrir Inklu</a></p></body></html>`);
});

router.post("/reset-password", async (req, res) => {
  try {
    const rawToken = String(req.body.token || "");
    const password = String(req.body.password || "");
    if (!rawToken || !validatePassword(password)) return res.status(400).json({ message: "El token y una contraseña válida son obligatorios." });
    const user = await User.findOne({ resetPasswordTokenHash: sha256(rawToken), resetPasswordExpiresAt: { $gt: new Date() }, active: true });
    if (!user) return res.status(400).json({ message: "El enlace de recuperación es inválido o ya venció." });
    user.password = hashPassword(password);
    user.resetPasswordTokenHash = undefined;
    user.resetPasswordExpiresAt = undefined;
    user.authProvider = "password";
    await user.save();
    res.json({ message: "Contraseña actualizada correctamente." });
  } catch (error) {
    console.error("Reset password error", error.message);
    res.status(500).json({ message: "No se pudo actualizar la contraseña." });
  }
});

module.exports = router;
