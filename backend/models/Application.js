const mongoose = require('mongoose');

const ApplicationSchema = new mongoose.Schema({
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
  candidateId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: ['Postulada', 'En revisión', 'Entrevista', 'Seleccionada', 'No seleccionada'], default: 'Postulada' }
}, { timestamps: true });

ApplicationSchema.index({ jobId: 1, candidateId: 1 }, { unique: true });

module.exports = mongoose.model('Application', ApplicationSchema);
