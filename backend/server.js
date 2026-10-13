require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('./models/User');
const Job = require('./models/Job');
const Application = require('./models/Application');
const ChatMessage = require('./models/ChatMessage');
const { PDFParse } = require('pdf-parse');
const mammoth = require('mammoth');

const app = express();
const PORT = process.env.PORT || 10000;
const JWT_SECRET = process.env.JWT_SECRET || 'change-this-secret-in-render';
const MAX_CV_BYTES = 5 * 1024 * 1024;

app.use(cors({ origin: process.env.FRONTEND_ORIGIN || '*', methods: ['GET','POST','PATCH','OPTIONS'], allowedHeaders: ['Content-Type','Authorization'] }));
app.use(express.json({ limit: '8mb' }));

function normalizeConadis(value) { return String(value || '').replace(/\s+/g, '').trim(); }
function validConadis(value) { return /^[A-Za-z0-9-]{5,30}$/.test(value); }
function tokenFor(user) { return jwt.sign({ id: user._id.toString(), role: user.role }, JWT_SECRET, { expiresIn: '7d' }); }

async function auth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    if (!header.startsWith('Bearer ')) return res.status(401).json({ message: 'Sesión requerida.' });
    const payload = jwt.verify(header.slice(7), JWT_SECRET);
    const user = await User.findById(payload.id);
    if (!user) return res.status(401).json({ message: 'Usuario no encontrado.' });
    req.user = user;
    next();
  } catch (_) { return res.status(401).json({ message: 'Token inválido o expirado.' }); }
}

function publicUser(user, { includeSensitive = false } = {}) {
  const data = { id: user._id, name: user.name, email: user.email, phone: user.phone, role: user.role, country: user.country, ruc: user.ruc, profile: user.profile };
  if (includeSensitive && user.role === 'candidate') {
    data.conadisNumber = user.conadisNumber;
    data.hasCv = Boolean(user.cv?.data?.length);
    data.cvFileName = user.cv?.fileName || null;
    data.cvAnalysis = user.cvAnalysis ? {
      skills: user.cvAnalysis.skills || [],
      analyzedAt: user.cvAnalysis.analyzedAt || null,
      textLength: user.cvAnalysis.textLength || 0
    } : null;
  }
  return data;
}

const CV_SKILL_CATALOG = [
  { label: 'Excel', terms: ['excel', 'hojas de calculo', 'spreadsheet'] },
  { label: 'Microsoft Office', terms: ['microsoft office', 'word', 'powerpoint', 'office'] },
  { label: 'Atención al cliente', terms: ['atencion al cliente', 'servicio al cliente', 'customer service'] },
  { label: 'Ventas', terms: ['ventas', 'venta', 'sales', 'comercial'] },
  { label: 'Marketing digital', terms: ['marketing digital', 'seo', 'sem', 'campanas digitales', 'social media'] },
  { label: 'Comunicación', terms: ['comunicacion', 'redaccion', 'presentaciones'] },
  { label: 'Administración', terms: ['administracion', 'administrativo', 'gestion administrativa'] },
  { label: 'Contabilidad', terms: ['contabilidad', 'contable', 'tributacion', 'niif'] },
  { label: 'Finanzas', terms: ['finanzas', 'analisis financiero', 'presupuestos'] },
  { label: 'Programación', terms: ['programacion', 'desarrollo de software', 'coding'] },
  { label: 'Python', terms: ['python'] },
  { label: 'JavaScript', terms: ['javascript', 'typescript', 'node.js', 'nodejs'] },
  { label: 'SQL y bases de datos', terms: ['sql', 'mysql', 'postgresql', 'mongodb', 'bases de datos'] },
  { label: 'Desarrollo web', terms: ['html', 'css', 'react', 'angular', 'vue', 'desarrollo web'] },
  { label: 'Flutter', terms: ['flutter', 'dart', 'aplicaciones moviles', 'android'] },
  { label: 'Diseño UX/UI', terms: ['ux/ui', 'ux', 'ui', 'figma', 'experiencia de usuario'] },
  { label: 'Diseño gráfico', terms: ['diseno grafico', 'photoshop', 'illustrator', 'canva'] },
  { label: 'Análisis de datos', terms: ['analisis de datos', 'power bi', 'tableau', 'estadistica', 'data analysis'] },
  { label: 'Soporte técnico', terms: ['soporte tecnico', 'mesa de ayuda', 'help desk', 'helpdesk'] },
  { label: 'Redes y sistemas', terms: ['redes', 'linux', 'windows server', 'ciberseguridad', 'infraestructura'] },
  { label: 'Recursos humanos', terms: ['recursos humanos', 'seleccion de personal', 'reclutamiento', 'talent acquisition'] },
  { label: 'Gestión de proyectos', terms: ['gestion de proyectos', 'scrum', 'agile', 'project management'] },
  { label: 'Logística', terms: ['logistica', 'inventario', 'cadena de suministro', 'almacen'] },
  { label: 'Educación', terms: ['educacion', 'docencia', 'ensenanza', 'pedagogia'] },
  { label: 'Salud', terms: ['enfermeria', 'salud', 'clinica', 'atencion sanitaria'] },
  { label: 'Inglés', terms: ['ingles', 'english', 'bilingual'] },
];

function normalizeText(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

const CV_STOP_WORDS = new Set((
  'para como con por una uno unas unos las los del que de en al el y o a se su sus es son fue ser está estar ' +
  'the and for with from this that are was were you your our their have has had not but can will about after before ' +
  'perfil curriculum currículum cv candidato candidata empresa empleo trabajo profesional profesionales experiencia ' +
  'experiencias habilidades conocimiento conocimientos funciones responsabilidades objetivo datos persona personal ' +
  'años ano año años mes meses equipo equipos puesto posición cargo laboral laborales'
).split(/\\s+/));

function keywordCounts(text, limit = 60) {
  const tokens = normalizeText(text).match(/[a-z0-9+#.]{3,}/g) || [];
  const counts = new Map();
  for (const token of tokens) {
    if (CV_STOP_WORDS.has(token) || /^\\d+$/.test(token)) continue;
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

function normalizeApplicationStatus(status) {
  const legacy = {
    'Postulada': 'Postulado',
    'En revisión': 'CV visto',
    'Entrevista': 'En proceso',
    'Seleccionada': 'Aceptado',
    'No seleccionada': 'Proceso terminado'
  };
  return legacy[status] || status || 'Postulado';
}

function chatIsEnabled(status) {
  return ['En proceso', 'Aceptado', 'Proceso terminado'].includes(
    normalizeApplicationStatus(status)
  );
}

async function analyzeCandidateCv(user) {
  if (user.role !== 'candidate') {
    const error = new Error('Solo los candidatos pueden analizar un CV.');
    error.statusCode = 403;
    throw error;
  }
  if (!user.cv?.data?.length) {
    const error = new Error('Primero debes subir un CV desde tu perfil.');
    error.statusCode = 400;
    throw error;
  }

  const uploadedAt = user.cv.uploadedAt ? new Date(user.cv.uploadedAt) : new Date();
  const cached = user.cvAnalysis;
  if (
    cached?.sourceUploadedAt &&
    new Date(cached.sourceUploadedAt).getTime() === uploadedAt.getTime()
  ) {
    return {
      skills: cached.skills || [],
      keywords: cached.keywords || [],
      textLength: cached.textLength || 0,
      analyzedAt: cached.analyzedAt,
      cached: true
    };
  }

  const buffer = Buffer.from(user.cv.data);
  const extension = String(user.cv.fileName || '').toLowerCase().split('.').pop();
  let text = '';

  try {
    if (extension === 'pdf') {
      const parser = new PDFParse({ data: buffer });
      try {
        const result = await parser.getText();
        text = result.text || '';
      } finally {
        await parser.destroy();
      }
    } else if (extension === 'docx') {
      const result = await mammoth.extractRawText({ buffer });
      text = result.value || '';
    } else if (extension === 'doc') {
      // Extract readable text from legacy DOC files; PDF/DOCX produce better results.
      text = buffer.toString('latin1').replace(/[^\x20-\x7E\u00A0-\u00FF\n\r\t]/g, ' ');
    } else {
      const error = new Error('Formato no compatible para analizar el CV.');
      error.statusCode = 415;
      throw error;
    }
  } catch (cause) {
    if (cause.statusCode) throw cause;
    const error = new Error('No se pudo leer el CV. Prueba con un PDF con texto seleccionable o un archivo DOCX.');
    error.statusCode = 422;
    throw error;
  }

  text = String(text).replace(/\s+/g, ' ').trim();
  if (text.length < 30) {
    const error = new Error('No encontramos suficiente texto en el CV. Sube un PDF con texto seleccionable o un archivo DOCX.');
    error.statusCode = 422;
    throw error;
  }

  const normalized = normalizeText(text);
  const skills = CV_SKILL_CATALOG
    .filter(skill => skill.terms.some(term => normalized.includes(normalizeText(term))))
    .map(skill => skill.label);
  const keywords = keywordCounts(text, 60);

  user.cvAnalysis = {
    skills,
    keywords,
    textLength: text.length,
    analyzedAt: new Date(),
    sourceUploadedAt: uploadedAt
  };
  await user.save();

  return { skills, keywords, textLength: text.length, analyzedAt: user.cvAnalysis.analyzedAt, cached: false };
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
  const jobDocuments = jobs.map(job => {
    const requiredSkills = Array.isArray(job.requiredSkills) ? job.requiredSkills : [];
    const content = [job.title, job.description, ...requiredSkills].join(' ');
    return { job, requiredSkills, content, keywords: keywordCounts(content, 200) };
  });
  const documentFrequency = new Map();
  for (const document of jobDocuments) {
    const uniqueTerms = new Set(document.keywords.map(item => item.term));
    for (const term of uniqueTerms) {
      documentFrequency.set(term, (documentFrequency.get(term) || 0) + 1);
    }
  }

  return jobDocuments.map(document => {
    const { job, requiredSkills, content, keywords } = document;
    const jobText = normalizeText([
      job.title,
      job.description,
      job.modality,
      job.location,
      ...requiredSkills
    ].join(' '));
    const matchedSkills = skills.filter(skill => jobText.includes(normalizeText(skill)));
    const matchedRequired = requiredSkills.filter(required =>
      normalizedSkills.some(skill =>
        skill.includes(normalizeText(required)) || normalizeText(required).includes(skill)
      )
    );
    const candidateTerms = new Set(cvKeywords.map(item => item.term));
    const sharedKeywords = keywords
      .filter(item => candidateTerms.has(item.term))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map(item => item.term);

    const similarity = tfidfCosineSimilarity(
      cvKeywords,
      keywords,
      documentFrequency,
      Math.max(jobDocuments.length, 1)
    );
    const reasons = [];
    if (matchedSkills.length) reasons.push('Habilidades relacionadas: ' + matchedSkills.slice(0, 4).join(', '));
    if (sharedKeywords.length) reasons.push('Palabras coincidentes: ' + sharedKeywords.slice(0, 4).join(', '));
    if (location && normalizeText(job.location).includes(location)) reasons.push('Coincide con tu ubicación preferida');
    if (modality && normalizeText(job.modality).includes(modality)) reasons.push('Coincide con tu modalidad preferida');

    let score = Math.round(similarity * 75);
    if (matchedSkills.length) {
      score = Math.max(score, Math.round((matchedSkills.length / Math.min(skills.length, 5)) * 65));
    }
    if (matchedRequired.length) score += Math.min(15, matchedRequired.length * 5);
    if (location && normalizeText(job.location).includes(location)) score += 5;
    if (modality && normalizeText(job.modality).includes(modality)) score += 5;
    score = Math.min(100, score);

    const record = job.toObject();
    return {
      ...record,
      matchScore: score,
      matchReasons: reasons,
      matchedSkills,
      textSimilarity: Number(similarity.toFixed(4))
    };
  })
    .filter(job => job.matchScore > 0)
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, 10);
}

async function findChatApplication(req, res) {
  const application = await Application.findById(req.params.id).populate('jobId');
  if (!application || !application.jobId) {
    res.status(404).json({ message: 'Postulación no encontrada.' });
    return null;
  }
  const isCandidate = String(application.candidateId) === String(req.user._id);
  const isCompany = String(application.jobId.companyId) === String(req.user._id);
  if (!isCandidate && !isCompany) {
    res.status(403).json({ message: 'No tienes acceso a esta conversación.' });
    return null;
  }
  if (!chatIsEnabled(application.status)) {
    res.status(403).json({ message: 'El chat se habilita cuando la postulación llega a “En proceso”.' });
    return null;
  }
  return application;
}

app.get('/api/health', (req, res) => res.json({ ok: true, service: 'INKLU API' }));

app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, phone, password, role, country, ruc, accreditationType, accreditationNumber } = req.body || {};
    if (!name || !email || !password || !role) return res.status(400).json({ message: 'Completa los campos obligatorios.' });
    if (!['candidate', 'company'].includes(role)) return res.status(400).json({ message: 'Tipo de cuenta inválido.' });
    if (password.length < 8) return res.status(400).json({ message: 'La contraseña debe tener al menos 8 caracteres.' });
    const normalizedEmail = String(email).trim().toLowerCase();
    if (await User.exists({ email: normalizedEmail })) return res.status(409).json({ message: 'El correo electrónico ya está registrado.' });
    let conadisNumber = null;
    if (role === 'candidate') {
      conadisNumber = normalizeConadis(accreditationNumber);
      if (!conadisNumber) return res.status(400).json({ message: 'El número de CONADIS es obligatorio para registrarte como candidato.' });
      if (!validConadis(conadisNumber)) return res.status(400).json({ message: 'El número de CONADIS no tiene un formato válido.' });
      if (await User.exists({ conadisNumber })) return res.status(409).json({ message: 'Este número de CONADIS ya está registrado.' });
    }
    const passwordHash = await bcrypt.hash(password, 12);
    const user = await User.create({ name: String(name).trim(), email: normalizedEmail, phone: String(phone || '').trim(), passwordHash, role, country: country || 'PE', ruc: role === 'company' ? String(ruc || '').trim() : undefined, conadisNumber, accreditationType: role === 'candidate' ? (accreditationType || 'Carné CONADIS') : undefined });
    return res.status(201).json({ token: tokenFor(user), user: publicUser(user, { includeSensitive: true }) });
  } catch (e) {
    if (e?.code === 11000) {
      if (e.keyPattern?.conadisNumber) return res.status(409).json({ message: 'Este número de CONADIS ya está registrado.' });
      if (e.keyPattern?.email) return res.status(409).json({ message: 'El correo electrónico ya está registrado.' });
    }
    console.error(e); return res.status(500).json({ message: 'No se pudo crear la cuenta.' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password, user.passwordHash))) return res.status(401).json({ message: 'Correo o contraseña incorrectos.' });
    return res.json({ token: tokenFor(user), user: publicUser(user, { includeSensitive: user.role === 'candidate' }) });
  } catch (e) { console.error(e); return res.status(500).json({ message: 'No se pudo iniciar sesión.' }); }
});

app.post('/api/profile/cv', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden subir un CV.' });
    const { fileName, mimeType, data } = req.body || {};
    if (!fileName || !data) return res.status(400).json({ message: 'Selecciona un archivo CV.' });
    const extension = String(fileName).toLowerCase().split('.').pop();
    if (!['pdf','doc','docx'].includes(extension)) return res.status(400).json({ message: 'El CV debe ser PDF, DOC o DOCX.' });
    const buffer = Buffer.from(String(data), 'base64');
    if (!buffer.length) return res.status(400).json({ message: 'El archivo CV está vacío.' });
    if (buffer.length > MAX_CV_BYTES) return res.status(413).json({ message: 'El CV supera el tamaño máximo de 5 MB.' });
    req.user.cv = { fileName: String(fileName).trim(), mimeType: String(mimeType || 'application/octet-stream'), data: buffer, size: buffer.length, uploadedAt: new Date() };
    await req.user.save();
    res.json({ message: 'CV guardado correctamente.', fileName: req.user.cv.fileName, size: buffer.length });
  } catch (e) { console.error(e); res.status(500).json({ message: 'No se pudo guardar el CV.' }); }
});

app.get('/api/profile/cv', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate' || !req.user.cv?.data?.length) return res.status(404).json({ message: 'No hay un CV registrado.' });
    res.set('Content-Type', req.user.cv.mimeType || 'application/octet-stream');
    res.set('Content-Disposition', `attachment; filename="${String(req.user.cv.fileName || 'CV').replace(/"/g, '')}"`);
    res.send(req.user.cv.data);
  } catch (e) { console.error(e); res.status(500).json({ message: 'No se pudo descargar el CV.' }); }
});

app.post('/api/profile/cv/analyze', auth, async (req, res) => {
  try {
    const analysis = await analyzeCandidateCv(req.user);
    res.json({
      message: analysis.cached ? 'El CV ya estaba analizado.' : 'CV analizado correctamente.',
      skills: analysis.skills,
      keywords: (analysis.keywords || []).slice(0, 12).map(item => item.term),
      textLength: analysis.textLength,
      analyzedAt: analysis.analyzedAt,
      cached: analysis.cached,
      engine: 'skill-match-mvp'
    });
  } catch (e) {
    res.status(e.statusCode || 500).json({
      message: e.statusCode ? e.message : 'No se pudo analizar el CV.'
    });
  }
});

app.get('/api/profile/me', auth, async (req, res) => res.json(publicUser(req.user, { includeSensitive: true })));
app.patch('/api/profile/me', auth, async (req, res) => {
  try {
    const allowed = ['birth', 'address', 'education', 'experience', 'skills', 'modality', 'location'];
    const updates = {};
    for (const key of allowed) if (Object.prototype.hasOwnProperty.call(req.body || {}, key)) updates[`profile.${key}`] = req.body[key];
    if (Object.keys(updates).length === 0) return res.status(400).json({ message: 'No hay datos de perfil para actualizar.' });
    const user = await User.findByIdAndUpdate(req.user._id, { $set: updates }, { new: true, runValidators: true });
    res.json(publicUser(user, { includeSensitive: true }));
  } catch (e) { console.error(e); res.status(500).json({ message: 'No se pudo actualizar el perfil.' }); }
});

app.get('/api/recommendations', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Las recomendaciones están disponibles para candidatos.' });
    const analysis = await analyzeCandidateCv(req.user);
    const jobs = await Job.find({ active: true }).populate('companyId', 'name').sort({ createdAt: -1 });
    const recommendations = recommendJobsForUser(req.user, jobs);
    res.json({
      engine: 'skill-match-mvp',
      cvSkills: analysis.skills,
      recommendations,
      message: analysis.skills.length
        ? 'Ofertas ordenadas por coincidencia entre las habilidades del CV y los requisitos.'
        : 'No detectamos habilidades conocidas en el CV. Puedes revisar todas las ofertas mientras mejoras el documento.'
    });
  } catch (e) {
    res.status(e.statusCode || 500).json({ message: e.statusCode ? e.message : 'No se pudieron calcular las recomendaciones.' });
  }
});

app.get('/api/company/jobs', auth, async (req, res) => { const jobs = await Job.find({ active: true }).populate('companyId', 'name').sort({ createdAt: -1 }); res.json(jobs); });
app.get('/api/company/my-jobs', auth, async (req, res) => { if (req.user.role !== 'company') return res.status(403).json({ message: 'Solo las empresas pueden consultar sus ofertas.' }); const jobs = await Job.find({ companyId: req.user._id }).sort({ createdAt: -1 }); res.json(jobs); });
app.post('/api/company/jobs', auth, async (req, res) => {
  try {
    if (req.user.role !== 'company') return res.status(403).json({ message: 'Solo las empresas pueden publicar ofertas.' });
    const { title, description, modality, location, contractType, salary, requiredSkills, experienceRequired } = req.body || {};
    if (!title || !description) return res.status(400).json({ message: 'El título y la descripción son obligatorios.' });
    const skills = Array.isArray(requiredSkills) ? requiredSkills : String(requiredSkills || '').split(',').map(s => s.trim()).filter(Boolean);
    const job = await Job.create({ companyId: req.user._id, title, description, modality, location, contractType, salary, requiredSkills: skills, experienceRequired: Number(experienceRequired || 0) });
    res.status(201).json(job);
  } catch (e) { console.error(e); res.status(500).json({ message: 'No se pudo publicar la oferta.' }); }
});
app.get('/api/applications', auth, async (req, res) => {
  let filter = {};
  if (req.user.role === 'candidate') filter.candidateId = req.user._id;
  else filter.jobId = { $in: (await Job.find({ companyId: req.user._id }).select('_id')).map(j => j._id) };
  const applications = await Application.find(filter)
    .populate('candidateId', 'name email phone profile cvAnalysis')
    .populate({ path: 'jobId', populate: { path: 'companyId', select: 'name' } })
    .sort({ createdAt: -1 });
  res.json(applications.map(application => {
    const record = application.toObject();
    record.status = normalizeApplicationStatus(record.status);
    return record;
  }));
});
app.post('/api/applications', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden postularse.' });
    const job = await Job.findOne({ _id: req.body?.jobId, active: true });
    if (!job) return res.status(404).json({ message: 'La oferta no existe o ya no está disponible.' });
    const application = await Application.create({ jobId: job._id, candidateId: req.user._id });
    res.status(201).json(application);
  } catch (e) { if (e?.code === 11000) return res.status(409).json({ message: 'Ya te postulaste a esta oferta.' }); console.error(e); res.status(500).json({ message: 'No se pudo registrar la postulación.' }); }
});
app.patch('/api/applications/:id/status', auth, async (req, res) => {
  try {
    if (req.user.role !== 'company') return res.status(403).json({ message: 'Solo las empresas pueden actualizar el proceso.' });
    const application = await Application.findById(req.params.id).populate('jobId');
    if (!application || !application.jobId || String(application.jobId.companyId) !== String(req.user._id)) {
      return res.status(404).json({ message: 'Postulación no encontrada.' });
    }
    const allowed = ['Postulado', 'CV visto', 'En proceso', 'Aceptado', 'Proceso terminado'];
    if (!allowed.includes(req.body?.status)) return res.status(400).json({ message: 'Etapa de postulación inválida.' });
    application.status = req.body.status;
    await application.save();
    res.json({ ...application.toObject(), status: normalizeApplicationStatus(application.status) });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'No se pudo actualizar el estado.' });
  }
});

app.get('/api/applications/:id/messages', auth, async (req, res) => {
  try {
    const application = await findChatApplication(req, res);
    if (!application) return;
    const messages = await ChatMessage.find({ applicationId: application._id })
      .sort({ createdAt: 1 })
      .limit(300)
      .populate('senderId', 'name role');
    res.json(messages.map(message => ({
      id: String(message._id),
      content: message.content,
      createdAt: message.createdAt,
      senderId: String(message.senderId?._id || message.senderId),
      senderName: message.senderId?.name || 'Usuario',
      senderRole: message.senderId?.role || ''
    })));
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'No se pudieron cargar los mensajes.' });
  }
});

app.post('/api/applications/:id/messages', auth, async (req, res) => {
  try {
    const application = await findChatApplication(req, res);
    if (!application) return;
    const content = String(req.body?.content || '').trim();
    if (!content) return res.status(400).json({ message: 'Escribe un mensaje antes de enviarlo.' });
    if (content.length > 2000) return res.status(400).json({ message: 'El mensaje no puede superar los 2000 caracteres.' });
    const candidateId = application.candidateId;
    const companyId = application.jobId.companyId;
    const receiverId = String(req.user._id) === String(candidateId) ? companyId : candidateId;
    const message = await ChatMessage.create({
      applicationId: application._id,
      candidateId,
      companyId,
      senderId: req.user._id,
      content
    });
    res.status(201).json({
      id: String(message._id),
      content: message.content,
      createdAt: message.createdAt,
      senderId: String(req.user._id),
      senderName: req.user.name,
      senderRole: req.user.role,
      receiverId: String(receiverId)
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'No se pudo enviar el mensaje.' });
  }
});
app.use((err, req, res, next) => { console.error(err); res.status(500).json({ message: 'Error interno del servidor.' }); });

mongoose.connect(process.env.MONGODB_URI).then(() => { console.log('MongoDB conectado'); app.listen(PORT, () => console.log(`INKLU API escuchando en ${PORT}`)); }).catch(err => { console.error('No se pudo conectar a MongoDB:', err.message); process.exit(1); });
