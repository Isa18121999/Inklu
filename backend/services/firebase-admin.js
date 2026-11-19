const admin = require('firebase-admin');

let initialized = false;

function getMessaging() {
  if (!initialized) {
    const raw = String(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '').trim();
    if (!raw) return null;
    let serviceAccount;
    try {
      serviceAccount = JSON.parse(raw);
    } catch (error) {
      console.error('FIREBASE_SERVICE_ACCOUNT_JSON no contiene JSON válido:', error.message);
      return null;
    }
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    }
    initialized = true;
  }
  return admin.messaging();
}

async function sendPushToUser(userId, { title, body, data = {} }) {
  try {
    const messaging = getMessaging();
    if (!messaging) return;
    const User = require('../models/User');
    const user = await User.findById(userId).select('+fcmTokens');
    const tokens = (user?.fcmTokens || []).map(item => item.token).filter(Boolean);
    if (!tokens.length) return;
    const safeData = Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value ?? '')]));
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: String(title || 'INKLU'), body: String(body || '') },
      data: safeData,
      android: { priority: 'high', notification: { channelId: 'inklu_notifications', sound: 'default' } }
    });
    const invalidTokens = [];
    response.responses.forEach((result, index) => {
      const code = result.error?.code || '';
      if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) invalidTokens.push(tokens[index]);
    });
    if (invalidTokens.length) {
      await User.updateOne({ _id: userId }, { $pull: { fcmTokens: { token: { $in: invalidTokens } } } });
    }
  } catch (error) {
    // Push es complementario: nunca debe interrumpir una postulación, mensaje u otra operación.
    console.error('No se pudo enviar la notificación push:', error.message);
  }
}

module.exports = { sendPushToUser };
