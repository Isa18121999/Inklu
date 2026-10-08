const mongoose = require("mongoose");

const CompanySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true },
  name: { type: String, required: true, trim: true },
  ruc: { type: String, trim: true, match: /^\d{11}$/ },
  email: { type: String, required: true, lowercase: true, trim: true },
  phone: { type: String, required: true, trim: true, match: /^\d{7,15}$/ },
  sector: { type: String, trim: true, default: "" },
  country: { type: String, default: "PE" },
  description: { type: String, default: "" },
  verified: { type: Boolean, default: false },
  inclusionPolicy: { type: String, default: "" },
  accessibilityOptions: { type: [String], default: [] }
}, { timestamps: true });

module.exports = mongoose.model("Company", CompanySchema);
