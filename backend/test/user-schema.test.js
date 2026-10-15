const test = require('node:test');
const assert = require('node:assert/strict');
const User = require('../models/User');

test('CV y foto quedan excluidos de las consultas normales de usuario', () => {
  const cvSchema = User.schema.path('cv').schema;
  const photoSchema = User.schema.path('profilePhoto').schema;

  assert.equal(cvSchema.path('data').options.select, false);
  assert.equal(photoSchema.path('data').options.select, false);
});

test('los tokens de verificación y recuperación no se seleccionan por defecto', () => {
  for (const path of [
    'emailVerificationTokenHash',
    'emailVerificationExpires',
    'emailVerificationRequestedAt',
    'passwordResetTokenHash',
    'passwordResetExpires',
    'passwordResetRequestedAt'
  ]) {
    assert.equal(User.schema.path(path).options.select, false, `${path} debe estar oculto por defecto`);
  }
});

test('las cuentas candidatas pueden guardar ofertas sin duplicados', () => {
  const path = User.schema.path('savedJobs');
  assert.ok(path, 'savedJobs debe existir en el modelo');
  assert.equal(path.instance, 'Array');
  assert.equal(path.caster.options.ref, 'Job');
});

test('el perfil profesional guarda resumen, proyectos, certificaciones y experiencia validada', () => {
  const profileSchema = User.schema.path('profile').schema;

  assert.equal(profileSchema.path('professionalSummary').options.maxlength, 1200);
  assert.equal(profileSchema.path('experience').options.max, 60);
  assert.ok(profileSchema.path('projects'), 'projects debe existir en el perfil');
  assert.ok(profileSchema.path('certifications'), 'certifications debe existir en el perfil');
});
