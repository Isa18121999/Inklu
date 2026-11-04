const DEFAULT_JWT_PLACEHOLDER = 'change-this-secret-in-render';
const DEFAULT_FRONTEND_ORIGIN = 'https://isa18121999.github.io';

function getAllowedFrontendOrigins(env = process.env) {
  const raw = String(env.FRONTEND_ORIGIN || DEFAULT_FRONTEND_ORIGIN);
  return raw.split(',').map(origin => origin.trim()).filter(origin => origin && origin !== '*');
}

function auditSecurityConfig(env = process.env) {
  const jwtSecret = String(env.JWT_SECRET || '').trim();
  const rawOrigins = String(env.FRONTEND_ORIGIN || DEFAULT_FRONTEND_ORIGIN)
    .split(',').map(origin => origin.trim()).filter(Boolean);

  return {
    jwtSecretNeedsAttention:
      !jwtSecret ||
      jwtSecret === DEFAULT_JWT_PLACEHOLDER ||
      jwtSecret.length < 32,
    corsAllowsAnyOrigin: rawOrigins.includes('*') || rawOrigins.length === 0
  };
}

module.exports = {
  auditSecurityConfig,
  getAllowedFrontendOrigins,
  DEFAULT_JWT_PLACEHOLDER
};
