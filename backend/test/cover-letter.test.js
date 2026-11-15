const test = require('node:test');
const assert = require('node:assert/strict');
const { buildCoverLetter } = require('../services/cover-letter');

test('genera una carta personalizada con datos del perfil y la oferta', () => {
  const letter = buildCoverLetter({
    name: 'Ana Pérez',
    profile: {
      education: 'Ingeniería de Sistemas',
      professionalSummary: 'Estudiante con interés en desarrollo de software.',
      experience: 1,
      skills: ['JavaScript', 'Flutter'],
      projects: ['Aplicación móvil accesible']
    },
    cvAnalysis: { skills: ['Python'] }
  }, {
    title: 'Desarrolladora junior',
    companyId: { name: 'Empresa Inclusiva' }
  });

  assert.match(letter, /Desarrolladora junior/);
  assert.match(letter, /Empresa Inclusiva/);
  assert.match(letter, /Ingeniería de Sistemas/);
  assert.match(letter, /JavaScript/);
  assert.match(letter, /Flutter/);
  assert.match(letter, /Python/);
  assert.match(letter, /Ana Pérez/);
  assert.ok(letter.length >= 80);
});
