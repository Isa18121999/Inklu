const mongoose = require("mongoose");

const MessageSchema = new mongoose.Schema({
  applicationId: { type: mongoose.Schema.Types.ObjectId, ref: "Application", required: true, index: true },
  senderUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  recipientUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  text: { type: String, required: true, trim: true, maxlength: 2000 },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

MessageSchema.index({ applicationId: 1, createdAt: 1 });

module.exports = mongoose.model("Message", MessageSchema);
