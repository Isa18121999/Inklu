const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const Candidate = require("../models/Candidate");
const { requireAuth, requireRole } = require("../middleware/auth");
const { removeLocalCv } = require("../storage/cvStorage");
const { parseCv } = require("../services/cvParser");

const uploadDirectory = path.join(__dirname, "..", "..", "uploads", "cv");
fs.mkdirSync(uploadDirectory, { recursive: true });

const storage = multer.diskStorage({
  destination: uploadDirectory,
  filename: (req, file, cb) => {
    const extension = path.extname(file.originalname).toLowerCase();
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${extension}`);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024,
    files: 1,
    fields: 0,
    parts: 1,
    fieldNameSize: 100,
    fieldSize: 64 * 1024,
    headerPairs: 200,
    fieldNestingDepth: 5,
    fieldArrayIndexLimit: 20
  },
  preservePath: false,
  fileFilter: (req, file, cb) => {
    const allowed = {
      ".pdf": ["application/pdf"],
      ".doc": ["application/msword", "application/octet-stream"],
      ".docx": ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/octet-stream"]
    };
    const ext = path.extname(file.originalname).toLowerCase();
    const expectedMimeTypes = allowed[ext];
    if (!expectedMimeTypes || (file.mimetype && !expectedMimeTypes.includes(file.mimetype))) {
      return cb(Object.assign(new Error("Tipo de archivo no permitido"), { code: "INVALID_FILE_TYPE" }), false);
    }
    return cb(null, true);
  }
});

const validateCvSignature = async (filePath, extension) => {
  const handle = await fs.promises.open(filePath, "r");
  try {
    const header = Buffer.alloc(8);
    await handle.read(header, 0, 8, 0);

    if (extension === ".pdf") {
      return header.subarray(0, 5).toString("ascii") === "%PDF-";
    }

    const isOle = header.equals(Buffer.from([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]));
    if (extension === ".doc") return isOle;

    if (extension === ".docx") {
      if (header[0] !== 0x50 || header[1] !== 0x4B || header[2] !== 0x03 || header[3] !== 0x04) return false;
      const content = await fs.promises.readFile(filePath);
      return content.includes(Buffer.from("[Content_Types].xml")) && content.includes(Buffer.from("word/document.xml"));
    }

    return false;
  } finally {
    await handle.close();
  }
};

router.get("/me", requireAuth, requireRole("candidate"), async (req, res) => {
  try {
    const candidate = await Candidate.findOne({ userId: req.user.id }).select("cvUrl");
    if (!candidate) return res.status(404).json({ message: "Candidato no encontrado" });
    if (!candidate.cvUrl) return res.json({ hasCv: false });
    return res.json({ hasCv: true, fileName: path.basename(candidate.cvUrl) });
  } catch (error) {
    return res.status(500).json({ message: "Error obteniendo el CV" });
  }
});

router.post("/me", requireAuth, requireRole("candidate"), upload.single("cv"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: "CV requerido" });

    const extension = path.extname(req.file.originalname).toLowerCase();
    const validSignature = await validateCvSignature(req.file.path, extension);
    if (!validSignature) {
      await fs.promises.unlink(req.file.path).catch(() => {});
      return res.status(400).json({ message: "El contenido del archivo no coincide con el formato declarado" });
    }

    const candidate = await Candidate.findOne({ userId: req.user.id });

    if (!candidate) {
      fs.unlink(req.file.path, () => {});
      return res.status(404).json({ message: "Candidato no encontrado" });
    }

    let extraction = { extracted: false, textLength: 0, profile: {} };
    try {
      extraction = parseCv(req.file.path);
    } catch (parseError) {
      console.warn("No se pudo extraer el perfil del CV:", parseError.message);
    }

    removeLocalCv(candidate.cvUrl);
    candidate.cvUrl = `/uploads/cv/${req.file.filename}`;

    const profile = extraction.profile || {};
    if (profile.experience !== undefined) candidate.experience = profile.experience;
    if (profile.education) candidate.education = profile.education;
    if (profile.modality) candidate.modality = profile.modality;
    if (profile.skills?.length) candidate.skills = profile.skills;
    if (profile.accessibility?.length) candidate.accessibility = profile.accessibility;

    await candidate.save();

    res.json({
      message: "CV actualizado",
      extracted: extraction.extracted,
      extractedFields: Object.keys(profile),
      candidate
    });
  } catch (error) {
    if (req.file?.path) fs.unlink(req.file.path, () => {});
    console.error("CV upload error", error.message);
    res.status(500).json({ message: "Error procesando el CV" });
  }
});

router.get("/application/:applicationId", requireAuth, requireRole("company"), async (req, res) => {
  try {
    const Application = require("../models/Application");
    const Job = require("../models/Job");
    const Company = require("../models/Company");

    const application = await Application.findById(req.params.applicationId);
    if (!application) return res.status(404).json({ message: "Postulación no encontrada" });

    const job = await Job.findById(application.jobId);
    if (!job) return res.status(404).json({ message: "Oferta no encontrada" });

    const company = await Company.findOne({ userId: req.user.id });
    if (!company || job.companyId.toString() !== company._id.toString()) {
      return res.status(403).json({ message: "No puedes acceder al CV de esta postulación" });
    }

    const candidate = await Candidate.findById(application.candidateId).select("cvUrl");
    if (!candidate?.cvUrl || !candidate.cvUrl.startsWith("/uploads/cv/")) {
      return res.status(404).json({ message: "El candidato no tiene un CV disponible" });
    }

    const filename = path.basename(candidate.cvUrl);
    const filePath = path.join(uploadDirectory, filename);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ message: "El archivo CV no está disponible" });
    }

    return res.sendFile(filePath, {
      headers: {
        "Content-Disposition": "inline; filename=\"" + filename + "\""
      }
    });
  } catch (error) {
    return res.status(500).json({ message: "Error accediendo al CV" });
  }
});

module.exports = router;
