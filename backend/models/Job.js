const mongoose = require('mongoose');

const JobAccessibilitySchema = new mongoose.Schema({
  remote: { type: Boolean, default: false },
  hybrid: { type: Boolean, default: false },
  physicalAccess: { type: Boolean, default: false },
  flexibleSchedule: { type: Boolean, default: false },
  workplaceAdaptation: { type: Boolean, default: false },
  assistiveTechnology: { type: Boolean, default: false },
  accessibleRestroom: { type: Boolean, default: false },
  elevator: { type: Boolean, default: false },
  accessibleParking: { type: Boolean, default: false },
  transportationSupport: { type: Boolean, default: false },
  interpreter: { type: Boolean, default: false },
  notes: { type: String, trim: true, maxlength: 1200, default: '' }
}, { _id: false });

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
  preferredSkills: { type: [String], default: [] },
  accessibilityDetails: { type: String, trim: true, maxlength: 1200, default: '' },
  accessibility: { type: JobAccessibilitySchema, default: () => ({}) },
  experienceRequired: { type: Number, min: 0, default: 0 },
  active: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Job', JobSchema);
