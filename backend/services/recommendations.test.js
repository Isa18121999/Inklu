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

test('usa resumen, proyectos y certificaciones cuando el CV no aporta palabras clave', () => {
  const profileOnlyCandidate = {
    profile: {
      education: '',
      professionalSummary: 'Analítica de datos y reportes financieros con Power BI',
      experience: 0,
      skills: [],
      projects: ['Dashboard financiero con reportes automatizados'],
      certifications: ['Fundamentos de análisis de datos'],
      location: '',
      modality: ''
    },
    cvAnalysis: { skills: [], keywords: [] }
  };
  const relevant = job({
    _id: 'job-finance-data',
    title: 'Asistente de reportes financieros',
    description: 'Preparar dashboard y reportes de finanzas usando Power BI.',
    category: 'Finanzas',
    modality: 'Remoto',
    location: 'Lima',
    requiredSkills: ['Power BI'],
    preferredSkills: ['Excel'],
    experienceRequired: 0
  });

  const results = recommendJobsForUser(profileOnlyCandidate, [relevant]);

  assert.equal(results.length, 1);
  assert.equal(results[0]._id, 'job-finance-data');
  assert.ok(results[0].matchScore > 0);
  assert.ok(results[0].careerMatch);
  assert.ok(results[0].matchReasons.some(reason => reason.includes('Coincidencias con tu CV')));
});

test('muestra requisitos obligatorios no encontrados en el perfil sin afirmar que la persona no los tiene', () => {
  const partialCandidate = {
    profile: {
      education: 'Ingeniería de software',
      experience: 1,
      skills: ['Python'],
      projects: [],
      certifications: [],
      location: '',
      modality: ''
    },
    cvAnalysis: {
      skills: ['Python'],
      keywords: [{ term: 'python', count: 3 }, { term: 'software', count: 2 }]
    }
  };
  const opening = job({
    _id: 'python-docker',
    title: 'Desarrollador Python',
    description: 'Desarrollo de software y servicios API.',
    category: 'Tecnología',
    requiredSkills: ['Python', 'Docker'],
    preferredSkills: [],
    experienceRequired: 1
  });

  const [result] = recommendJobsForUser(partialCandidate, [opening]);

  assert.ok(result);
  assert.deepEqual(result.matchedRequiredSkills, ['Python']);
  assert.deepEqual(result.missingRequiredSkills, ['Docker']);
  assert.ok(result.matchReasons.some(reason => reason.includes('No encontramos en tu perfil estos requisitos')));
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
