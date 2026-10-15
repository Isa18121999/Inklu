const mongoose = require('mongoose');

const APPLICATION_STATUSES = [
  'Postulado',
  'CV visto',
  'En proceso',
  'Aceptado',
  'Proceso terminado',
  'Retirada por candidato',
  // Compatibilidad con postulaciones creadas antes del nuevo flujo.
  'Postulada',
  'En revisión',
  'Entrevista',
  'Seleccionada',
  'No seleccionada'
];

const ApplicationStatusHistorySchema = new mongoose.Schema({
  status: { type: String, enum: APPLICATION_STATUSES, required: true },
  changedAt: { type: Date, default: Date.now },
  changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { _id: false });

const ApplicationSchema = new mongoose.Schema({
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
  candidateId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: APPLICATION_STATUSES, default: 'Postulado' },
  statusHistory: { type: [ApplicationStatusHistorySchema], default: [] }
}, { timestamps: true });

ApplicationSchema.index({ jobId: 1, candidateId: 1 }, { unique: true });

module.exports = mongoose.model('Application', ApplicationSchema);
