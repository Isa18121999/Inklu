function canAccessApplicationConversation(role, userId, candidateId, companyId) {
  if (!role || !userId) return false;
  const id = String(userId);
  if (role === 'candidate') return Boolean(candidateId) && id === String(candidateId);
  if (role === 'company') return Boolean(companyId) && id === String(companyId);
  return false;
}

module.exports = { canAccessApplicationConversation };
