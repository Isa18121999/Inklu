function getApplicationMessageReceiver(senderId, candidateId, companyId) {
  const sender = String(senderId);
  if (sender === String(candidateId)) return companyId;
  if (sender === String(companyId)) return candidateId;
  return null;
}

function buildApplicationMessageNotification({ receiverId, applicationId, senderName, jobTitle }) {
  const safeSender = String(senderName || 'La otra persona').trim().slice(0, 100);
  const safeJobTitle = String(jobTitle || 'tu postulación').trim().slice(0, 160);
  return {
    userId: receiverId,
    title: 'Nuevo mensaje de postulación',
    message: `${safeSender} te envió un mensaje sobre “${safeJobTitle}”.`,
    type: 'application_message',
    relatedId: applicationId
  };
}

module.exports = { getApplicationMessageReceiver, buildApplicationMessageNotification };
