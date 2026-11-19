const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeApplicationStatus,
  canCompanyUpdateApplicationStatus,
  chatIsEnabled
} = require('../services/application-workflow');

test('normaliza los estados heredados al flujo actual', () => {
  assert.equal(normalizeApplicationStatus('Postulada'), 'Postulado');
  assert.equal(normalizeApplicationStatus('En revisión'), 'CV visto');
  assert.equal(normalizeApplicationStatus('Entrevista'), 'Entrevista');
  assert.equal(normalizeApplicationStatus('Seleccionada'), 'Aceptado');
  assert.equal(normalizeApplicationStatus('No seleccionada'), 'Proceso terminado');
});

test('permite avanzar sin retroceder en el proceso de selección', () => {
  assert.equal(canCompanyUpdateApplicationStatus('Postulado', 'CV visto'), true);
  assert.equal(canCompanyUpdateApplicationStatus('CV visto', 'En proceso'), true);
  assert.equal(canCompanyUpdateApplicationStatus('En proceso', 'Entrevista'), true);
  assert.equal(canCompanyUpdateApplicationStatus('Entrevista', 'Aceptado'), true);
  assert.equal(canCompanyUpdateApplicationStatus('Postulado', 'Proceso terminado'), true);
  assert.equal(canCompanyUpdateApplicationStatus('En proceso', 'CV visto'), false);
  assert.equal(canCompanyUpdateApplicationStatus('CV visto', 'Postulado'), false);
});

test('los estados finales y las postulaciones retiradas no se pueden reabrir', () => {
  assert.equal(canCompanyUpdateApplicationStatus('Aceptado', 'En proceso'), false);
  assert.equal(canCompanyUpdateApplicationStatus('Proceso terminado', 'En proceso'), false);
  assert.equal(canCompanyUpdateApplicationStatus('Retirada por candidato', 'Aceptado'), false);
  assert.equal(canCompanyUpdateApplicationStatus('Seleccionada', 'Proceso terminado'), false);
});

test('permite conservar la etapa actual sin crear una transición nueva', () => {
  assert.equal(canCompanyUpdateApplicationStatus('CV visto', 'CV visto'), true);
});


test('el chat solo se habilita desde En proceso y conserva compatibilidad con estados heredados', () => {
  assert.equal(chatIsEnabled('Postulado'), false);
  assert.equal(chatIsEnabled('CV visto'), false);
  assert.equal(chatIsEnabled('En proceso'), true);
  assert.equal(chatIsEnabled('Entrevista'), true);
  assert.equal(chatIsEnabled('Aceptado'), true);
  assert.equal(chatIsEnabled('Proceso terminado'), true);
  assert.equal(chatIsEnabled('Retirada por candidato'), false);
  assert.equal(chatIsEnabled('Entrevista'), true);
  assert.equal(chatIsEnabled('Seleccionada'), true);
  assert.equal(chatIsEnabled('No seleccionada'), true);
});
