const test = require('node:test');
const assert = require('node:assert/strict');
const { canAccessApplicationConversation } = require('../services/conversation-access');

test('solo el candidato titular y la empresa propietaria acceden a la conversación', () => {
  assert.equal(canAccessApplicationConversation('candidate', 'candidate-1', 'candidate-1', 'company-1'), true);
  assert.equal(canAccessApplicationConversation('company', 'company-1', 'candidate-1', 'company-1'), true);
});

test('otras cuentas y roles no acceden a la conversación', () => {
  assert.equal(canAccessApplicationConversation('candidate', 'candidate-2', 'candidate-1', 'company-1'), false);
  assert.equal(canAccessApplicationConversation('company', 'company-2', 'candidate-1', 'company-1'), false);
  assert.equal(canAccessApplicationConversation('admin', 'candidate-1', 'candidate-1', 'company-1'), false);
  assert.equal(canAccessApplicationConversation(null, 'candidate-1', 'candidate-1', 'company-1'), false);
});

test('la función deniega el acceso si faltan identificadores', () => {
  assert.equal(canAccessApplicationConversation('candidate', 'candidate-1', null, 'company-1'), false);
  assert.equal(canAccessApplicationConversation('company', 'company-1', 'candidate-1', null), false);
});
