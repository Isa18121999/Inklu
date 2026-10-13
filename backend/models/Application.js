const mongoose = require('mongoose');

const APPLICATION_STATUSES = [
  'Postulado',
  'CV visto',
  'En proceso',
  'Aceptado',
  'Proceso terminado',
  // Compatibilidad con registros creados por versiones anteriores.
  'Postulada',
  'En revisión',
  'Entrevista',
  'Seleccionada',
  'No seleccionada'
];

const ApplicationSchema = new mongoose.Schema({
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
  candidateId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: APPLICATION_STATUSES, default: 'Postulado' }
}, { timestamps: true });

ApplicationSchema.index({ jobId: 1, candidateId: 1 }, { unique: true });

module.exports = mongoose.model('Application', ApplicationSchema);
