const express = require("express");
const Candidate = require("../models/Candidate");
const Company = require("../models/Company");
const User = require("../models/User");
const Job = require("../models/Job");
const calculateMatch = require("../services/matchingService");
const { requireAuth } = require("../middleware/auth");
const { validateName, validatePhone } = require("../validation");

const router = express.Router();
const candidateFields = ["name", "professionalTitle", "experience", "skills", "education", "modality", "accessibility", "phone"];
const companyFields = ["name", "sector", "country", "description", "inclusionPolicy", "accessibilityOptions", "phone"];
const pick = (source, fields) => Object.fromEntries(fields.filter((field) => source[field] !== undefined).map((field) => [field, source[field]]));

router.get("/me", requireAuth, async (req, res) => {
  try {
    const Model = req.user.role === "company" ? Company : Candidate;
    const profile = await Model.findOne({ userId: req.user.id });
    if (!profile) return res.status(404).json({ message: "Perfil no encontrado" });
    return res.json(profile);
  } catch (error) { console.error("Profile fetch error", error.message); return res.status(500).json({ message: "Error obteniendo perfil" }); }
});

router.get("/matches", requireAuth, async (req, res) => {
  try {
    if (req.user.role !== "candidate") return res.status(403).json({ message: "Solo los candidatos tienen matches" });
    const candidate = await Candidate.findOne({ userId: req.user.id });
    if (!candidate) return res.status(404).json({ message: "Perfil de candidato no encontrado" });
    const jobs = await Job.find().populate("companyId", "name").sort({ createdAt: -1 });
    const matches = jobs.map((job) => {
      const match = calculateMatch(candidate, job);
      return { ...job.toObject(), score: match.score, breakdown: match.breakdown, matchedSkills: match.matchedSkills, missingSkills: match.missingSkills, matchedAccessibility: match.matchedAccessibility, missingAccessibility: match.missingAccessibility, reasons: match.reasons };
    }).sort((a, b) => b.score - a.score);
    return res.json({ candidateId: candidate._id, matches });
  } catch (error) { console.error("Profile matches error", error.message); return res.status(500).json({ message: "Error obteniendo matches" }); }
});

router.patch("/me", requireAuth, async (req, res) => {
  try {
    const isCompany = req.user.role === "company";
    const Model = isCompany ? Company : Candidate;
    const changes = pick(req.body, isCompany ? companyFields : candidateFields);

    if (!isCompany && changes.name !== undefined) {
      const name = String(changes.name).trim();
      if (!validateName(name) || name.length < 2 || name.length > 100) {
        return res.status(400).json({ message: "El nombre solo puede contener letras, espacios, guiones y apóstrofes" });
      }
      changes.name = name;
    }
    if (changes.phone !== undefined && !validatePhone(changes.phone)) {
      return res.status(400).json({ message: "El teléfono debe contener solo números y tener entre 7 y 15 dígitos" });
    }
    if (changes.professionalTitle !== undefined) {
      const value = String(changes.professionalTitle).trim();
      if (value.length > 120) return res.status(400).json({ message: "El cargo o profesión no puede superar 120 caracteres" });
      changes.professionalTitle = value;
    }
    if (changes.education !== undefined) {
      const value = String(changes.education).trim();
      if (value.length > 200) return res.status(400).json({ message: "La formación académica no puede superar 200 caracteres" });
      changes.education = value;
    }
    if (changes.experience !== undefined) {
      const value = Number(changes.experience);
      if (!Number.isFinite(value) || value < 0 || value > 60) return res.status(400).json({ message: "La experiencia debe ser un número entre 0 y 60 años" });
      changes.experience = value;
    }
    if (changes.skills !== undefined) {
      if (!Array.isArray(changes.skills) || changes.skills.length > 30 || changes.skills.some((item) => typeof item !== "string" || !item.trim() || item.trim().length > 100)) return res.status(400).json({ message: "Las habilidades deben ser una lista válida de hasta 30 elementos" });
      changes.skills = changes.skills.map((item) => item.trim());
    }
    if (changes.accessibility !== undefined) {
      if (!Array.isArray(changes.accessibility) || changes.accessibility.length > 30 || changes.accessibility.some((item) => typeof item !== "string" || !item.trim() || item.trim().length > 100)) return res.status(400).json({ message: "Las necesidades de accesibilidad deben ser una lista válida" });
      changes.accessibility = changes.accessibility.map((item) => item.trim());
    }
    if (changes.modality !== undefined) {
      const modality = String(changes.modality).trim().toLowerCase();
      if (modality && !["remoto", "híbrido", "hibrido", "presencial"].includes(modality)) return res.status(400).json({ message: "La modalidad debe ser remoto, híbrido o presencial" });
      changes.modality = modality;
    }
    if (isCompany) {
      if (changes.name !== undefined) {
        const name = String(changes.name).trim();
        if (name.length < 2 || name.length > 150 || !/[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]/.test(name)) return res.status(400).json({ message: "Ingresa un nombre de empresa válido" });
        changes.name = name;
      }
      for (const field of ["sector", "country", "description", "inclusionPolicy"]) {
        if (changes[field] !== undefined && String(changes[field]).trim().length > 500) return res.status(400).json({ message: `${field} supera el máximo permitido de 500 caracteres` });
      }
      if (changes.accessibilityOptions !== undefined) {
        if (!Array.isArray(changes.accessibilityOptions) || changes.accessibilityOptions.length > 30) return res.status(400).json({ message: "Las opciones de accesibilidad no son válidas" });
        changes.accessibilityOptions = changes.accessibilityOptions.map((item) => String(item).trim()).filter(Boolean);
      }
    }

    const profile = await Model.findOneAndUpdate({ userId: req.user.id }, changes, { new: true, runValidators: true });
    if (!profile) return res.status(404).json({ message: "Perfil no encontrado" });

    const userChanges = {};
    if (changes.name !== undefined) userChanges.name = changes.name;
    if (changes.phone !== undefined) userChanges.phone = changes.phone;
    if (Object.keys(userChanges).length) await User.findByIdAndUpdate(req.user.id, userChanges, { runValidators: true });

    return res.json(profile);
  } catch (error) { console.error("Profile update error", error.message); return res.status(500).json({ message: "Error actualizando perfil" }); }
});

module.exports = router;
