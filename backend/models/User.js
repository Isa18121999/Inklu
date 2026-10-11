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

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  phone: { type: String, trim: true },
  passwordHash: { type: String, required: true },
  role: { type: String, enum: ['candidate', 'company'], required: true },
  country: { type: String, default: 'PE' },
  ruc: { type: String, trim: true },
  // Obligatorio y único para candidatos. No se usa para empresas.
  conadisNumber: { type: String, trim: true, default: null },
  accreditationType: { type: String, trim: true, default: 'Carné CONADIS' },
  profile: { type: CandidateProfileSchema, default: () => ({}) }
}, { timestamps: true });

// Permite muchos documentos sin CONADIS solo para registros que no sean candidatos.
// Los candidatos deben llegar a la ruta de registro con un número válido.
UserSchema.index(
  { conadisNumber: 1 },
  { unique: true, partialFilterExpression: { conadisNumber: { $type: 'string' } } }
);

module.exports = mongoose.model('User', UserSchema);
