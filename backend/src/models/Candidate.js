const mongoose = require("mongoose");

const CandidateSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true },
  name: { type: String, required: true, match: /^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:[ '\-][A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$/ },
  email: { type: String, required: true, lowercase: true, trim: true },
  phone: { type: String, required: true, trim: true, match: /^\d{7,15}$/ },
  country: { type: String, enum: ["PE"], default: "PE" },
  candidateType: { type: String, enum: ["CONADIS", "Voluntario"], default: "CONADIS" },
  accreditationType: { type: String, enum: ["Carné CONADIS"], default: undefined },
  accreditationNumber: { type: String, match: /^\d{6}$/ },
  disabilityType: String,
  supportNeeds: { type: [String], default: [] },
  supportOfferings: { type: [String], default: [] },
  professionalTitle: String,
  experience: { type: Number, min: 0, default: 0 },
  skills: { type: [String], default: [] },
  education: String,
  modality: String,
  cvUrl: String,
  accessibility: { type: [String], default: [] },
  favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: "Job" }]
}, { timestamps: true });

module.exports = mongoose.model("Candidate", CandidateSchema);
