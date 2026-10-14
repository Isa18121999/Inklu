const mongoose = require('mongoose');

const JobSchema = new mongoose.Schema({
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true, trim: true },
  description: { type: String, required: true, trim: true },
  category: { type: String, trim: true, default: '' },
  modality: { type: String, trim: true },
  location: { type: String, trim: true },
  contractType: { type: String, trim: true },
  salary: { type: String, trim: true },
  requiredSkills: { type: [String], default: [] },
  accessibilityDetails: { type: String, trim: true, maxlength: 1200, default: '' },
  experienceRequired: { type: Number, min: 0, default: 0 },
  active: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Job', JobSchema);
