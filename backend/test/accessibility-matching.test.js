const test = require('node:test');
const assert = require('node:assert/strict');
const { accessibilityMatch, recommendJobsForUser } = require('../services/recommendations');

function job(data) {
  return {
    ...data,
    toObject() { return { ...data }; }
  };
}

test('calcula compatibilidad de accesibilidad solo cuando la persona la comparte', () => {
  const candidate = {
    profile: {
      accessibility: {
        share: true,
        needType: 'Movilidad',
        preferences: ['Acceso físico', 'Ascensor']
      }
    }
  };
  const opening = {
    accessibility: {
      physicalAccess: true,
      elevator: true,
      accessibleParking: false
    }
  };
  const result = accessibilityMatch(candidate, opening);
  assert.equal(result.shared, true);
  assert.equal(result.matched.length, 2);
  assert.equal(result.missing.length, 1);
  assert.equal(result.score, 7);
});

test('no penaliza una oferta cuando las preferencias de accesibilidad no fueron compartidas', () => {
  const candidate = {
    profile: {
      accessibility: {
        share: false,
        needType: 'Movilidad',
        preferences: ['Acceso físico', 'Ascensor']
      }
    }
  };
  const opening = { accessibility: { physicalAccess: false, elevator: false } };
  const result = accessibilityMatch(candidate, opening);
  assert.equal(result.shared, false);
  assert.equal(result.requested.length, 0);
  assert.equal(result.score, 0);
});

test('incluye accesibilidad en las razones del ranking', () => {
  const candidate = {
    role: 'candidate',
    profile: {
      education: 'Ingeniería de Sistemas',
      experience: 1,
      skills: ['Python'],
      location: 'Lima',
      modality: 'Remoto',
      accessibility: {
        share: true,
        needType: '',
        preferences: ['Horario flexible']
      }
    },
    cvAnalysis: {
      skills: ['Python'],
      keywords: [{ term: 'python', count: 3 }, { term: 'sistemas', count: 2 }]
    }
  };
  const opening = job({
    _id: 'job-accessible',
    title: 'Desarrollador Python',
    description: 'Desarrollo de software y automatización.',
    category: 'Tecnología',
    modality: 'Remoto',
    location: 'Lima',
    requiredSkills: ['Python'],
    preferredSkills: [],
    experienceRequired: 1,
    accessibility: { flexibleSchedule: true }
  });

  const [result] = recommendJobsForUser(candidate, [opening]);
  assert.ok(result);
  assert.equal(result.accessibilityMatch.matched[0], 'flexibleSchedule');
  assert.ok(result.matchReasons.some(reason => reason.includes('preferencias de accesibilidad')));
});
