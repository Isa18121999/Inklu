// Recomendador determinista de INKLU. No es un modelo ML entrenado: combina
// palabras clave del CV, habilidades, carrera/área, ubicación, modalidad y experiencia.
function normalizeText(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

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

function recommendJobsForUser(user, jobs) {
  const skills = [...new Set([
    ...(user.cvAnalysis?.skills || []),
    ...(user.profile?.skills || [])
  ])];
  const normalizedSkills = skills.map(normalizeText);
  const location = normalizeText(user.profile?.location);
  const modality = normalizeText(user.profile?.modality);
  const cvKeywords = user.cvAnalysis?.keywords || [];
  const education = String(user.profile?.education || '');
  const cvCareerTerms = cvKeywords.slice(0, 25).map(item => item.term || '');
  const careerSource = [education, ...skills, ...(user.profile?.skills || []), ...cvCareerTerms].join(' ');
  const careerTerms = new Set(keywordCounts(careerSource, 100).map(item => item.term));
  const candidateExperience = Math.max(0, Number(user.profile?.experience || 0));

  // Agrupación aproximada de carreras/áreas, además de la similitud textual del CV.
  const careerGroups = [
    { key: 'tecnologia', signals: ['tecnologia', 'informatica', 'computacion', 'sistemas', 'software', 'programacion', 'desarrollo web', 'flutter', 'javascript', 'sql', 'ciberseguridad', 'redes'] },
    { key: 'administracion', signals: ['administracion', 'administrativo', 'gestion empresarial', 'negocios', 'contabilidad', 'finanzas', 'economia', 'recursos humanos', 'reclutamiento'] },
    { key: 'diseno', signals: ['diseno', 'ux', 'ui', 'figma', 'photoshop', 'illustrator', 'diseno grafico'] },
    { key: 'datos', signals: ['analisis de datos', 'estadistica', 'power bi', 'tableau', 'data analysis', 'bases de datos'] },
    { key: 'salud', signals: ['salud', 'enfermeria', 'clinica', 'medicina', 'atencion sanitaria', 'terapia'] },
    { key: 'educacion', signals: ['educacion', 'docencia', 'ensenanza', 'pedagogia', 'docente', 'profesor'] },
    { key: 'logistica', signals: ['logistica', 'inventario', 'almacen', 'cadena de suministro', 'transporte'] },
    { key: 'marketing', signals: ['marketing', 'publicidad', 'comunicacion', 'redes sociales', 'contenido'] },
    { key: 'atencion', signals: ['atencion al cliente', 'servicio al cliente', 'ventas', 'soporte', 'mesa de ayuda', 'help desk'] },
    { key: 'proyectos', signals: ['gestion de proyectos', 'project management', 'scrum', 'agile'] }
  ];
  const candidateCareerText = normalizeText([education, ...skills, ...(user.profile?.skills || []), ...cvCareerTerms].join(' '));
  const candidateGroups = new Set(careerGroups
    .filter(group => group.signals.some(signal => candidateCareerText.includes(normalizeText(signal))))
    .map(group => group.key));

  const jobDocuments = jobs.map(job => {
    const requiredSkills = Array.isArray(job.requiredSkills) ? job.requiredSkills : [];
    const preferredSkills = Array.isArray(job.preferredSkills) ? job.preferredSkills : [];
    const content = [job.title, job.description, job.category, ...requiredSkills, ...preferredSkills].join(' ');
    const categoryTitleSkills = normalizeText([job.category, job.title, ...requiredSkills, ...preferredSkills].join(' '));
    const jobGroups = careerGroups
      .filter(group => group.signals.some(signal => categoryTitleSkills.includes(normalizeText(signal))))
      .map(group => group.key);
    return {
      job,
      requiredSkills,
      preferredSkills,
      content,
      categoryTitleSkills,
      jobGroups,
      keywords: keywordCounts(content, 200)
    };
  });

  const documentFrequency = new Map();
  for (const document of jobDocuments) {
    const uniqueTerms = new Set(document.keywords.map(item => item.term));
    for (const term of uniqueTerms) {
      documentFrequency.set(term, (documentFrequency.get(term) || 0) + 1);
    }
  }

  return jobDocuments.map(document => {
    const { job, requiredSkills, preferredSkills, categoryTitleSkills, jobGroups, keywords } = document;
    const jobText = normalizeText([
      job.title,
      job.description,
      job.category,
      job.modality,
      job.location,
      ...requiredSkills
    ].join(' '));
    const matchedSkills = skills.filter(skill => {
      const normalized = normalizeText(skill);
      return normalized.length > 1 && jobText.includes(normalized);
    });
    const matchedRequired = requiredSkills.filter(required => {
      const normalized = normalizeText(required);
      return normalized.length > 1 && normalizedSkills.some(skill =>
        skill.includes(normalized) || normalized.includes(skill)
      );
    });
    const matchedPreferred = preferredSkills.filter(preferred => {
      const normalized = normalizeText(preferred);
      return normalized.length > 1 && normalizedSkills.some(skill =>
        skill.includes(normalized) || normalized.includes(skill)
      );
    });
    const candidateTerms = new Set(cvKeywords.map(item => item.term));
    const sharedKeywords = keywords
      .filter(item => candidateTerms.has(item.term))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map(item => item.term);
    const matchedCareerTerms = keywords
      .filter(item => careerTerms.has(item.term))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map(item => item.term);
    const careerCategoryMatch = jobGroups.some(group => candidateGroups.has(group));

    const similarity = tfidfCosineSimilarity(
      cvKeywords,
      keywords,
      documentFrequency,
      Math.max(jobDocuments.length, 1)
    );
    const reasons = [];
    if (careerCategoryMatch) reasons.push('Área profesional relacionada con tu carrera o CV');
    if (matchedSkills.length) reasons.push('Habilidades relacionadas: ' + matchedSkills.slice(0, 4).join(', '));
    if (matchedPreferred.length) reasons.push('Habilidades deseables coincidentes: ' + matchedPreferred.slice(0, 4).join(', '));
    if (matchedCareerTerms.length) reasons.push('Coincidencias con tu CV: ' + matchedCareerTerms.slice(0, 4).join(', '));
    if (location && normalizeText(job.location).includes(location)) reasons.push('Coincide con tu ubicación preferida');
    if (modality && normalizeText(job.modality).includes(modality)) reasons.push('Coincide con tu modalidad preferida');

    const experienceRequired = Math.max(0, Number(job.experienceRequired || 0));
    const experienceGap = Math.max(0, experienceRequired - candidateExperience);
    const evidenceCount = matchedSkills.length + matchedRequired.length + matchedPreferred.length + sharedKeywords.length +
      matchedCareerTerms.length + (careerCategoryMatch ? 2 : 0);

    let score = Math.round(similarity * 60);
    if (matchedSkills.length) score = Math.max(score, Math.min(50, matchedSkills.length * 10));
    score += Math.min(20, matchedCareerTerms.length * 4);
    if (careerCategoryMatch) score += 15;
    if (matchedRequired.length) score += Math.min(10, matchedRequired.length * 3);
    // Las habilidades deseables suman menos puntos que los requisitos obligatorios.
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
    score = Math.max(0, Math.min(100, score));

    const record = job.toObject();
    return {
      ...record,
      matchScore: score,
      matchReasons: reasons,
      matchedSkills,
      matchedPreferredSkills: matchedPreferred,
      textSimilarity: Number(similarity.toFixed(4)),
      careerMatch: evidenceCount > 0,
      experienceFit: experienceGap === 0
    };
  })
    .filter(job => job.matchScore > 0 && job.careerMatch)
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, 10);
}

module.exports = { normalizeText, keywordCounts, tfidfCosineSimilarity, recommendJobsForUser };
