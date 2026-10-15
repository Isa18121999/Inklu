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

test('el flujo de postulaciones admite el retiro y conserva el historial de estados', () => {
  const Application = require('../models/Application');
  const statuses = Application.schema.path('status').enumValues;
  const historyStatuses = Application.schema.path('statusHistory').schema.path('status').enumValues;

  assert.ok(statuses.includes('Postulado'));
  assert.ok(statuses.includes('En proceso'));
  assert.ok(statuses.includes('Retirada por candidato'));
  assert.ok(historyStatuses.includes('Retirada por candidato'));
  assert.ok(Application.schema.indexes().some(([keys, options]) =>
    keys.jobId === 1 && keys.candidateId === 1 && options.unique === true
  ));
});

test('las notificaciones admiten alertas de nuevas ofertas coincidentes', () => {
  const Notification = require('../models/Notification');
  assert.ok(Notification.schema.path('type').enumValues.includes('job_match'));
  assert.ok(Notification.schema.path('userId'), 'la notificación debe pertenecer a un usuario');
  assert.ok(Notification.schema.path('readAt'), 'la notificación debe poder marcarse como leída');
});
