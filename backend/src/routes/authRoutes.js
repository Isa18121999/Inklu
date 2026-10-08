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
    const user = await User.create({ name: normalizedName, email: normalizedEmail, phone: normalizedPhone, password: hashPassword(password), role, active: true });

    let profile;
    if (role === "candidate") {
      profile = await Candidate.create({
        userId: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        country: "PE",
        candidateType: "CONADIS",
        accreditationType: "Carné CONADIS",
        accreditationNumber: normalizedConadis,
        disabilityType: conadisRecord.tipoDiscapacidad
      });
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

module.exports = router;
