// Mejoras de INKLU: flujo visual + matching de ofertas.
(function(){
  const normalize = (v='') => String(v).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').trim();
  const list = (v) => Array.isArray(v) ? v : String(v||'').split(',').map(s=>s.trim()).filter(Boolean);

  // Matching ponderado: habilidades 50%, modalidad 20%, ubicación 15%, experiencia 15%.
  window.matchScore = function(job){
    const p = window.professionalProfile || {};
    const title = normalize(job.title);
    const description = normalize(job.description);
    const requirements = normalize(job.requirements || job.requiredSkills || job.skills || '');
    const text = `${title} ${description} ${requirements}`;
    const skills = list(p.skills).map(normalize);
    const validSkills = skills.filter(Boolean);
    const matched = validSkills.filter(skill => text.includes(skill));
    let score = validSkills.length ? (matched.length / validSkills.length) * 50 : 25;

    const wantedModality = normalize(p.modality);
    const jobModality = normalize(job.modality);
    if (!wantedModality) score += 10;
    else if (jobModality === wantedModality) score += 20;
    else if (jobModality.includes(wantedModality) || wantedModality.includes(jobModality)) score += 10;

    const wantedLocation = normalize(p.location);
    const jobLocation = normalize(job.location);
    if (!wantedLocation) score += 7.5;
    else if (jobLocation && (jobLocation.includes(wantedLocation) || wantedLocation.includes(jobLocation))) score += 15;

    const candidateExperience = Number(p.experience);
    const requiredExperience = Number(job.experienceRequired || job.requiredExperience || job.minExperience);
    if (!Number.isNaN(candidateExperience) && !Number.isNaN(requiredExperience) && requiredExperience > 0) {
      score += Math.min(15, Math.max(0, candidateExperience / requiredExperience * 15));
    } else {
      score += 7.5;
    }

    return Math.min(99, Math.max(0, Math.round(score)));
  };

  window.addEventListener('load', () => {
    window.__inkluWebFix = true;
    // Recalcula las tarjetas después de sustituir el algoritmo de matching.
    if (typeof window.render === 'function') window.render();
  });
})();
