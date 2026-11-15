const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const fixture = require('../data/demo-jobs.json');

test('el fixture contiene 20 ofertas ficticias variadas y completas', () => {
  assert.equal(fixture.schemaVersion, 1);
  assert.match(fixture.notice, /FICTICIOS PARA PRUEBAS/);
  assert.equal(fixture.publisherEmail, '18100102@ue.edu.pe');
  assert.match(fixture.publisherNote, /No crear cuentas ficticias/);
  assert.equal(fixture.offers.length, 20);
  assert.equal(new Set(fixture.offers.map(offer => offer.slug)).size, 20);
  const categories = new Set(fixture.offers.map(offer => offer.category));
  for (const category of ['Tecnología', 'Administración', 'Diseño', 'Atención al cliente', 'Educación', 'Salud', 'Finanzas', 'Logística', 'Marketing']) {
    assert.ok(categories.has(category), `Falta la categoría ${category}`);
  }
  for (const offer of fixture.offers) {
    assert.ok(!offer.company && !offer.email, 'La empresa publicadora se toma de la cuenta existente');
    assert.ok(offer.title && offer.description && offer.salary && offer.location);
    assert.ok(['Remoto', 'Híbrido', 'Presencial'].includes(offer.modality));
    assert.ok(Array.isArray(offer.requiredSkills) && offer.requiredSkills.length > 0);
    assert.equal(typeof offer.accessibility, 'object');
  }
});

test('el script usa la cuenta empresarial existente y no crea usuarios', () => {
  const script = require('node:fs').readFileSync(path.join(__dirname, '../scripts/seed-demo-jobs.js'), 'utf8');
  assert.match(script, /SEED_DEMO_JOBS !== 'true'/);
  assert.match(script, /18100102@ue\.edu\.pe/);
  assert.match(script, /publisher\.role !== 'company'/);
  assert.match(script, /isDemo: true/);
  assert.doesNotMatch(script, /User\.create|bcrypt|randomBytes/);
});
