const mongoose = require("mongoose");

const MODALITIES = ["remoto", "híbrido", "hibrido", "presencial"];
const CONTRACT_TYPES = ["tiempo completo", "medio tiempo", "temporal", "prácticas", "freelance"];

const JobSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true, minlength: 2, maxlength: 300 },
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: "Company", required: true },
  area: { type: String, required: true, trim: true, minlength: 2, maxlength: 300 },
  profession: { type: String, trim: true, maxlength: 200, default: "" },
  skills: { type: [String], default: [] },
  modality: { type: String, trim: true, enum: MODALITIES },
  contractType: { type: String, trim: true, enum: CONTRACT_TYPES },
  experienceRequired: { type: Number, min: 0, max: 60, default: 0 },
  educationRequired: { type: String, trim: true, maxlength: 300, default: "" },
  salaryMin: { type: Number, min: 0, max: 1000000 },
  salaryMax: { type: Number, min: 0, max: 1000000 },
  requirements: {
    type: [String],
    default: [],
    validate: [
      { validator: (items) => items.length <= 30, message: "No puede haber más de 30 requisitos" },
      { validator: (items) => items.every((item) => String(item).trim().length >= 1 && String(item).trim().length <= 100), message: "Cada requisito debe tener entre 1 y 100 caracteres" }
    ]
  },
  accessibility: {
    type: [String],
    default: [],
    validate: [
      { validator: (items) => items.length <= 30, message: "No puede haber más de 30 requisitos de accesibilidad" },
      { validator: (items) => items.every((item) => String(item).trim().length >= 1 && String(item).trim().length <= 100), message: "Cada requisito de accesibilidad debe tener entre 1 y 100 caracteres" }
    ]
  },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Job", JobSchema);
