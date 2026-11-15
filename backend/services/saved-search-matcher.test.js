const test = require('node:test');
const assert = require('node:assert/strict');
const { matchesSavedJobSearch } = require('./saved-search-matcher');

const offer = {
  title: 'Analista de Datos Junior',
  description: 'Preparar reportes para el equipo de tecnología.',
  category: 'Tecnología',
  location: 'Lima Metropolitana',
  modality: 'Remoto',
  contractType: 'Tiempo completo',
  requiredSkills: ['SQL', 'Power BI'],
  preferredSkills: ['Python'],
  accessibilityDetails: 'Acceso sin escalones y entrevista virtual.'
};

test('coincide cuando todos los filtros guardados encajan con la oferta', () => {
  assert.equal(matchesSavedJobSearch({
    label: 'Analítica remota',
    query: 'power bi',
    location: 'Lima',
    modality: 'remoto',
    contractType: 'Tiempo completo',
    category: 'tecnología',
    withAccessibility: true
  }, offer, 'Empresa Inclusiva'), true);
});

test('normaliza tildes y mayúsculas en búsquedas guardadas', () => {
  assert.equal(matchesSavedJobSearch({
    label: 'Datos',
    query: 'ANALÍSTA DE DATOS',
    category: 'TECNOLOGÍA'
  }, offer), true);
});

test('no genera alerta si un filtro concreto no coincide', () => {
  assert.equal(matchesSavedJobSearch({
    label: 'Presencial en Cusco',
    location: 'Cusco',
    modality: 'Presencial'
  }, offer), false);
});

test('la búsqueda que exige accesibilidad solo coincide si la oferta declara ajustes', () => {
  assert.equal(matchesSavedJobSearch({
    label: 'Con accesibilidad',
    withAccessibility: true
  }, offer), true);
  assert.equal(matchesSavedJobSearch({
    label: 'Con accesibilidad',
    withAccessibility: true
  }, { ...offer, accessibilityDetails: '   ' }), false);
});

test('no considera válida una búsqueda guardada sin filtros', () => {
  assert.equal(matchesSavedJobSearch({ label: 'Sin filtros' }, offer), false);
});
