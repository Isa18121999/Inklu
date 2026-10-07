const express = require("express");
const mongoose = require("mongoose");
const Message = require("../models/Message");
const Application = require("../models/Application");
const Candidate = require("../models/Candidate");
const Company = require("../models/Company");
const Notification = require("../models/Notification");
const { requireAuth } = require("../middleware/auth");

const router = express.Router();

const getConversationContext = async (applicationId) => {
  if (!mongoose.isValidObjectId(applicationId)) return null;
  const application = await Application.findById(applicationId).populate("jobId", "companyId title");
  if (!application?.jobId) return null;
  const candidate = await Candidate.findById(application.candidateId).select("userId");
  const company = await Company.findById(application.jobId.companyId).select("userId name");
  if (!candidate || !company) return null;
  return { application, candidateUserId: String(candidate.userId), companyUserId: String(company.userId), companyName: company.name };
};

const authorizeParticipant = (context, userId) => context && (context.candidateUserId === String(userId) || context.companyUserId === String(userId));

router.get("/:applicationId", requireAuth, async (req, res) => {
  try {
    const context = await getConversationContext(req.params.applicationId);
    if (!context) return res.status(404).json({ message: "Postulación no encontrada" });
    if (!authorizeParticipant(context, req.user.id)) return res.status(403).json({ message: "No tienes acceso a este chat" });
    const messages = await Message.find({ applicationId: context.application._id }).sort({ createdAt: 1 }).limit(200).lean();
    await Message.updateMany({ applicationId: context.application._id, recipientUserId: req.user.id, read: false }, { $set: { read: true } });
    return res.json({ messages, companyName: context.companyName, applicationId: context.application._id });
  } catch (error) {
    console.error("Message list error", error.message);
    return res.status(500).json({ message: "Error obteniendo mensajes" });
  }
});

router.post("/:applicationId", requireAuth, async (req, res) => {
  try {
    const context = await getConversationContext(req.params.applicationId);
    if (!context) return res.status(404).json({ message: "Postulación no encontrada" });
    if (!authorizeParticipant(context, req.user.id)) return res.status(403).json({ message: "No tienes acceso a este chat" });
    const text = String(req.body?.text || "").trim();
    if (!text || text.length > 2000) return res.status(400).json({ message: "El mensaje debe tener entre 1 y 2000 caracteres" });
    const recipientUserId = context.candidateUserId === String(req.user.id) ? context.companyUserId : context.candidateUserId;
    const message = await Message.create({ applicationId: context.application._id, senderUserId: req.user.id, recipientUserId, text });
    await Notification.create({ userId: recipientUserId, type: "chat", title: "Nuevo mensaje", message: `Tienes un nuevo mensaje sobre ${context.application.jobId.title}.` });
    return res.status(201).json({ message });
  } catch (error) {
    console.error("Message send error", error.message);
    return res.status(500).json({ message: "Error enviando mensaje" });
  }
});

module.exports = router;
