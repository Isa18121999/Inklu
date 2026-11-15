const app = document.getElementById('app');
const API_URL = 'https://inklu-api.onrender.com/api';
const logo = 'assets/logo.png';
let screen = 'home';
let role = localStorage.getItem('inklu_role') || '';
let profile = null, jobs = [], applications = [], companyJobs = [];
let candidateDraft = JSON.parse(localStorage.getItem('inklu_candidate_draft') || '{}');
let professionalProfile = JSON.parse(localStorage.getItem('inklu_professional_profile') || '{}');

const token = () => localStorage.getItem('inklu_token') || '';
const headers = () => token() ? { Authorization: `Bearer ${token()}` } : {};
async function api(path, options = {}) {
  const h = { ...headers(), ...(options.body ? {'Content-Type':'application/json'} : {}), ...(options.headers || {}) };
  const r = await fetch(`${API_URL}${path}`, {...options, headers:h});
  let data = {}; try { data = await r.json(); } catch (_) {}
  if (!r.ok) throw new Error(data.message || 'No se pudo completar la operación.');
  return data;
}
function esc(v=''){return String(v).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]));}
function go(s){screen=s; render(); window.scrollTo(0,0);}
function saveDraft(){localStorage.setItem('inklu_candidate_draft',JSON.stringify(candidateDraft));}
function saveProfessional(){localStorage.setItem('inklu_professional_profile',JSON.stringify(professionalProfile));}
function top(){return `<header class="topbar"><button class="back" onclick="go('home')">‹</button><div class="brand"><img src="${logo}" alt=""><span>INKLU</span></div><span></span></header>`;}
function progress(n){return `<div class="progress"><i class="${n>=1?'active':''}"></i><i class="${n>=2?'active':''}"></i><i class="${n>=3?'active':''}"></i></div>`;}
function field(label,id,type='text',value='',required=true){return `<div class="field"><label for="${id}">${label}</label><input id="${id}" name="${id}" type="${type}" value="${esc(value)}" ${required?'required':''}></div>`;}
function nav(active,who){return `<nav class="bottom"><button class="nav ${active==='home'?'active':''}" onclick="go('${who==='company'?'companyDash':'candidateDash'}')"><span>⌂</span>Inicio</button><button class="nav ${active==='jobs'?'active':''}" onclick="go('${who==='company'?'offer':'jobs'}')"><span>▣</span>${who==='company'?'Ofertas':'Empleos'}</button><button class="nav ${active==='apps'?'active':''}" onclick="loadApplications()"><span>✓</span>Postulaciones</button><button class="nav" onclick="logout()"><span>◯</span>Salir</button></nav>`;}
function notice(text,error=false){return `<div class="notice ${error?'success':''}">${esc(text)}</div>`;}

async function registerCandidateStep2(){
  const d=candidateDraft;
  const conadisYes=document.getElementById('conadisYes')?.checked;
  d.birth=document.getElementById('birth')?.value || '';
  d.address=document.getElementById('address')?.value || '';
  d.hasConadis=!!conadisYes;
  d.conadis=conadisYes ? (document.getElementById('conadis')?.value || '').trim() : '';
  saveDraft();
  if(conadisYes && !d.conadis){ alert('Ingresa tu número de CONADIS.'); return; }
  const payload={name:`${d.names} ${d.surnames}`.trim(),email:String(d.email).trim().toLowerCase(),phone:String(d.phone).replace(/\D/g,''),password:d.password,role:'candidate',country:'PE',accreditationType:conadisYes?'Carné CONADIS':'',accreditationNumber:d.conadis};
  try{
    const data=await api('/auth/register',{method:'POST',body:JSON.stringify(payload)});
    localStorage.setItem('inklu_token',data.token); localStorage.setItem('inklu_role','candidate'); role='candidate';
    go('candidate3');
  }catch(e){ document.getElementById('candidate2Error').innerHTML=notice(e.message,true); }
}
function startCandidate(form){
  const fd=new FormData(form);
  candidateDraft={names:fd.get('names'),surnames:fd.get('surnames'),email:fd.get('email'),phone:fd.get('phone'),password:fd.get('password')};
  saveDraft(); go('candidate2');
}
async function registerCompany(form){
  const fd=new FormData(form); const payload={name:String(fd.get('company')).trim(),email:String(fd.get('email')).trim().toLowerCase(),phone:String(fd.get('phone')).replace(/\D/g,''),password:fd.get('password'),role:'company',country:'PE',ruc:String(fd.get('ruc')).replace(/\D/g,'')};
  try{const data=await api('/auth/register',{method:'POST',body:JSON.stringify(payload)});localStorage.setItem('inklu_token',data.token);localStorage.setItem('inklu_role','company');role='company';go('company2');}catch(e){form.insertAdjacentHTML('beforeend',notice(e.message,true));}
}
async function login(form){const fd=new FormData(form);try{const data=await api('/auth/login',{method:'POST',body:JSON.stringify({email:String(fd.get('email')).trim().toLowerCase(),password:fd.get('password')})});localStorage.setItem('inklu_token',data.token);localStorage.setItem('inklu_role',data.user?.role||'candidate');role=data.user?.role||'candidate';await loadProfile();go(role==='company'?'companyDash':'candidateDash');}catch(e){form.insertAdjacentHTML('beforeend',notice(e.message,true));}}
async function loadProfile(){try{profile=await api('/profile/me');}catch(_){profile=null;}}
async function loadJobs(){try{const d=await api('/company/jobs');jobs=Array.isArray(d)?d:[];}catch(_){jobs=[];}}
async function loadCompanyJobs(){try{const d=await api('/company/my-jobs');companyJobs=Array.isArray(d)?d:[];}catch(_){companyJobs=[];}}
async function loadApplications(){try{const d=await api('/applications');applications=Array.isArray(d)?d:[];}catch(_){applications=[];}screen='applications';render();}
async function apply(jobId){if(jobId==='demo'){alert('Esta es una oferta de demostración.');return;}try{await api('/applications',{method:'POST',body:JSON.stringify({jobId})});alert('Postulación registrada correctamente.');await loadApplications();}catch(e){alert(e.message);}}
async function createJob(form){const fd=new FormData(form);const payload={title:fd.get('title'),description:fd.get('description'),modality:fd.get('modality'),location:fd.get('location'),contractType:fd.get('contractType'),salary:fd.get('salary')};try{await api('/company/jobs',{method:'POST',body:JSON.stringify(payload)});alert('Oferta publicada correctamente.');await loadCompanyJobs();go('companyDash');}catch(e){form.insertAdjacentHTML('beforeend',notice(e.message,true));}}
function logout(){localStorage.removeItem('inklu_token');localStorage.removeItem('inklu_role');role='';profile=null;go('home');}

function matchScore(job){
  const p=professionalProfile, text=`${job.title||''} ${job.description||''}`.toLowerCase(); let score=45;
  const skills=Array.isArray(p.skills)?p.skills:[]; const hits=skills.filter(s=>text.includes(String(s).toLowerCase())).length; score+=Math.min(30,hits*10);
  if(p.modality && String(job.modality||'').toLowerCase()===String(p.modality).toLowerCase()) score+=15;
  if(p.location && String(job.location||'').toLowerCase().includes(String(p.location).toLowerCase())) score+=10;
  return Math.min(99,Math.round(score));
}
function demoJobs(){return [{_id:'demo',title:'Asistente Administrativo',description:'Organización, atención y gestión de documentos.',companyId:{name:'Empresa Inclusiva'},modality:'Híbrido',location:'Lima, Perú'},{_id:'demo2',title:'Analista de Datos',description:'Excel, análisis de datos y reportes.',companyId:{name:'Intercorp'},modality:'Remoto',location:'Perú'}];}
function jobCard(j){const company=j.companyId?.name||j.company?.name||'Empresa';const score=matchScore(j);return `<article class="job"><div class="job-top"><div><h4>${esc(j.title||'Oferta laboral')}</h4><div class="meta">${esc(company)} · ${esc(j.modality||'Modalidad por definir')} · ${esc(j.location||'')}</div></div><strong>${score}% match</strong></div><p>${esc(j.description||'Oportunidad laboral inclusiva.')}</p><button class="btn secondary" onclick="apply('${esc(j._id||j.id||'')}')">Postularme</button></article>`;}
function filterJobs(q){const list=document.getElementById('jobList');if(!list)return;const query=String(q||'').toLowerCase();const data=(jobs.length?jobs:demoJobs()).filter(j=>`${j.title||''} ${j.description||''} ${j.companyId?.name||''}`.toLowerCase().includes(query));list.innerHTML=data.map(jobCard).join('')||notice('No encontramos ofertas con esa búsqueda.');}

function render(){let html='';
if(screen==='home')html=`<section class="phone hero"><img src="${logo}" alt="Logo INKLU"><h1>INKLU</h1><p>Talento, inclusión y oportunidades laborales</p><div class="actions"><button class="btn primary" onclick="go('role')">Empezar</button><button class="btn secondary" onclick="go('login')">Iniciar sesión</button></div></section>`;
if(screen==='role')html=`<section class="phone">${top()}<div class="content"><h1 class="title">¿Cómo quieres empezar?</h1><p class="subtitle">Elige el tipo de cuenta que mejor te describe.</p><button class="role-card" onclick="go('candidate1')"><div class="role-icon">👩🏻‍💻</div><div class="grow"><h3>Soy candidato</h3><p>Busco oportunidades laborales.</p></div><b>›</b></button><button class="role-card" onclick="go('company1')"><div class="role-icon">🏢</div><div class="grow"><h3>Soy empresa</h3><p>Busco talento diverso.</p></div><b>›</b></button></div></section>`;
if(screen==='login')html=`<section class="phone">${top()}<div class="content login-card"><h1 class="title">Iniciar sesión</h1><p class="subtitle">Accede a tu cuenta INKLU.</p><form onsubmit="event.preventDefault();login(this)">${field('Correo electrónico','email','email')}${field('Contraseña','password','password')}<button class="btn primary" style="width:100%">Ingresar</button></form></div></section>`;
if(screen==='candidate1')html=`<section class="phone">${top()}<div class="content">${progress(1)}<h1 class="title">Crear cuenta como candidato</h1><p class="subtitle">Completa tus datos para comenzar.</p><form onsubmit="event.preventDefault();startCandidate(this)">${field('Nombres','names')}${field('Apellidos','surnames')}${field('Correo electrónico','email','email')}${field('Teléfono','phone','tel')}${field('Contraseña','password','password')}<label class="check"><input type="checkbox" required> Acepto los términos y condiciones</label><button class="btn primary" style="width:100%">Siguiente</button></form></div></section>`;
if(screen==='candidate2')html=`<section class="phone">${top()}<div class="content">${progress(2)}<h1 class="title">Información personal</h1><p class="subtitle">Completa tus datos y acreditación.</p>${field('Fecha de nacimiento','birth','date',candidateDraft.birth||'')}${field('Dirección','address','text',candidateDraft.address||'')}<div class="field"><label>¿Cuentas con CONADIS?</label><div class="segmented"><label><input type="radio" name="hasConadis" id="conadisYes" onchange="toggleConadis(true)" ${candidateDraft.hasConadis?'checked':''}> Sí</label><label><input type="radio" name="hasConadis" onchange="toggleConadis(false)" ${candidateDraft.hasConadis===false?'checked':''}> No</label></div></div><div id="conadisWrap" class="field" style="display:${candidateDraft.hasConadis===false?'none':'block'}"><label for="conadis">Número de CONADIS</label><input id="conadis" value="${esc(candidateDraft.conadis||'')}"></div><div id="candidate2Error"></div><button class="btn primary" style="width:100%" onclick="registerCandidateStep2()">Siguiente</button></div></section>`;
if(screen==='candidate3')html=`<section class="phone">${top()}<div class="content">${progress(3)}<h1 class="title">Perfil profesional</h1><p class="subtitle">Estos datos se usarán para mejorar tu matching con ofertas.</p>${field('Formación académica','education','text',professionalProfile.education||'',false)}${field('Años de experiencia','experience','number',professionalProfile.experience||'',false)}<div class="field"><label for="skills">Habilidades</label><input id="skills" value="${esc((professionalProfile.skills||[]).join(', '))}" placeholder="Ej. Excel, Python, atención al cliente"></div><div class="field"><label for="modality">Modalidad preferida</label><select id="modality"><option value="">Cualquiera</option><option value="Remoto" ${professionalProfile.modality==='Remoto'?'selected':''}>Remoto</option><option value="Híbrido" ${professionalProfile.modality==='Híbrido'?'selected':''}>Híbrido</option><option value="Presencial" ${professionalProfile.modality==='Presencial'?'selected':''}>Presencial</option></select></div>${field('Ubicación preferida','location','text',professionalProfile.location||'',false)}<button class="btn primary" style="width:100%;margin-top:18px" onclick="finishProfessionalProfile()">Guardar perfil y ver oportunidades</button></div></section>`;
if(screen==='candidateDash')html=`<section class="phone">${top()}<div class="content"><h1 class="title">¡Hola, ${esc(profile?.name||candidateDraft.names||'candidato')}!</h1><p class="subtitle">Oportunidades recomendadas según tu perfil profesional.</p><div class="search"><input placeholder="Buscar empleos, empresas..." oninput="filterJobs(this.value)"><button class="icon-btn" onclick="loadJobs().then(render)">⌕</button></div><div class="notice"><b>Tu matching está activo</b><br>Las ofertas muestran un porcentaje de compatibilidad basado en tus habilidades, modalidad y ubicación.</div><div class="section-head"><h3>Empleos recomendados</h3><span class="link" onclick="go('jobs')">Ver todos</span></div>${(jobs.length?jobs.slice(0,4):demoJobs()).map(jobCard).join('')}</div>${nav('home','candidate')}</section>`;
if(screen==='jobs')html=`<section class="phone">${top()}<div class="content"><h1 class="title">Empleos</h1><p class="subtitle">Encuentra oportunidades disponibles.</p><div class="search"><input placeholder="Cargo, empresa o palabra clave" oninput="filterJobs(this.value)"><button class="icon-btn" onclick="loadJobs().then(render)">⌕</button></div><div id="jobList">${(jobs.length?jobs:demoJobs()).map(jobCard).join('')}</div></div>${nav('jobs','candidate')}</section>`;
if(screen==='company1')html=`<section class="phone">${top()}<div class="content">${progress(1)}<h1 class="title">Crear cuenta como empresa</h1><p class="subtitle">Ingresa los datos de tu organización.</p><form onsubmit="event.preventDefault();registerCompany(this)">${field('Nombre de la empresa','company')}${field('RUC','ruc')}${field('Correo institucional','email','email')}${field('Teléfono','phone','tel')}${field('Contraseña','password','password')}<label class="check"><input type="checkbox" required> Acepto los términos y condiciones</label><button class="btn primary" style="width:100%">Siguiente</button></form></div></section>`;
if(screen==='company2')html=`<section class="phone">${top()}<div class="content">${progress(2)}<h1 class="title">Información de la empresa</h1><p class="subtitle">Completa los datos de tu organización.</p><div class="field"><label>Sector</label><select><option>Tecnología</option><option>Servicios</option><option>Educación</option><option>Comercio</option></select></div>${field('Dirección','address')}${field('Sitio web','website','url')}<div class="field"><label>Descripción de la empresa</label><textarea placeholder="Cuéntanos sobre tu empresa..."></textarea></div><button class="btn primary" style="width:100%" onclick="go('company3')">Siguiente</button></div></section>`;
if(screen==='company3')html=`<section class="phone">${top()}<div class="content">${progress(3)}<h1 class="title">Información de contacto</h1><p class="subtitle">Datos de la persona de contacto.</p>${field('Nombre completo','contactName')}${field('Cargo','contactRole')}${field('Teléfono','contactPhone','tel')}${field('Correo electrónico','contactEmail','email')}<button class="btn primary" style="width:100%;margin-top:12px" onclick="go('companyDash')">Finalizar</button></div></section>`;
if(screen==='companyDash')html=`<section class="phone">${top()}<div class="content"><h1 class="title">¡Hola, ${esc(profile?.name||'empresa')}!</h1><p class="subtitle">Gestiona tus ofertas y conecta con talento diverso.</p><div class="stat-grid"><div class="stat"><b>${companyJobs.length}</b><small>Ofertas activas</small></div><div class="stat"><b>${applications.length}</b><small>Postulaciones</small></div><div class="stat"><b>—</b><small>En revisión</small></div></div><button class="btn primary" style="width:100%" onclick="go('offer')">＋ Crear nueva oferta</button><div class="section-head"><h3>Mis ofertas</h3><span class="link" onclick="loadCompanyJobs().then(render)">Actualizar</span></div>${companyJobs.map(j=>`<div class="job"><h4>${esc(j.title)}</h4><div class="meta">${esc(j.modality||'')} · ${esc(j.location||'')}</div></div>`).join('')||notice('Aún no tienes ofertas publicadas.')}</div>${nav('home','company')}</section>`;
if(screen==='offer')html=`<section class="phone">${top()}<div class="content"><h1 class="title">Crear nueva oferta</h1><p class="subtitle">Publica una oportunidad real en INKLU.</p><form onsubmit="event.preventDefault();createJob(this)">${field('Título del puesto','title')}${field('Descripción del puesto','description')}<div class="field"><label>Tipo de contrato</label><select name="contractType"><option>Tiempo completo</option><option>Medio tiempo</option><option>Prácticas</option></select></div><div class="field"><label>Modalidad</label><select name="modality"><option>Presencial</option><option>Híbrido</option><option>Remoto</option></select></div>${field('Ubicación','location','text','Lima, Perú')}${field('Salario (opcional)','salary','text','',false)}<button class="btn primary" style="width:100%">Publicar oferta</button></form></div></section>`;
if(screen==='applications')html=`<section class="phone">${top()}<div class="content"><h1 class="title">Postulaciones</h1><p class="subtitle">Consulta el estado de tus procesos.</p>${applications.map(a=>`<div class="job"><h4>${esc(a.jobId?.title||a.job?.title||'Postulación')}</h4><div class="meta">Estado: ${esc(a.status||'Enviada')}</div></div>`).join('')||notice('Todavía no tienes postulaciones.')}</div>${nav('apps',role||'candidate')}</section>`;
app.innerHTML=html;
}
function toggleConadis(show){const w=document.getElementById('conadisWrap');if(w)w.style.display=show?'block':'none';candidateDraft.hasConadis=show;saveDraft();}
function finishProfessionalProfile(){professionalProfile={education:document.getElementById('education').value,experience:document.getElementById('experience').value,skills:document.getElementById('skills').value.split(',').map(s=>s.trim()).filter(Boolean),modality:document.getElementById('modality').value,location:document.getElementById('location').value};saveProfessional();go('candidateDash');loadJobs().then(render);}
async function init(){if(token()){await loadProfile();if(role==='candidate')await loadJobs();if(role==='company')await loadCompanyJobs();}render();}
window.addEventListener('load',init);
