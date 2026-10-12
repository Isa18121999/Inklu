require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('./models/User');
const Job = require('./models/Job');
const Application = require('./models/Application');

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
  }
  return data;
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
  const applications = await Application.find(filter).populate('candidateId', 'name email phone profile').populate({ path: 'jobId', populate: { path: 'companyId', select: 'name' } }).sort({ createdAt: -1 });
  res.json(applications);
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
    if (!application || String(application.jobId.companyId) !== String(req.user._id)) return res.status(404).json({ message: 'Postulación no encontrada.' });
    const allowed = ['Postulada', 'En revisión', 'Entrevista', 'Seleccionada', 'No seleccionada'];
    if (!allowed.includes(req.body?.status)) return res.status(400).json({ message: 'Estado inválido.' });
    application.status = req.body.status; await application.save(); res.json(application);
  } catch (e) { console.error(e); res.status(500).json({ message: 'No se pudo actualizar el estado.' }); }
});
app.use((err, req, res, next) => { console.error(err); res.status(500).json({ message: 'Error interno del servidor.' }); });

mongoose.connect(process.env.MONGODB_URI).then(() => { console.log('MongoDB conectado'); app.listen(PORT, () => console.log(`INKLU API escuchando en ${PORT}`)); }).catch(err => { console.error('No se pudo conectar a MongoDB:', err.message); process.exit(1); });
