// Mejoras de INKLU: flujo visual + matching de ofertas + CONADIS obligatorio + perfil persistente.
(function(){
  const API_URL = 'https://inklu-api.onrender.com/api';
  const normalize = (v='') => String(v).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').trim();
  const list = (v) => Array.isArray(v) ? v : String(v||'').split(',').map(s=>s.trim()).filter(Boolean);
  const profile = () => { try { return JSON.parse(localStorage.getItem('inklu_professional_profile') || '{}'); } catch (_) { return {}; } };
  const token = () => localStorage.getItem('inklu_token') || '';

  // Matching ponderado: habilidades 50%, modalidad 20%, ubicación 15%, experiencia 15%.
  window.matchScore = function(job){
    const p = profile();
    const title = normalize(job.title);
    const description = normalize(job.description);
    const requirements = normalize(job.requirements || job.requiredSkills || job.skills || '');
    const text = `${title} ${description} ${requirements}`;
    const skills = list(p.skills).map(normalize).filter(Boolean);
    const matched = skills.filter(skill => text.includes(skill));
    let score = skills.length ? (matched.length / skills.length) * 50 : 25;

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

  // El CONADIS es requisito obligatorio: no se muestra selector Sí/No.
  function enforceConadisField(){
    const title = Array.from(document.querySelectorAll('h1,h2,h3')).find(el => normalize(el.textContent).includes('informacion personal'));
    if(!title) return;
    const segmented = document.querySelector('.segmented');
    if(!segmented) return;
    const wrapper = segmented.closest('.field');
    if(!wrapper) return;
    wrapper.outerHTML = '<div class="field"><label for="conadis">Número de CONADIS *</label><input id="conadis" name="conadis" inputmode="numeric" autocomplete="off" required><small>El número de CONADIS es obligatorio para crear tu cuenta en INKLU.</small></div>';
    const old = document.querySelector('#conadis');
    const draft = (()=>{try{return JSON.parse(localStorage.getItem('inklu_candidate_draft')||'{}')}catch(_){return {}}})();
    if(old && draft.conadis) old.value = draft.conadis;
  }

  // Reemplaza la función original para exigir CONADIS antes de registrar al candidato.
  window.registerCandidateStep2 = async function(){
    const draft = (()=>{try{return JSON.parse(localStorage.getItem('inklu_candidate_draft')||'{}')}catch(_){return {}}})();
    draft.birth = document.getElementById('birth')?.value || '';
    draft.address = document.getElementById('address')?.value || '';
    draft.conadis = (document.getElementById('conadis')?.value || '').trim();
    localStorage.setItem('inklu_candidate_draft', JSON.stringify(draft));

    const errorBox = document.getElementById('candidate2Error');
    if(!draft.conadis){
      if(errorBox) errorBox.innerHTML = '<div class="notice success">El número de CONADIS es obligatorio para continuar.</div>';
      document.getElementById('conadis')?.focus();
      return;
    }
    if(!/^[A-Za-z0-9-]{5,30}$/.test(draft.conadis)){
      if(errorBox) errorBox.innerHTML = '<div class="notice success">Ingresa un número de CONADIS válido.</div>';
      document.getElementById('conadis')?.focus();
      return;
    }

    const payload = {
      name: `${draft.names || ''} ${draft.surnames || ''}`.trim(),
      email: String(draft.email || '').trim().toLowerCase(),
      phone: String(draft.phone || '').replace(/\D/g,''),
      password: draft.password,
      role: 'candidate',
      country: 'PE',
      accreditationType: 'Carné CONADIS',
      accreditationNumber: draft.conadis
    };

    try{
      const r = await fetch(`${API_URL}/auth/register`, {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body:JSON.stringify(payload)
      });
      let data={}; try{data=await r.json();}catch(_){ }
      if(!r.ok) throw new Error(data.message || 'No se pudo completar el registro.');
      localStorage.setItem('inklu_token', data.token || '');
      localStorage.setItem('inklu_role', 'candidate');
      if(typeof window.go === 'function') window.go('candidate3');
    }catch(e){
      if(errorBox) errorBox.innerHTML = `<div class="notice success">${String(e.message || 'No se pudo registrar la cuenta.').replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]))}</div>`;
    }
  };

  // Guarda el perfil profesional también en MongoDB, no solo en localStorage.
  window.finishProfessionalProfile = async function(){
    const professionalProfile = {
      education: document.getElementById('education')?.value?.trim() || '',
      experience: Number(document.getElementById('experience')?.value || 0),
      skills: list(document.getElementById('skills')?.value || ''),
      modality: document.getElementById('modality')?.value || '',
      location: document.getElementById('location')?.value?.trim() || ''
    };

    localStorage.setItem('inklu_professional_profile', JSON.stringify(professionalProfile));

    if(!token()){
      const box = document.getElementById('candidate3Error');
      if(box) box.innerHTML = '<div class="notice success">Tu sesión expiró. Inicia sesión nuevamente para guardar el perfil.</div>';
      return;
    }

    try{
      const r = await fetch(`${API_URL}/profile/me`, {
        method:'PATCH',
        headers:{'Content-Type':'application/json', Authorization:`Bearer ${token()}`},
        body:JSON.stringify(professionalProfile)
      });
      let data={}; try{data=await r.json();}catch(_){ }
      if(!r.ok) throw new Error(data.message || 'No se pudo guardar el perfil.');

      localStorage.setItem('inklu_professional_profile', JSON.stringify(data.profile || professionalProfile));
      if(typeof window.loadProfile === 'function') await window.loadProfile();
      if(typeof window.loadJobs === 'function') await window.loadJobs();
      if(typeof window.go === 'function') window.go('candidateDash');
    }catch(e){
      const box = document.getElementById('candidate3Error');
      if(box) box.innerHTML = `<div class="notice success">${String(e.message || 'No se pudo guardar el perfil.').replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]))}</div>`;
      else alert(e.message || 'No se pudo guardar el perfil.');
    }
  };

  const observer = new MutationObserver(() => enforceConadisField());
  window.addEventListener('DOMContentLoaded', () => observer.observe(document.body,{childList:true,subtree:true}));
  window.addEventListener('load', () => {
    window.__inkluWebFix = true;
    enforceConadisField();
    if (typeof window.render === 'function') window.render();
  });
})();
