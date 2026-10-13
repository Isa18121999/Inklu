const mongoose = require('mongoose');

const CandidateProfileSchema = new mongoose.Schema({
  birth: { type: String, trim: true },
  address: { type: String, trim: true },
  education: { type: String, trim: true },
  experience: { type: Number, min: 0, default: 0 },
  skills: { type: [String], default: [] },
  modality: { type: String, trim: true },
  location: { type: String, trim: true }
}, { _id: false });

const CvSchema = new mongoose.Schema({
  fileName: { type: String, trim: true },
  mimeType: { type: String, trim: true },
  data: { type: Buffer },
  size: { type: Number, min: 0 },
  uploadedAt: { type: Date, default: Date.now }
}, { _id: false });

const CvAnalysisSchema = new mongoose.Schema({
  skills: { type: [String], default: [] },
  keywords: [{
    term: { type: String, required: true },
    count: { type: Number, min: 1, required: true }
  }],
  textLength: { type: Number, default: 0 },
  analyzedAt: { type: Date },
  sourceUploadedAt: { type: Date }
}, { _id: false });

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  phone: { type: String, trim: true },
  passwordHash: { type: String, required: true },
  role: { type: String, enum: ['candidate', 'company'], required: true },
  country: { type: String, default: 'PE' },
  ruc: { type: String, trim: true },
  conadisNumber: { type: String, trim: true, default: null },
  accreditationType: { type: String, trim: true, default: 'Carné CONADIS' },
  profile: { type: CandidateProfileSchema, default: () => ({}) },
  cv: { type: CvSchema, default: undefined },
  cvAnalysis: { type: CvAnalysisSchema, default: undefined }
}, { timestamps: true });

UserSchema.index(
  { conadisNumber: 1 },
  { unique: true, partialFilterExpression: { conadisNumber: { $type: 'string' } } }
);

module.exports = mongoose.model('User', UserSchema);
