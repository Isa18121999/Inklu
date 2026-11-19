const test = require('node:test');
const assert = require('node:assert/strict');
const {
  getApplicationMessageReceiver,
  buildApplicationMessageNotification
} = require('../services/application-notifications');

test('envía la notificación al otro participante de la conversación', () => {
  assert.equal(getApplicationMessageReceiver('candidate-1', 'candidate-1', 'company-1'), 'company-1');
  assert.equal(getApplicationMessageReceiver('company-1', 'candidate-1', 'company-1'), 'candidate-1');
});

test('no asigna destinatario a usuarios ajenos a la postulación', () => {
  assert.equal(getApplicationMessageReceiver('other-user', 'candidate-1', 'company-1'), null);
});

test('construye una notificación de mensaje con el destinatario y la postulación correctos', () => {
  const notification = buildApplicationMessageNotification({
    receiverId: 'company-1',
    applicationId: 'application-1',
    senderName: 'Isabella',
    jobTitle: 'Desarrolladora Flutter'
  });
  assert.deepEqual(notification, {
    userId: 'company-1',
    title: 'Nuevo mensaje de postulación',
    message: 'Isabella te envió un mensaje sobre “Desarrolladora Flutter”.',
    type: 'application_message',
    relatedId: 'application-1'
  });
});
