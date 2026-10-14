const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  title: { type: String, required: true, trim: true, maxlength: 120 },
  message: { type: String, required: true, trim: true, maxlength: 600 },
  type: { type: String, enum: ['application', 'application_status', 'system'], default: 'system' },
  relatedId: { type: mongoose.Schema.Types.ObjectId, default: null },
  readAt: { type: Date, default: null }
}, { timestamps: true });

NotificationSchema.index({ userId: 1, createdAt: -1 });
module.exports = mongoose.model('Notification', NotificationSchema);
