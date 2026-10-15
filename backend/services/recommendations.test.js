const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeText,
  keywordCounts,
  recommendJobsForUser
} = require('./recommendations');

function job(data) {
  return {
    ...data,
    toObject() {
      return { ...data };
    }
  };
}

const candidate = {
  profile: {
    education: 'Ingeniería de software',
    experience: 1,
    skills: ['JavaScript', 'SQL'],
    location: 'Lima',
    modality: 'Remoto'
  },
  cvAnalysis: {
    skills: ['JavaScript'],
    keywords: [
      { term: 'javascript', count: 3 },
      { term: 'sql', count: 2 },
      { term: 'software', count: 1 }
    ]
  }
};

test('normaliza acentos y mayúsculas para comparar términos', () => {
  assert.equal(normalizeText('INGENIERÍA DE Software'), 'ingenieria de software');
});

test('descarta tokens numéricos al extraer palabras clave', () => {
  const terms = keywordCounts('12345 javascript 6789', 20).map(item => item.term);
  assert.deepEqual(terms, ['javascript']);
});

test('prioriza ofertas relacionadas y explica coincidencias de habilidades', () => {
  const relevant = job({
    _id: 'job-tech',
    title: 'Desarrollador JavaScript',
    description: 'Construir aplicaciones web y consultar bases SQL.',
    category: 'Tecnología',
    modality: 'Remoto',
    location: 'Lima',
    requiredSkills: ['JavaScript', 'SQL'],
    preferredSkills: ['Git'],
    experienceRequired: 1,
    companyId: { name: 'Empresa tecnológica' }
  });
  const unrelated = job({
    _id: 'job-health',
    title: 'Enfermero clínico',
    description: 'Atención de pacientes y coordinación hospitalaria.',
    category: 'Salud',
    modality: 'Presencial',
    location: 'Cusco',
    requiredSkills: ['Enfermería'],
    preferredSkills: [],
    experienceRequired: 3,
    companyId: { name: 'Clínica' }
  });

  const results = recommendJobsForUser(candidate, [unrelated, relevant]);
  assert.equal(results.length, 1);
  assert.equal(results[0]._id, 'job-tech');
  assert.ok(results[0].matchScore >= 0 && results[0].matchScore <= 100);
  assert.ok(results[0].matchReasons.some(reason => reason.includes('Habilidades')));
  assert.ok(results[0].matchedSkills.includes('JavaScript'));
});

test('marca cuando la experiencia indicada no alcanza el requisito', () => {
  const demandingJob = job({
    _id: 'job-senior',
    title: 'Desarrollador senior JavaScript',
    description: 'Software y SQL.',
    category: 'Tecnología',
    modality: 'Remoto',
    location: 'Lima',
    requiredSkills: ['JavaScript', 'SQL'],
    preferredSkills: [],
    experienceRequired: 5,
    companyId: { name: 'Empresa' }
  });
  const newCandidate = {
    ...candidate,
    profile: { ...candidate.profile, experience: 0 }
  };
  const [result] = recommendJobsForUser(newCandidate, [demandingJob]);
  assert.ok(result);
  assert.equal(result.experienceFit, false);
  assert.ok(result.matchReasons.some(reason => reason.includes('solicita 5 año(s)')));
});
