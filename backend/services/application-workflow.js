const LEGACY_STATUSES = {
  'Postulada': 'Postulado',
  'En revisión': 'CV visto',
  'Entrevista': 'Entrevista',
  'Seleccionada': 'Aceptado',
  'No seleccionada': 'Proceso terminado'
};

const COMPANY_STATUSES = ['Postulado', 'CV visto', 'En proceso', 'Entrevista', 'Aceptado', 'Proceso terminado'];
const TERMINAL_STATUSES = new Set(['Aceptado', 'Proceso terminado', 'Retirada por candidato']);
const STAGE_INDEX = new Map(COMPANY_STATUSES.map((status, index) => [status, index]));

function normalizeApplicationStatus(status) {
  return LEGACY_STATUSES[status] || status || 'Postulado';
}

function chatIsEnabled(status) {
  return ['En proceso', 'Entrevista', 'Aceptado', 'Proceso terminado'].includes(
    normalizeApplicationStatus(status)
  );
}

function canCompanyUpdateApplicationStatus(currentStatus, nextStatus) {
  const current = normalizeApplicationStatus(currentStatus);
  const next = normalizeApplicationStatus(nextStatus);

  if (!COMPANY_STATUSES.includes(next)) return false;
  if (current === next) return true;
  if (TERMINAL_STATUSES.has(current)) return false;

  const currentIndex = STAGE_INDEX.get(current);
  const nextIndex = STAGE_INDEX.get(next);
  return Number.isInteger(currentIndex) && Number.isInteger(nextIndex) && nextIndex > currentIndex;
}

module.exports = { normalizeApplicationStatus, canCompanyUpdateApplicationStatus, chatIsEnabled };
