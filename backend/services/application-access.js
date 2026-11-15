const COMPANY_APPLICATION_CANDIDATE_FIELDS = [
  'name',
  'profile.education',
  'profile.professionalSummary',
  'profile.experience',
  'profile.skills',
  'profile.projects',
  'profile.certifications',
  'cvAnalysis.skills',
  'cv.fileName',
  'cv.size'
].join(' ');

function canCompanyAccessApplicationCv(role, companyId, applicationCompanyId) {
  return role === 'company'
    && Boolean(companyId)
    && Boolean(applicationCompanyId)
    && String(companyId) === String(applicationCompanyId);
}

module.exports = {
  COMPANY_APPLICATION_CANDIDATE_FIELDS,
  canCompanyAccessApplicationCv
};
