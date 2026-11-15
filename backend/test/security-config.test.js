const test = require('node:test');
const assert = require('node:assert/strict');
const {
  auditSecurityConfig,
  getAllowedFrontendOrigins,
  DEFAULT_JWT_PLACEHOLDER
} = require('../services/security-config');

test('detecta secretos JWT ausentes, cortos o de ejemplo', () => {
  assert.equal(auditSecurityConfig({}).jwtSecretNeedsAttention, true);
  assert.equal(auditSecurityConfig({ JWT_SECRET: DEFAULT_JWT_PLACEHOLDER }).jwtSecretNeedsAttention, true);
  assert.equal(auditSecurityConfig({ JWT_SECRET: 'short' }).jwtSecretNeedsAttention, true);
  assert.equal(auditSecurityConfig({ JWT_SECRET: 'a'.repeat(48) }).jwtSecretNeedsAttention, false);
});

test('CORS solo conserva orígenes explícitos y elimina comodines', () => {
  assert.deepEqual(
    getAllowedFrontendOrigins({ FRONTEND_ORIGIN: 'https://inklu-web.onrender.com, https://isa18121999.github.io, *' }),
    ['https://inklu-web.onrender.com', 'https://isa18121999.github.io']
  );
  assert.equal(auditSecurityConfig({ JWT_SECRET: 'a'.repeat(48), FRONTEND_ORIGIN: '*' }).corsAllowsAnyOrigin, true);
  assert.equal(auditSecurityConfig({ JWT_SECRET: 'a'.repeat(48), FRONTEND_ORIGIN: 'https://inklu-web.onrender.com' }).corsAllowsAnyOrigin, false);
});
