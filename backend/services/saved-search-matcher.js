function normalize(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim();
}

function includesFilter(filter, values) {
  const wanted = normalize(filter);
  if (!wanted) return true;
  return values.some(value => normalize(value).includes(wanted));
}

/**
 * Returns true only when every non-empty saved-search filter matches the offer.
 * This is intentionally a literal, accent-insensitive matcher (not user regex).
 */
function matchesSavedJobSearch(search, job, companyName = '') {
  if (!search || !job) return false;

  const query = String(search.query ?? '').trim();
  const location = String(search.location ?? '').trim();
  const modality = String(search.modality ?? '').trim();
  const contractType = String(search.contractType ?? '').trim();
  const category = String(search.category ?? '').trim();
  const withAccessibility = search.withAccessibility === true;
  const hasAnyFilter = Boolean(
    query || location || modality || contractType || category || withAccessibility
  );
  if (!hasAnyFilter) return false;

  const jobText = [
    job.title,
    job.description,
    job.category,
    job.location,
    job.modality,
    job.contractType,
    companyName,
    ...(Array.isArray(job.requiredSkills) ? job.requiredSkills : []),
    ...(Array.isArray(job.preferredSkills) ? job.preferredSkills : [])
  ];
  if (query && !includesFilter(query, jobText)) return false;
  if (location && !includesFilter(location, [job.location])) return false;
  if (modality && !includesFilter(modality, [job.modality])) return false;
  if (contractType && !includesFilter(contractType, [job.contractType])) return false;
  if (category && !includesFilter(category, [job.category])) return false;
  if (withAccessibility && !String(job.accessibilityDetails ?? '').trim()) return false;
  return true;
}

module.exports = { matchesSavedJobSearch, normalize };
