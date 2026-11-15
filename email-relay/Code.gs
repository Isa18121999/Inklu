const TOKEN_PROPERTY = 'INKLU_RELAY_TOKEN';

function doPost(e) {
  try {
    const payload = JSON.parse((e && e.postData && e.postData.contents) || '{}');
    const expectedToken = PropertiesService.getScriptProperties().getProperty(TOKEN_PROPERTY);
    if (!expectedToken || !payload.token || payload.token !== expectedToken) {
      return jsonResponse({ success: false, error: 'unauthorized' });
    }

    const to = String(payload.to || '').trim();
    const subject = String(payload.subject || 'Recupera tu contraseña de INKLU').trim().slice(0, 180);
    const text = String(payload.text || '').slice(0, 20000);
    const html = String(payload.html || '').slice(0, 50000);
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(to) || !text) {
      return jsonResponse({ success: false, error: 'invalid_email_or_message' });
    }

    MailApp.sendEmail({
      to: to,
      subject: subject,
      body: text,
      htmlBody: html || undefined,
      name: 'INKLU'
    });
    return jsonResponse({ success: true });
  } catch (error) {
    console.error('INKLU mail relay error:', error);
    return jsonResponse({
      success: false,
      error: String((error && error.message) || error).slice(0, 180)
    });
  }
}

function doGet() {
  return jsonResponse({ service: 'INKLU email relay', ready: true });
}

function jsonResponse(value) {
  return ContentService
    .createTextOutput(JSON.stringify(value))
    .setMimeType(ContentService.MimeType.JSON);
}
