const mongoose = require('mongoose');

const ReportSchema = new mongoose.Schema({
  reporterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
  reason: { type: String, required: true, trim: true, maxlength: 120 },
  details: { type: String, trim: true, maxlength: 1500, default: '' },
  status: { type: String, enum: ['open', 'reviewing', 'resolved'], default: 'open' }
}, { timestamps: true });

ReportSchema.index({ reporterId: 1, jobId: 1 }, { unique: true });
module.exports = mongoose.model('Report', ReportSchema);
