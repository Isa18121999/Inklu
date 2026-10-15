const test = require('node:test');
const assert = require('node:assert/strict');
const { auditSecurityConfig } = require('./security-config');

test('marca una JWT ausente o de demostración como pendiente de corregir', () => {
  assert.equal(auditSecurityConfig({}).jwtSecretNeedsAttention, true);
  assert.equal(auditSecurityConfig({ JWT_SECRET: 'change-this-secret-in-render' }).jwtSecretNeedsAttention, true);
  assert.equal(auditSecurityConfig({ JWT_SECRET: 'short-key' }).jwtSecretNeedsAttention, true);
});

test('acepta una JWT larga configurada y detecta CORS abierto', () => {
  const audit = auditSecurityConfig({
    JWT_SECRET: 'a'.repeat(64),
    FRONTEND_ORIGIN: '*'
  });
  assert.equal(audit.jwtSecretNeedsAttention, false);
  assert.equal(audit.corsAllowsAnyOrigin, true);
});

test('admite más de un origen explícito y no revela valores secretos', () => {
  const audit = auditSecurityConfig({
    JWT_SECRET: 'b'.repeat(64),
    FRONTEND_ORIGIN: 'https://isa18121999.github.io,https://preview.example.test'
  });
  assert.equal(audit.jwtSecretNeedsAttention, false);
  assert.equal(audit.corsAllowsAnyOrigin, false);
  assert.equal(JSON.stringify(audit).includes('b'.repeat(64)), false);
});
