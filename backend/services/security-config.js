const DEFAULT_JWT_PLACEHOLDER = 'change-this-secret-in-render';

function auditSecurityConfig(env = process.env) {
  const jwtSecret = String(env.JWT_SECRET || '').trim();
  const origins = String(env.FRONTEND_ORIGIN || 'https://isa18121999.github.io')
    .split(',')
    .map(origin => origin.trim())
    .filter(Boolean);

  return {
    jwtSecretNeedsAttention:
      !jwtSecret ||
      jwtSecret === DEFAULT_JWT_PLACEHOLDER ||
      jwtSecret.length < 32,
    corsAllowsAnyOrigin: origins.includes('*') || origins.length === 0
  };
}

module.exports = { auditSecurityConfig, DEFAULT_JWT_PLACEHOLDER };
