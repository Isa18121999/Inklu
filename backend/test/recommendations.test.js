const test = require('node:test');
const assert = require('node:assert/strict');
const { recommendJobsForUser, normalizeText } = require('../services/recommendations');

function makeJob(values) {
  return {
    active: true,
    modality: 'Remoto',
    location: 'Lima, Perú',
    requiredSkills: [],
    experienceRequired: 0,
    ...values,
    toObject() {
      const { toObject, ...record } = this;
      return record;
    }
  };
}

function candidate(overrides = {}) {
  return {
    role: 'candidate',
    profile: {
      education: 'Ingeniería de Sistemas',
      experience: 1,
      skills: ['Python', 'SQL'],
      location: 'Lima Metropolitana',
      modality: 'Remoto'
    },
    cvAnalysis: {
      skills: ['Python', 'SQL y bases de datos'],
      keywords: [
        { term: 'python', count: 5 },
        { term: 'software', count: 4 },
        { term: 'sql', count: 3 },
        { term: 'apis', count: 2 }
      ]
    },
    ...overrides
  };
}

test('normaliza tildes y mayúsculas para comparar términos', () => {
  assert.equal(normalizeText('INGENIERÍA de Sistemas'), 'ingenieria de sistemas');
});

test('prioriza una oferta profesional relacionada y descarta una de otra área', () => {
  const related = makeJob({
    _id: 'tech-job',
    title: 'Desarrollador Python Junior',
    description: 'Desarrollo de software y APIs para aplicaciones.',
    category: 'Tecnología',
    requiredSkills: ['Python', 'SQL'],
    experienceRequired: 0
  });
  const unrelated = makeJob({
    _id: 'health-job',
    title: 'Enfermero clínico',
    description: 'Atención sanitaria y cuidados de enfermería.',
    category: 'Salud',
    requiredSkills: ['Enfermería'],
    experienceRequired: 0
  });

  const results = recommendJobsForUser(candidate(), [unrelated, related]);

  assert.equal(results.length, 1);
  assert.equal(results[0]._id, 'tech-job');
  assert.ok(results[0].matchScore > 0);
  assert.ok(results[0].matchReasons.some(reason => reason.includes('Área profesional')));
  assert.ok(results[0].matchReasons.some(reason => reason.includes('Habilidades')));
});

test('explica cuando la oferta solicita más experiencia que la indicada', () => {
  const demanding = makeJob({
    _id: 'senior-job',
    title: 'Desarrollador Python',
    description: 'Desarrollo de software y APIs.',
    category: 'Tecnología',
    requiredSkills: ['Python'],
    experienceRequired: 5
  });

  const results = recommendJobsForUser(candidate(), [demanding]);

  assert.equal(results.length, 1);
  assert.equal(results[0].experienceFit, false);
  assert.ok(results[0].matchReasons.some(reason => reason.includes('solicita 5')));
});

test('no recomienda una oferta sin evidencia de coincidencia profesional', () => {
  const sparseCandidate = {
    role: 'candidate',
    profile: { education: '', experience: 0, skills: [], location: '', modality: '' },
    cvAnalysis: { skills: [], keywords: [] }
  };
  const unrelated = makeJob({
    _id: 'admin-job',
    title: 'Auxiliar contable',
    description: 'Registro de facturas y balances financieros.',
    category: 'Administración',
    requiredSkills: ['Contabilidad'],
    experienceRequired: 0
  });

  assert.deepEqual(recommendJobsForUser(sparseCandidate, [unrelated]), []);
});
