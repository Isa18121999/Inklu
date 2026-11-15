function clean(value, max = 500) {
  return String(value ?? '').replace(/[<>\r\n]+/g, ' ').replace(/\s+/g, ' ').trim().slice(0, max);
}

function buildCoverLetter(candidate, job) {
  const profile = candidate.profile || {};
  const company = job.companyId && typeof job.companyId === 'object' ? job.companyId.name : '';
  const skills = [...new Set([...(candidate.cvAnalysis?.skills || []), ...(profile.skills || [])].map(item => clean(item)).filter(Boolean))].slice(0, 6);
  const summary = clean(profile.professionalSummary, 700);
  const education = clean(profile.education, 240);
  const projects = Array.isArray(profile.projects) ? profile.projects.map(item => clean(item, 160)).filter(Boolean).slice(0, 2) : [];
  const experience = Number(profile.experience) > 0 ? `${Number(profile.experience)} año(s) de experiencia` : '';
  const highlights = [education, experience, skills.length ? `mis habilidades en ${skills.join(', ')}` : '', projects.length ? `mis proyectos, como ${projects.join(' y ')}` : ''].filter(Boolean);
  return [
    'Estimado equipo de selección' + (company ? ` de ${company}` : '') + ':',
    '',
    `Me gustaría expresar mi interés en la posición de ${clean(job.title, 160)}. Me motiva la posibilidad de contribuir con mis conocimientos y seguir desarrollándome profesionalmente en su organización.`,
    summary || (highlights.length ? `Mi perfil incluye ${highlights.join('; ')}.` : 'Cuento con disposición para aportar, aprender y colaborar con el equipo.'),
    highlights.length && summary ? `Además, puedo aportar ${highlights.join('; ')}.` : '',
    '',
    `He revisado la descripción de la vacante y considero que puedo contribuir a sus responsabilidades. Agradecería la oportunidad de conversar sobre cómo mi perfil puede responder a las necesidades del puesto.`,
    '',
    'Muchas gracias por su tiempo y consideración.',
    '',
    'Atentamente,',
    clean(candidate.name, 100) || 'Postulante'
  ].filter(Boolean).join('\n');
}

module.exports = { buildCoverLetter };
