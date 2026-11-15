const test = require('node:test');
const assert = require('node:assert/strict');
const {
  COMPANY_APPLICATION_CANDIDATE_FIELDS,
  canCompanyAccessApplicationCv
} = require('../services/application-access');

test('solo la empresa propietaria de la oferta puede acceder al CV', () => {
  assert.equal(canCompanyAccessApplicationCv('company', 'company-1', 'company-1'), true);
  assert.equal(canCompanyAccessApplicationCv('company', 'company-2', 'company-1'), false);
});

test('candidatos y usuarios sin identificador no pueden acceder al CV de una postulación', () => {
  assert.equal(canCompanyAccessApplicationCv('candidate', 'company-1', 'company-1'), false);
  assert.equal(canCompanyAccessApplicationCv('company', null, 'company-1'), false);
  assert.equal(canCompanyAccessApplicationCv('company', 'company-1', null), false);
});

test('la proyección de datos para empresas excluye identificadores y datos personales sensibles', () => {
  const fields = COMPANY_APPLICATION_CANDIDATE_FIELDS.split(/\s+/);
  for (const forbidden of [
    'conadisNumber',
    'email',
    'phone',
    'profile.address',
    'profile.birth',
    'profile.accessibility',
    'cv.data'
  ]) {
    assert.equal(fields.includes(forbidden), false, forbidden + ' no debe exponerse a empresas');
  }
  assert.ok(fields.includes('name'));
  assert.ok(fields.includes('profile.skills'));
});
