// Motor híbrido de matching de INKLU.
// Combina NLP/TF-IDF, habilidades, carrera/área, experiencia,
// ubicación, modalidad y preferencias de accesibilidad compartidas.
// No usa la discapacidad como criterio de aptitud ni como penalización.
function normalizeText(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

const KNOWN_SKILL_LABELS = [
  'Excel', 'Microsoft Office', 'Atención al cliente', 'Ventas', 'Marketing digital',
  'Comunicación', 'Administración', 'Contabilidad', 'Finanzas', 'Programación',
  'Python', 'JavaScript', 'SQL y bases de datos', 'Desarrollo web', 'Flutter',
  'Diseño UX/UI', 'Diseño gráfico', 'Análisis de datos', 'Soporte técnico',
  'Redes y sistemas', 'Recursos humanos', 'Gestión de proyectos', 'Logística',
  'Educación', 'Salud', 'Inglés'
];

function humanizeSkill(value) {
  const raw = String(value ?? '').trim();
  if (!raw) return '';
  if (/^\d+$/.test(raw)) {
    const index = Number(raw);
    return Number.isInteger(index) && index >= 0 && index < KNOWN_SKILL_LABELS.length
      ? KNOWN_SKILL_LABELS[index]
      : '';
  }
  return raw;
}

const GENERIC_SKILL_TERMS = new Set([
  'excel', 'microsoft office', 'office', 'word', 'powerpoint',
  'comunicacion', 'comunicacion efectiva', 'organizacion',
  'trabajo en equipo', 'responsabilidad', 'puntualidad',
  'atencion al cliente', 'servicio al cliente', 'ofimatica'
].map(normalizeText));

const CAREER_GROUP_LABELS = {
  tecnologia: 'Tecnología', administracion: 'Administración', diseno: 'Diseño',
  datos: 'Análisis de datos', salud: 'Salud', educacion: 'Educación',
  logistica: 'Logística', marketing: 'Marketing', atencion: 'Atención al cliente',
  proyectos: 'Gestión de proyectos'
};

const CV_STOP_WORDS = new Set((
  'para como con por una uno unas unos las los del que de en al el y o a se su sus es son fue ser esta estar ' +
  'the and for with from this that are was were you your our their have has had not but can will about after before ' +
  'perfil curriculum cv candidato candidata empresa empleo trabajo profesional profesionales experiencia ' +
  'experiencias habilidades conocimiento conocimientos funciones responsabilidades objetivo datos persona personal ' +
  'anos ano mes meses equipo equipos puesto posicion cargo laboral laborales años'
).split(/\s+/).map(normalizeText));

function keywordCounts(text, limit = 60) {
  const tokens = normalizeText(text).match(/[a-z0-9+#.]{3,}/g) || [];
  const counts = new Map();
  for (const token of tokens) {
    if (CV_STOP_WORDS.has(token) || /^\d+$/.test(token)) continue;
    counts.set(token, (counts.get(token) || 0) + 1);
  }
  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([term, count]) => ({ term, count }));
}

function tfidfCosineSimilarity(candidateKeywords, jobKeywords, documentFrequency, documentCount) {
  const candidateCounts = new Map((candidateKeywords || []).map(item => [item.term, item.count]));
  const jobCounts = new Map((jobKeywords || []).map(item => [item.term, item.count]));
  const terms = new Set([...candidateCounts.keys(), ...jobCounts.keys()]);
  let dot = 0;
  let candidateNorm = 0;
  let jobNorm = 0;
  for (const term of terms) {
    const df = documentFrequency.get(term) || 0;
    const idf = Math.log((documentCount + 1) / (df + 1)) + 1;
    const candidateWeight = candidateCounts.has(term) ? (1 + Math.log(candidateCounts.get(term))) * idf : 0;
    const jobWeight = jobCounts.has(term) ? (1 + Math.log(jobCounts.get(term))) * idf : 0;
    dot += candidateWeight * jobWeight;
    candidateNorm += candidateWeight * candidateWeight;
    jobNorm += jobWeight * jobWeight;
  }
  if (!candidateNorm || !jobNorm) return 0;
  return dot / (Math.sqrt(candidateNorm) * Math.sqrt(jobNorm));
}

// Traduce las preferencias que la persona decidió compartir a capacidades
// concretas de la oferta. La preferencia se usa para mejorar compatibilidad,
// nunca para decidir si la persona "es apta" para trabajar.
const ACCESSIBILITY_RULES = [
  { terms: ['adaptacion', 'adaptaciones del puesto', 'ajuste del puesto'], flags: ['workplaceAdaptation'] },
  { terms: ['tecnologia asistiva', 'tecnologia de asistencia', 'lector de pantalla', 'software accesible'], flags: ['assistiveTechnology'] },
  { terms: ['horario flexible', 'flexibilidad horaria'], flags: ['flexibleSchedule'] },
  { terms: ['acceso fisico', 'accesibilidad fisica', 'acceso al edificio'], flags: ['physicalAccess'] },
  { terms: ['ascensor', 'elevador'], flags: ['elevator'] },
  { terms: ['estacionamiento accesible', 'parking accesible'], flags: ['accessibleParking'] },
  { terms: ['baño accesible', 'bano accesible', 'servicio higienico accesible'], flags: ['accessibleRestroom'] },
  { terms: ['transporte', 'apoyo de transporte'], flags: ['transportationSupport'] },
  { terms: ['interprete', 'lengua de señas', 'lengua de senas'], flags: ['interpreter'] }
];

function accessibilityMatch(user, job) {
  const accessibility = user?.profile?.accessibility;
  if (!accessibility || accessibility.share !== true) {
    return { shared: false, requested: [], matched: [], missing: [], score: 0 };
  }

  const preferences = Array.isArray(accessibility.preferences)
    ? accessibility.preferences.map(String).map(normalizeText).filter(Boolean)
    : [];
  const needType = normalizeText(accessibility.needType);
  const requested = [];

  for (const preference of preferences) {
    const rule = ACCESSIBILITY_RULES.find(item =>
      item.terms.some(term => normalizeText(term) === preference || preference.includes(normalizeText(term)) || normalizeText(term).includes(preference))
    );
    if (rule) requested.push(...rule.flags);
  }

  if (needType.includes('movil') || needType.includes('fisic')) requested.push('physicalAccess', 'elevator', 'accessibleParking');
  if (needType.includes('visual')) requested.push('assistiveTechnology');
  if (needType.includes('audit') || needType.includes('sordo')) requested.push('interpreter', 'assistiveTechnology');
  if (needType.includes('comunic')) requested.push('interpreter', 'assistiveTechnology');

  const uniqueRequested = [...new Set(requested)];
  const jobAccessibility = job?.accessibility || {};
  const matched = uniqueRequested.filter(flag => jobAccessibility[flag] === true);
  const missing = uniqueRequested.filter(flag => jobAccessibility[flag] !== true);
  const score = uniqueRequested.length
    ? Math.round((matched.length / uniqueRequested.length) * 10)
    : 0;

  return { shared: true, requested: uniqueRequested, matched, missing, score };
}

function recommendJobsForUser(user, jobs) {
  const skills = [...new Set([
    ...(user.cvAnalysis?.skills || []),
    ...(user.profile?.skills || [])
  ].map(humanizeSkill).filter(Boolean))];
  const normalizedSkills = skills.map(normalizeText);
  const location = normalizeText(user.profile?.location);
  const modality = normalizeText(user.profile?.modality);
  const cvKeywords = user.cvAnalysis?.keywords || [];
  const education = String(user.profile?.education || '');
  const professionalSummary = String(user.profile?.professionalSummary || '');
  const projects = Array.isArray(user.profile?.projects) ? user.profile.projects : [];
  const certifications = Array.isArray(user.profile?.certifications) ? user.profile.certifications : [];
  const cvCareerTerms = cvKeywords.slice(0, 25).map(item => item.term || '');

  const profileText = [education, professionalSummary, ...projects, ...certifications, ...skills, ...cvCareerTerms]
    .filter(Boolean).join(' ');
  const profileKeywords = keywordCounts(profileText, 100);
  const mergedCandidateKeywords = new Map();
  for (const item of [...cvKeywords, ...profileKeywords]) {
    if (!item?.term) continue;
    const rawTerm = String(item.term).trim();
    const namedTerm = /^\d+$/.test(rawTerm) ? humanizeSkill(rawTerm) : rawTerm;
    if (!namedTerm) continue;
    const term = normalizeText(namedTerm);
    const count = Math.max(1, Number(item.count) || 1);
    mergedCandidateKeywords.set(term, Math.max(mergedCandidateKeywords.get(term) || 0, count));
  }
  const candidateKeywords = [...mergedCandidateKeywords.entries()].map(([term, count]) => ({ term, count }));
  const careerTerms = new Set(profileKeywords.map(item => item.term));
  const candidateExperience = Math.max(0, Number(user.profile?.experience || 0));

  const careerGroups = [
    { key: 'tecnologia', signals: ['tecnologia', 'informatica', 'computacion', 'sistemas', 'software', 'programacion', 'desarrollo web', 'desarrollo de software', 'flutter', 'javascript', 'typescript', 'python', 'java', 'sql', 'ciberseguridad', 'redes informaticas', 'ingenieria de sistemas', 'ingenieria informatica', 'computacion e informatica', 'ciencia de la computacion', 'analista programador', 'tecnologias de la informacion', 'soporte tecnico', 'infraestructura'] },
    { key: 'administracion', signals: ['administracion', 'administrativo', 'gestion empresarial', 'negocios', 'contabilidad', 'finanzas', 'economia', 'recursos humanos', 'reclutamiento', 'asistente contable', 'auxiliar contable', 'tesoreria', 'planillas'] },
    { key: 'diseno', signals: ['diseno', 'ux', 'ui', 'figma', 'photoshop', 'illustrator', 'diseno grafico', 'diseno digital'] },
    { key: 'datos', signals: ['analisis de datos', 'analitica de datos', 'estadistica', 'power bi', 'tableau', 'data analysis', 'bases de datos', 'business intelligence', 'inteligencia de negocios'] },
    { key: 'salud', signals: ['salud', 'enfermeria', 'clinica', 'medicina', 'medico', 'medica', 'tecnologo medico', 'tecnologa medica', 'laboratorio clinico', 'radiologia', 'fisioterapia', 'rehabilitacion', 'odontologia', 'obstetricia', 'nutricion', 'farmacia', 'terapia ocupacional', 'atencion sanitaria', 'cuidados de pacientes', 'psicologia clinica'] },
    { key: 'educacion', signals: ['educacion', 'docencia', 'ensenanza', 'pedagogia', 'docente', 'profesor', 'instructor', 'capacitacion'] },
    { key: 'logistica', signals: ['logistica', 'inventario', 'almacen', 'cadena de suministro', 'transporte', 'distribucion', 'compras'] },
    { key: 'marketing', signals: ['marketing', 'publicidad', 'comunicacion', 'redes sociales', 'contenido', 'seo', 'community manager'] },
    { key: 'atencion', signals: ['atencion al cliente', 'servicio al cliente', 'ventas', 'soporte al cliente', 'mesa de ayuda', 'help desk', 'call center'] },
    { key: 'proyectos', signals: ['gestion de proyectos', 'project management', 'scrum', 'agile', 'coordinador de proyectos'] }
  ];

  const educationText = normalizeText(education);
  const educationGroups = new Set(careerGroups.filter(group => group.signals.some(signal => educationText.includes(normalizeText(signal)))).map(group => group.key));
  const candidateCareerText = normalizeText(profileText);
  const candidateGroups = educationGroups.size > 0
    ? educationGroups
    : new Set(careerGroups.filter(group => group.signals.some(signal => candidateCareerText.includes(normalizeText(signal)))).map(group => group.key));

  const groupsForText = value => {
    const normalized = normalizeText(value);
    return careerGroups.filter(group => group.signals.some(signal => normalized.includes(normalizeText(signal)))).map(group => group.key);
  };

  const jobDocuments = jobs.map(job => {
    const requiredSkills = Array.isArray(job.requiredSkills) ? job.requiredSkills.map(humanizeSkill).filter(Boolean) : [];
    const preferredSkills = Array.isArray(job.preferredSkills) ? job.preferredSkills.map(humanizeSkill).filter(Boolean) : [];
    const titleGroups = groupsForText(job.title);
    const categoryGroups = groupsForText(job.category);
    const skillGroups = groupsForText([...requiredSkills, ...preferredSkills].join(' '));
    const content = [job.title, job.description, job.category, ...requiredSkills, ...preferredSkills].join(' ');
    const jobGroups = titleGroups.length ? titleGroups : [...new Set([...categoryGroups, ...skillGroups])];
    const matchingCategoryGroup = categoryGroups.find(group => titleGroups.includes(group));
    const primaryAreaGroup = titleGroups.length ? (matchingCategoryGroup || titleGroups[0]) : (categoryGroups[0] || skillGroups[0] || null);
    return {
      job, requiredSkills, preferredSkills, content, titleGroups, categoryGroups, jobGroups,
      professionalArea: primaryAreaGroup ? CAREER_GROUP_LABELS[primaryAreaGroup] : '',
      keywords: keywordCounts(content, 200)
    };
  });

  const documentFrequency = new Map();
  for (const document of jobDocuments) {
    for (const term of new Set(document.keywords.map(item => item.term))) {
      documentFrequency.set(term, (documentFrequency.get(term) || 0) + 1);
    }
  }

  return jobDocuments.map(document => {
    const { job, requiredSkills, preferredSkills, jobGroups, professionalArea, keywords } = document;
    const jobText = normalizeText([job.title, job.description, job.category, job.modality, job.location, ...requiredSkills].join(' '));
    const matchedSkills = skills.filter(skill => {
      const normalized = normalizeText(skill);
      return normalized.length > 1 && jobText.includes(normalized);
    });
    const matchedRequired = requiredSkills.filter(required => {
      const normalized = normalizeText(required);
      return normalized.length > 1 && normalizedSkills.some(skill => skill.includes(normalized) || normalized.includes(skill));
    });
    const missingRequiredSkills = requiredSkills.filter(required => !matchedRequired.includes(required));
    const matchedPreferred = preferredSkills.filter(preferred => {
      const normalized = normalizeText(preferred);
      return normalized.length > 1 && normalizedSkills.some(skill => skill.includes(normalized) || normalized.includes(skill));
    });
    const candidateTerms = new Set(candidateKeywords.map(item => item.term));
    const sharedKeywords = keywords.filter(item => candidateTerms.has(item.term)).sort((a, b) => b.count - a.count).slice(0, 5).map(item => item.term);
    const matchedCareerTerms = keywords.filter(item => careerTerms.has(item.term)).sort((a, b) => b.count - a.count).slice(0, 5).map(item => item.term);
    const careerCategoryMatch = jobGroups.some(group => candidateGroups.has(group));
    const hasSpecificRequiredSkillMatch = matchedRequired.some(skill => !GENERIC_SKILL_TERMS.has(normalizeText(skill)));
    const hasProfessionMismatch = candidateGroups.size > 0 && jobGroups.length > 0 && !careerCategoryMatch;
    const lacksCareerContextForSpecializedJob = candidateGroups.size === 0 && jobGroups.length > 0 && !hasSpecificRequiredSkillMatch;
    const hasCareerGroupConflict = hasProfessionMismatch || lacksCareerContextForSpecializedJob;

    const similarity = tfidfCosineSimilarity(candidateKeywords, keywords, documentFrequency, Math.max(jobDocuments.length, 1));
    const accessibility = accessibilityMatch(user, job);
    const reasons = [];
    if (careerCategoryMatch) reasons.push('Área profesional relacionada con tu carrera o CV');
    if (matchedSkills.length) reasons.push('Habilidades relacionadas: ' + matchedSkills.slice(0, 4).join(', '));
    if (matchedPreferred.length) reasons.push('Habilidades deseables coincidentes: ' + matchedPreferred.slice(0, 4).join(', '));
    if (matchedCareerTerms.length) reasons.push('Coincidencias con tu CV: ' + matchedCareerTerms.slice(0, 4).join(', '));
    if (location && normalizeText(job.location).includes(location)) reasons.push('Coincide con tu ubicación preferida');
    if (modality && normalizeText(job.modality).includes(modality)) reasons.push('Coincide con tu modalidad preferida');
    if (accessibility.shared && accessibility.requested.length > 0) {
      if (accessibility.matched.length === accessibility.requested.length) reasons.push('La oferta cubre tus preferencias de accesibilidad compartidas');
      else if (accessibility.matched.length > 0) reasons.push('Coincide con ' + accessibility.matched.length + ' de ' + accessibility.requested.length + ' preferencias de accesibilidad compartidas');
    }

    const experienceRequired = Math.max(0, Number(job.experienceRequired || 0));
    const experienceGap = Math.max(0, experienceRequired - candidateExperience);
    let score = Math.round(similarity * 60);
    if (matchedSkills.length) score = Math.max(score, Math.min(50, matchedSkills.length * 10));
    score += Math.min(20, matchedCareerTerms.length * 4);
    if (careerCategoryMatch) score += 15;
    if (matchedRequired.length) score += Math.min(10, matchedRequired.length * 3);
    if (missingRequiredSkills.length) {
      score -= Math.min(25, missingRequiredSkills.length * 5);
      reasons.push('No encontramos en tu perfil estos requisitos: ' + missingRequiredSkills.slice(0, 4).join(', ') + '. Revisa si conviene completar tus habilidades antes de postular.');
    }
    if (matchedPreferred.length) score += Math.min(6, matchedPreferred.length * 2);
    if (experienceGap === 0) {
      score += 8;
      reasons.push('Experiencia requerida compatible con tu perfil');
    } else {
      score -= Math.min(35, experienceGap * 12);
      reasons.push('La oferta solicita ' + experienceRequired + ' año(s) de experiencia y tu perfil indica ' + candidateExperience + '.');
    }
    if (location && normalizeText(job.location).includes(location)) score += 3;
    if (modality && normalizeText(job.modality).includes(modality)) score += 3;
    if (accessibility.shared && accessibility.requested.length > 0) score += accessibility.score;
    if (hasProfessionMismatch) {
      score = 0;
      reasons.push('Esta oferta pertenece a un área profesional distinta a la indicada en tu perfil.');
    } else if (lacksCareerContextForSpecializedJob) {
      score = 0;
      reasons.push('Completa tu carrera o añade habilidades específicas para poder recomendarte ofertas de esta área.');
    }
    score = Math.max(0, Math.min(100, score));

    const hasProfessionalEvidence = careerCategoryMatch || matchedSkills.length > 0 || matchedRequired.length > 0 || matchedPreferred.length > 0 || sharedKeywords.length >= 2 || matchedCareerTerms.length >= 2;
    const careerMatch = !hasCareerGroupConflict && hasProfessionalEvidence;
    const record = job.toObject();
    record.requiredSkills = requiredSkills;
    record.preferredSkills = preferredSkills;
    return {
      ...record,
      professionalArea: professionalArea || (() => {
        const rawCategory = String(record.category ?? '').trim();
        if (!rawCategory) return '';
        if (!/^\d+$/.test(rawCategory)) return rawCategory;
        const legacyCategories = ['Tecnología', 'Administración', 'Diseño', 'Atención al cliente', 'Educación', 'Salud', 'Finanzas', 'Logística', 'Marketing', 'Otro'];
        const categoryIndex = Number(rawCategory);
        return Number.isInteger(categoryIndex) && categoryIndex >= 0 && categoryIndex < legacyCategories.length ? legacyCategories[categoryIndex] : '';
      })(),
      matchScore: score,
      matchReasons: reasons,
      matchedSkills,
      matchedRequiredSkills: matchedRequired,
      missingRequiredSkills,
      matchedPreferredSkills: matchedPreferred,
      textSimilarity: Number(similarity.toFixed(4)),
      careerMatch,
      experienceFit: experienceGap === 0,
      accessibilityMatch: accessibility
    };
  })
    .filter(job => job.matchScore > 0 && job.careerMatch)
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, 10);
}

module.exports = { normalizeText, keywordCounts, tfidfCosineSimilarity, accessibilityMatch, recommendJobsForUser, humanizeSkill };
