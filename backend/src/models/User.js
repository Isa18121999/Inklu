const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  phone: { type: String, trim: true, match: /^\d{7,15}$/ },
  password: { type: String, default: "" },
  role: {
    type: String,
    enum: ["candidate", "company", "admin"],
    default: "candidate"
  },
  active: { type: Boolean, default: true },
  authProvider: { type: String, enum: ["password", "google"], default: "password" },
  googleSub: { type: String, trim: true, index: true, sparse: true },
  resetPasswordTokenHash: { type: String, trim: true, index: true, sparse: true },
  resetPasswordExpiresAt: { type: Date }
}, { timestamps: true });

module.exports = mongoose.model("User", UserSchema);
