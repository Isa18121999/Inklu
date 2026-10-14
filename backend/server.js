require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { rateLimit } = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const User = require('./models/User');
const Job = require('./models/Job');
const Application = require('./models/Application');
const ChatMessage = require('./models/ChatMessage');
const Notification = require('./models/Notification');
const { PDFParse } = require('pdf-parse');
const mammoth = require('mammoth');
const { normalizeText, keywordCounts, recommendJobsForUser } = require('./services/recommendations');

const app = express();
const PORT = process.env.PORT || 10000;
const JWT_SECRET = process.env.JWT_SECRET || 'change-this-secret-in-render';
const MAX_CV_BYTES = 5 * 1024 * 1024;
const MAX_PROFILE_PHOTO_BYTES = 2 * 1024 * 1024;

app.set('trust proxy', 1);
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors({ origin: process.env.FRONTEND_ORIGIN || '*', methods: ['GET','POST','PATCH','DELETE','OPTIONS'], allowedHeaders: ['Content-Type','Authorization'] }));
app.use(express.json({ limit: '8mb' }));

const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 12,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Demasiados intentos. Espera unos minutos antes de volver a intentarlo.' }
});
const recoveryRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Se alcanzó el límite temporal de recuperación. Inténtalo más tarde.' }
});
const passwordResetRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 8,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Demasiados intentos para cambiar la contraseña. Inténtalo más tarde.' }
});
const emailVerificationRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Demasiadas solicitudes de verificación. Inténtalo más tarde.' }
});
const verifyEmailRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Demasiados intentos de verificación. Inténtalo más tarde.' }
});

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
  const data = {
    id: user._id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    country: user.country,
    ruc: user.ruc,
    companyProfile: user.companyProfile,
    profile: user.profile,
    hasProfilePhoto: Boolean(user.profilePhoto?.size || user.profilePhoto?.data?.length),
    profilePhotoUpdatedAt: user.profilePhoto?.updatedAt || null
  };
  data.emailVerified = user.emailVerified !== false;
  if (includeSensitive && user.role === 'candidate') {
    data.conadisNumber = user.conadisNumber;
    data.hasCv = Boolean(user.cv?.size || user.cv?.data?.length);
    data.cvFileName = user.cv?.fileName || null;
    data.cvAnalysis = user.cvAnalysis ? {
      skills: user.cvAnalysis.skills || [],
      analyzedAt: user.cvAnalysis.analyzedAt || null,
      textLength: user.cvAnalysis.textLength || 0
    } : null;
  }
  return data;
}

function emailDeliveryConfigured() {
  return Boolean(
    (process.env.EMAIL_RELAY_URL && process.env.EMAIL_RELAY_TOKEN) ||
    (process.env.SMTP_USER && process.env.SMTP_APP_PASSWORD) ||
    (process.env.RESEND_API_KEY && process.env.EMAIL_FROM)
  );
}

async function sendTransactionalEmail({ to, subject, html, text }) {
  const relayConfigured = Boolean(process.env.EMAIL_RELAY_URL && process.env.EMAIL_RELAY_TOKEN);
  const smtpConfigured = Boolean(process.env.SMTP_USER && process.env.SMTP_APP_PASSWORD);
  const resendConfigured = Boolean(process.env.RESEND_API_KEY && process.env.EMAIL_FROM);
  if (!relayConfigured && !smtpConfigured && !resendConfigured) {
    throw new Error('El servicio de correo todavía no está configurado.');
  }

  if (relayConfigured) {
    const response = await fetch(process.env.EMAIL_RELAY_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: process.env.EMAIL_RELAY_TOKEN,
        to,
        subject,
        html,
        text
      }),
      signal: AbortSignal.timeout(20000)
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || result.success !== true) {
      console.error('Relay de correo rechazó el envío. HTTP:', response.status, result.error || 'sin detalle');
      throw new Error('El relay de correo no pudo enviar el mensaje.');
    }
    return;
  }

  if (smtpConfigured) {
    const transport = nodemailer.createTransport({
      service: process.env.SMTP_SERVICE || 'gmail',
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_APP_PASSWORD },
      connectionTimeout: 15000,
      greetingTimeout: 15000,
      socketTimeout: 20000
    });
    await transport.sendMail({
      from: process.env.EMAIL_FROM || process.env.SMTP_USER,
      to,
      subject,
      html,
      text
    });
    return;
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ from: process.env.EMAIL_FROM, to: [to], subject, html, text }),
    signal: AbortSignal.timeout(20000)
  });
  if (!response.ok) {
    const errorText = await response.text().catch(() => '');
    console.error('Proveedor de correo rechazó el envío. HTTP:', response.status, errorText.slice(0, 300));
    throw new Error('El proveedor de correo no pudo enviar el mensaje.');
  }
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

app.get('/api/health', (req, res) => {
  const relayConfigured = Boolean(process.env.EMAIL_RELAY_URL && process.env.EMAIL_RELAY_TOKEN);
  const smtpConfigured = Boolean(process.env.SMTP_USER && process.env.SMTP_APP_PASSWORD);
  const resendConfigured = Boolean(process.env.RESEND_API_KEY && process.env.EMAIL_FROM);
  const emailProvider = relayConfigured ? 'https-relay' : smtpConfigured ? 'smtp' : resendConfigured ? 'resend' : 'not-configured';
  // Expose only a boolean/provider label, never secret values.
  res.json({
    ok: true,
    service: 'INKLU API',
    emailDelivery: {
      configured: emailDeliveryConfigured(),
      provider: emailProvider
    }
  });
});

app.post('/api/auth/register', authRateLimit, async (req, res) => {
  try {
    const { name, email, phone, password, role, country, ruc, accreditationType, accreditationNumber, companyProfile } = req.body || {};
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
    const user = await User.create({
      name: String(name).trim(),
      email: normalizedEmail,
      phone: String(phone || '').trim(),
      passwordHash,
      emailVerified: false,
      role,
      country: country || 'PE',
      ruc: role === 'company' ? String(ruc || '').trim() : undefined,
      companyProfile: role === 'company' ? {
        sector: String(companyProfile?.sector || '').trim(),
        size: String(companyProfile?.size || '').trim(),
        address: String(companyProfile?.address || '').trim(),
        website: String(companyProfile?.website || '').trim(),
        description: String(companyProfile?.description || '').trim()
      } : undefined,
      conadisNumber,
      accreditationType: role === 'candidate' ? (accreditationType || 'Carné CONADIS') : undefined
    });
    return res.status(201).json({ token: tokenFor(user), user: publicUser(user, { includeSensitive: true }) });
  } catch (e) {
    if (e?.code === 11000) {
      if (e.keyPattern?.conadisNumber) return res.status(409).json({ message: 'Este número de CONADIS ya está registrado.' });
      if (e.keyPattern?.email) return res.status(409).json({ message: 'El correo electrónico ya está registrado.' });
    }
    console.error(e); return res.status(500).json({ message: 'No se pudo crear la cuenta.' });
  }
});

app.post('/api/auth/login', authRateLimit, async (req, res) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password, user.passwordHash))) return res.status(401).json({ message: 'Correo o contraseña incorrectos.' });
    return res.json({ token: tokenFor(user), user: publicUser(user, { includeSensitive: user.role === 'candidate' }) });
  } catch (e) { console.error(e); return res.status(500).json({ message: 'No se pudo iniciar sesión.' }); }
});

app.post('/api/auth/request-email-verification', auth, emailVerificationRateLimit, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('+emailVerificationTokenHash +emailVerificationExpires +emailVerificationRequestedAt');
    if (!user) return res.status(401).json({ message: 'Inicia sesión nuevamente.' });
    if (user.emailVerified === true) {
      return res.json({ success: true, alreadyVerified: true, message: 'Tu correo ya está verificado.' });
    }
    if (!emailDeliveryConfigured()) {
      return res.status(503).json({
        message: 'El envío de correo aún no está configurado. Completa la configuración de EMAIL_RELAY_URL y EMAIL_RELAY_TOKEN en Render.'
      });
    }

    const now = Date.now();
    if (user.emailVerificationRequestedAt && now - new Date(user.emailVerificationRequestedAt).getTime() < 60 * 1000) {
      return res.status(429).json({ message: 'Espera un minuto antes de solicitar otro enlace.' });
    }

    const token = crypto.randomBytes(32).toString('hex');
    const emailVerificationTokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const emailVerificationExpires = new Date(now + 24 * 60 * 60 * 1000);
    await User.updateOne(
      { _id: user._id },
      { $set: { emailVerificationTokenHash, emailVerificationExpires, emailVerificationRequestedAt: new Date(now) } }
    );

    const verifyUrl = new URL(String(process.env.EMAIL_VERIFICATION_URL || 'https://isa18121999.github.io/Inklu/verify-email.html'));
    verifyUrl.searchParams.set('token', token);
    verifyUrl.searchParams.set('email', user.email);
    const safeName = String(user.name || '').replace(/[&<>"]/g, '');
    const html = `<!doctype html><html lang="es"><body style="font-family:Arial,sans-serif;background:#f8f7ff;color:#19162d;padding:24px"><main style="max-width:560px;margin:auto;background:#fff;padding:28px;border-radius:18px;border:1px solid #e7e2fb"><h1 style="color:#4f46e5">Verifica tu correo de INKLU</h1><p>Hola ${safeName},</p><p>Confirma que esta dirección de correo te pertenece para mantener tu cuenta de INKLU actualizada.</p><p style="text-align:center;margin:28px 0"><a href="${verifyUrl.toString()}" style="display:inline-block;background:#4f46e5;color:#fff;text-decoration:none;padding:14px 24px;border-radius:10px;font-weight:bold">Verificar mi correo</a></p><p>Este enlace caduca en 24 horas. Si no has creado una cuenta en INKLU, puedes ignorar este mensaje.</p><p><strong>INKLU</strong> · Tecnología para la inclusión laboral.</p></main></body></html>`;
    const plainText = `Confirma tu correo de INKLU abriendo este enlace (caduca en 24 horas): ${verifyUrl.toString()}`;

    try {
      await sendTransactionalEmail({
        to: user.email,
        subject: 'Verifica tu correo de INKLU',
        html,
        text: plainText
      });
    } catch (deliveryError) {
      await User.updateOne(
        { _id: user._id },
        { $unset: { emailVerificationTokenHash: 1, emailVerificationExpires: 1, emailVerificationRequestedAt: 1 } }
      );
      console.error('No se pudo enviar la verificación de correo:', deliveryError?.message || deliveryError);
      return res.status(502).json({ message: 'No se pudo enviar el correo de verificación. Inténtalo más tarde.' });
    }

    return res.json({ success: true, message: 'Te enviamos un enlace de verificación. Revisa tu bandeja de entrada y Spam.' });
  } catch (error) {
    console.error('Error solicitando verificación de correo:', error);
    return res.status(500).json({ message: 'No se pudo procesar la solicitud. Inténtalo más tarde.' });
  }
});

app.post('/api/auth/verify-email', verifyEmailRateLimit, async (req, res) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const token = String(req.body?.token || '').trim();
    if (!/^[^@\s]+@[^\s]+\.[^\s]+$/.test(email) || !/^[a-f0-9]{64}$/i.test(token)) {
      return res.status(400).json({ message: 'El enlace de verificación no es válido.' });
    }

    const user = await User.findOne({ email }).select('+emailVerificationTokenHash +emailVerificationExpires');
    if (!user) return res.status(400).json({ message: 'El enlace no es válido o ha caducado. Solicita otro desde INKLU.' });
    if (user.emailVerified === true) {
      return res.json({ success: true, message: 'Tu correo ya estaba verificado. Puedes volver a INKLU.' });
    }
    if (!user.emailVerificationTokenHash || !user.emailVerificationExpires ||
        new Date(user.emailVerificationExpires).getTime() <= Date.now()) {
      return res.status(400).json({ message: 'El enlace no es válido o ha caducado. Solicita otro desde INKLU.' });
    }

    const incomingHash = crypto.createHash('sha256').update(token).digest('hex');
    const expected = Buffer.from(user.emailVerificationTokenHash, 'hex');
    const incoming = Buffer.from(incomingHash, 'hex');
    if (expected.length !== incoming.length || !crypto.timingSafeEqual(expected, incoming)) {
      return res.status(400).json({ message: 'El enlace no es válido o ha caducado. Solicita otro desde INKLU.' });
    }

    const updated = await User.updateOne(
      { _id: user._id, emailVerificationTokenHash: user.emailVerificationTokenHash, emailVerificationExpires: { $gt: new Date() } },
      { $set: { emailVerified: true }, $unset: { emailVerificationTokenHash: 1, emailVerificationExpires: 1, emailVerificationRequestedAt: 1 } }
    );
    if (!updated.modifiedCount) {
      return res.status(400).json({ message: 'El enlace ya no es válido. Solicita otro desde INKLU.' });
    }
    return res.json({ success: true, message: 'Correo verificado correctamente. Ya puedes volver a INKLU.' });
  } catch (error) {
    console.error('Error verificando correo:', error);
    return res.status(500).json({ message: 'No se pudo verificar el correo. Inténtalo más tarde.' });
  }
});

// La recuperación envía un enlace con un proveedor de correo configurado. No revela si una cuenta existe.
app.post('/api/auth/forgot-password', recoveryRateLimit, async (req, res) => {
  const genericMessage = 'Si existe una cuenta con ese correo y la recuperación está habilitada, recibirás un enlace para restablecer tu contraseña.';
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      return res.status(400).json({ message: 'Introduce un correo electrónico válido.' });
    }
    const relayConfigured = Boolean(process.env.EMAIL_RELAY_URL && process.env.EMAIL_RELAY_TOKEN);
    const smtpConfigured = Boolean(process.env.SMTP_USER && process.env.SMTP_APP_PASSWORD);
    const resendConfigured = Boolean(process.env.RESEND_API_KEY && process.env.EMAIL_FROM);
    if (!relayConfigured && !smtpConfigured && !resendConfigured) {
      return res.status(503).json({
        message: 'La recuperación por correo aún necesita configuración. Consulta email-relay/README.md para conectar Gmail por HTTPS.'
      });
    }

    const user = await User.findOne({ email }).select('+passwordResetTokenHash +passwordResetExpires +passwordResetRequestedAt');
    if (!user) return res.json({ message: genericMessage });

    const now = Date.now();
    if (user.passwordResetRequestedAt && now - new Date(user.passwordResetRequestedAt).getTime() < 60 * 1000) {
      return res.json({ message: genericMessage });
    }

    const token = crypto.randomBytes(32).toString('hex');
    const passwordResetTokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const passwordResetExpires = new Date(now + 30 * 60 * 1000);
    const passwordResetRequestedAt = new Date(now);
    // Actualiza solo los campos de recuperación: algunas cuentas antiguas pueden
    // no tener passwordHash y el save() del documento completo falla la validación.
    await User.updateOne(
      { _id: user._id },
      { $set: { passwordResetTokenHash, passwordResetExpires, passwordResetRequestedAt } }
    );

    const resetBase = String(process.env.PASSWORD_RESET_URL || 'https://isa18121999.github.io/Inklu/reset-password.html').trim();
    const resetUrl = new URL(resetBase);
    resetUrl.searchParams.set('token', token);
    resetUrl.searchParams.set('email', email);
    const safeName = String(user.name || '').replace(/[&<>"]/g, '');
    const html = `<!doctype html><html><body style="margin:0;background:#f8f7ff;font-family:Arial,sans-serif;color:#19162d"><div style="max-width:560px;margin:32px auto;padding:28px;background:#fff;border:1px solid #e7e2fb;border-radius:18px"><h1 style="color:#4f46e5">Recupera tu acceso a INKLU</h1><p>Hola ${safeName},</p><p>Recibimos una solicitud para cambiar la contraseña de tu cuenta de INKLU.</p><p style="text-align:center;margin:28px 0"><a href="${resetUrl.toString()}" style="display:inline-block;background:#4f46e5;color:#fff;text-decoration:none;padding:14px 24px;border-radius:10px;font-weight:bold">Crear nueva contraseña</a></p><p>El enlace caduca en 30 minutos y solo se puede utilizar una vez. Si no solicitaste este cambio, ignora este mensaje.</p><p style="color:#64748b;font-size:12px">Por seguridad, nunca compartas este enlace con otras personas.</p><p><strong>INKLU</strong> · Tecnología para la inclusión laboral.</p></div></body></html>`;

    const text = `Recibimos una solicitud para cambiar la contraseña de INKLU. Abre este enlace dentro de los próximos 30 minutos: ${resetUrl.toString()} Si no lo solicitaste, ignora este mensaje.`;

    try {
      if (relayConfigured) {
        // Prioriza HTTPS para evitar los timeouts de SMTP en ciertos hosts.
        const emailResponse = await fetch(process.env.EMAIL_RELAY_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            token: process.env.EMAIL_RELAY_TOKEN,
            to: email,
            subject: 'Recupera tu contraseña de INKLU',
            html,
            text
          }),
          signal: AbortSignal.timeout(20000)
        });
        const relayResult = await emailResponse.json().catch(() => ({}));
        if (!emailResponse.ok || relayResult.success !== true) {
          console.error('El relay de correo de INKLU rechazó el envío. HTTP:', emailResponse.status, relayResult.error || 'sin detalle');
          throw new Error('El relay de correo no pudo enviar el mensaje.');
        }
      } else if (smtpConfigured) {
        const transport = nodemailer.createTransport({
          service: process.env.SMTP_SERVICE || 'gmail',
          auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_APP_PASSWORD
          },
          connectionTimeout: 15000,
          greetingTimeout: 15000,
          socketTimeout: 20000
        });
        await transport.sendMail({
          from: process.env.EMAIL_FROM || process.env.SMTP_USER,
          to: email,
          subject: 'Recupera tu contraseña de INKLU',
          html,
          text
        });
      } else {
        const emailResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            from: process.env.EMAIL_FROM,
            to: [email],
            subject: 'Recupera tu contraseña de INKLU',
            html,
            text
          }),
          signal: AbortSignal.timeout(20000)
        });
        if (!emailResponse.ok) {
          const providerError = await emailResponse.text().catch(() => '');
          console.error('Resend no pudo enviar el correo de recuperación. HTTP:', emailResponse.status, providerError.slice(0, 400));
          throw new Error('El proveedor de correo rechazó el envío.');
        }
      }
    } catch (deliveryError) {
      await User.updateOne(
        { _id: user._id },
        { $unset: { passwordResetTokenHash: 1, passwordResetExpires: 1, passwordResetRequestedAt: 1 } }
      );
      console.error('No se pudo entregar el correo de recuperación:', deliveryError?.message || deliveryError);
      return res.status(502).json({ message: 'No se pudo enviar el correo de recuperación. Revisa la configuración de correo o inténtalo más tarde.' });
    }
    return res.json({ message: genericMessage });
  } catch (error) {
    console.error('Error solicitando recuperación de contraseña:', error);
    return res.status(500).json({ message: 'No se pudo procesar la solicitud. Inténtalo más tarde.' });
  }
});

app.post('/api/auth/reset-password', passwordResetRateLimit, async (req, res) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const token = String(req.body?.token || '').trim();
    const password = String(req.body?.password || '');
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || !token) {
      return res.status(400).json({ message: 'El enlace de recuperación no es válido.' });
    }
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password) || !/[^A-Za-z0-9]/.test(password)) {
      return res.status(400).json({ message: 'Usa al menos 8 caracteres e incluye mayúscula, minúscula, número y símbolo.' });
    }
    const user = await User.findOne({ email }).select('+passwordResetTokenHash +passwordResetExpires');
    if (!user || !user.passwordResetTokenHash || !user.passwordResetExpires || new Date(user.passwordResetExpires).getTime() <= Date.now()) {
      return res.status(400).json({ message: 'El enlace no es válido o ha caducado. Solicita uno nuevo.' });
    }
    const incomingHash = crypto.createHash('sha256').update(token).digest('hex');
    const expected = Buffer.from(user.passwordResetTokenHash, 'hex');
    const incoming = Buffer.from(incomingHash, 'hex');
    if (expected.length !== incoming.length || !crypto.timingSafeEqual(expected, incoming)) {
      return res.status(400).json({ message: 'El enlace no es válido o ha caducado. Solicita uno nuevo.' });
    }
    user.passwordHash = await bcrypt.hash(password, 12);
    user.passwordResetTokenHash = undefined;
    user.passwordResetExpires = undefined;
    user.passwordResetRequestedAt = undefined;
    await user.save();
    return res.json({ message: 'Tu contraseña se actualizó correctamente. Ya puedes iniciar sesión en INKLU.' });
  } catch (error) {
    console.error('Error restableciendo contraseña:', error);
    return res.status(500).json({ message: 'No se pudo restablecer la contraseña. Inténtalo más tarde.' });
  }
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
    if (req.user.role !== 'candidate') return res.status(404).json({ message: 'No hay un CV registrado.' });
    // Los bytes del CV se consultan solo en el endpoint que realmente los entrega.
    const candidate = await User.findById(req.user._id).select('+cv.data');
    if (!candidate?.cv?.data?.length) return res.status(404).json({ message: 'No hay un CV registrado.' });
    const safeFileName = String(candidate.cv.fileName || 'CV').replace(/["\r\n]/g, '');
    res.set('Content-Type', candidate.cv.mimeType || 'application/octet-stream');
    res.set('Content-Disposition', `attachment; filename="${safeFileName}"`);
    res.set('Cache-Control', 'private, no-store');
    res.send(candidate.cv.data);
  } catch (e) { console.error(e); res.status(500).json({ message: 'No se pudo descargar el CV.' }); }
});

app.post('/api/profile/cv/analyze', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden analizar un CV.' });
    const candidate = await User.findById(req.user._id).select('+cv.data');
    if (!candidate) return res.status(401).json({ message: 'Inicia sesión nuevamente.' });
    const analysis = await analyzeCandidateCv(candidate);
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

app.post('/api/profile/photo', auth, async (req, res) => {
  try {
    const { fileName, mimeType, data } = req.body || {};
    if (!fileName || !data) {
      return res.status(400).json({ message: 'Selecciona una foto de perfil.' });
    }

    const extension = String(fileName).toLowerCase().split('.').pop();
    const allowed = {
      jpg: { mime: 'image/jpeg' },
      jpeg: { mime: 'image/jpeg' },
      png: { mime: 'image/png' },
      webp: { mime: 'image/webp' }
    };
    const format = allowed[extension];
    if (!format) {
      return res.status(415).json({ message: 'La foto debe estar en formato JPG, PNG o WEBP.' });
    }
    if (mimeType && ![format.mime, 'application/octet-stream'].includes(String(mimeType).toLowerCase())) {
      return res.status(415).json({ message: 'El tipo de archivo no coincide con la extensión de la foto.' });
    }

    const buffer = Buffer.from(String(data), 'base64');
    if (!buffer.length) {
      return res.status(400).json({ message: 'El archivo de imagen está vacío.' });
    }
    if (buffer.length > MAX_PROFILE_PHOTO_BYTES) {
      return res.status(413).json({ message: 'La foto no puede superar los 2 MB.' });
    }

    const isJpeg = buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
    const isPng = buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
    const isWebp = buffer.length >= 12 && buffer.toString('ascii', 0, 4) === 'RIFF' && buffer.toString('ascii', 8, 12) === 'WEBP';
    const validImage = format.mime === 'image/jpeg' ? isJpeg : format.mime === 'image/png' ? isPng : isWebp;
    if (!validImage) {
      return res.status(415).json({ message: 'El archivo no parece ser una imagen válida.' });
    }

    req.user.profilePhoto = {
      fileName: String(fileName).trim().replace(/[\r\n"]/g, ''),
      mimeType: format.mime,
      data: buffer,
      size: buffer.length,
      updatedAt: new Date()
    };
    await req.user.save();

    res.json({
      message: 'Foto de perfil actualizada correctamente.',
      hasProfilePhoto: true,
      profilePhotoUpdatedAt: req.user.profilePhoto.updatedAt
    });
  } catch (error) {
    console.error('Error guardando la foto de perfil:', error);
    res.status(500).json({ message: 'No se pudo guardar la foto de perfil.' });
  }
});

app.get('/api/profile/photo', auth, async (req, res) => {
  try {
    // La foto binaria no se incluye en cada consulta autenticada; se lee aquí.
    const photoUser = await User.findById(req.user._id).select('+profilePhoto.data');
    const photo = photoUser?.profilePhoto;
    if (!photo?.data?.length) {
      return res.status(404).json({ message: 'Todavía no hay una foto de perfil.' });
    }
    res.set('Content-Type', photo.mimeType || 'image/jpeg');
    res.set('Content-Length', String(photo.size || photo.data.length));
    res.set('Content-Disposition', 'inline');
    res.set('Cache-Control', 'private, no-store');
    return res.send(photo.data);
  } catch (error) {
    console.error('Error cargando la foto de perfil:', error);
    return res.status(500).json({ message: 'No se pudo cargar la foto de perfil.' });
  }
});

app.get('/api/profile/me', auth, async (req, res) => res.json(publicUser(req.user, { includeSensitive: true })));
app.patch('/api/profile/me', auth, async (req, res) => {
  try {
    const body = req.body || {};
    const updates = {};

    if (req.user.role === 'candidate') {
      const allowed = ['birth', 'address', 'education', 'experience', 'skills', 'modality', 'location'];
      for (const key of allowed) {
        if (Object.prototype.hasOwnProperty.call(body, key)) updates[`profile.${key}`] = body[key];
      }
    } else if (req.user.role === 'company') {
      if (Object.prototype.hasOwnProperty.call(body, 'name')) {
        const name = String(body.name || '').trim();
        if (!name) return res.status(400).json({ message: 'El nombre de la empresa es obligatorio.' });
        updates.name = name;
      }
      if (Object.prototype.hasOwnProperty.call(body, 'phone')) updates.phone = String(body.phone || '').trim();

      const companyProfile = body.companyProfile && typeof body.companyProfile === 'object'
        ? body.companyProfile
        : {};
      const allowedCompanyFields = ['sector', 'size', 'address', 'website', 'description'];
      for (const key of allowedCompanyFields) {
        if (Object.prototype.hasOwnProperty.call(companyProfile, key)) {
          updates[`companyProfile.${key}`] = String(companyProfile[key] ?? '').trim();
        }
      }
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ message: 'No hay datos de perfil para actualizar.' });
    }
    const user = await User.findByIdAndUpdate(req.user._id, { $set: updates }, { new: true, runValidators: true });
    if (!user) return res.status(404).json({ message: 'No se encontró la cuenta.' });
    res.json(publicUser(user, { includeSensitive: true }));
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'No se pudo actualizar el perfil.' });
  }
});

app.delete('/api/profile/me', auth, async (req, res) => {
  try {
    const password = String(req.body?.password || '');
    if (!password || !(await bcrypt.compare(password, req.user.passwordHash))) {
      return res.status(401).json({ message: 'La contraseña actual no es correcta.' });
    }

    const userId = req.user._id;
    let applicationIds = [];
    let jobIds = [];

    if (req.user.role === 'company') {
      const jobs = await Job.find({ companyId: userId }).select('_id').lean();
      jobIds = jobs.map(job => job._id);
      if (jobIds.length) {
        const applications = await Application.find({ jobId: { $in: jobIds } }).select('_id').lean();
        applicationIds = applications.map(application => application._id);
      }
    } else {
      const applications = await Application.find({ candidateId: userId }).select('_id').lean();
      applicationIds = applications.map(application => application._id);
    }

    if (applicationIds.length) {
      await ChatMessage.deleteMany({ applicationId: { $in: applicationIds } });
      await Application.deleteMany({ _id: { $in: applicationIds } });
      await Notification.deleteMany({ relatedId: { $in: applicationIds } });
    }
    if (jobIds.length) {
      await Application.deleteMany({ jobId: { $in: jobIds } });
      await Job.deleteMany({ _id: { $in: jobIds } });
    }

    await Notification.deleteMany({ userId });
    await User.deleteOne({ _id: userId });
    return res.json({ success: true, message: 'La cuenta y los datos asociados se eliminaron.' });
  } catch (error) {
    console.error('Error eliminando cuenta:', error);
    return res.status(500).json({ message: 'No se pudo eliminar la cuenta. Inténtalo de nuevo más tarde.' });
  }
});

app.get('/api/notifications', auth, async (req, res) => {
  try {
    const items = await Notification.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
    res.json(items.map(item => ({
      id: String(item._id),
      title: item.title,
      message: item.message,
      type: item.type,
      relatedId: item.relatedId ? String(item.relatedId) : null,
      read: Boolean(item.readAt),
      createdAt: item.createdAt
    })));
  } catch (error) {
    console.error('Error cargando notificaciones:', error);
    res.status(500).json({ message: 'No se pudieron cargar las notificaciones.' });
  }
});

app.patch('/api/notifications/:id/read', auth, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ message: 'Notificación no válida.' });
    }
    const item = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id, readAt: null },
      { $set: { readAt: new Date() } },
      { new: true }
    );
    if (!item) return res.status(404).json({ message: 'No se encontró una notificación pendiente.' });
    res.json({ success: true, id: String(item._id), read: true });
  } catch (error) {
    console.error('Error actualizando notificación:', error);
    res.status(500).json({ message: 'No se pudo actualizar la notificación.' });
  }
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
      message: recommendations.length
        ? 'Ofertas filtradas y ordenadas por carrera, palabras clave del CV, habilidades y experiencia requerida.'
        : 'No encontramos ofertas suficientemente relacionadas con tu CV y experiencia. Completa tu formación y años de experiencia en tu perfil, o mejora el CV.'
    });
  } catch (e) {
    res.status(e.statusCode || 500).json({ message: e.statusCode ? e.message : 'No se pudieron calcular las recomendaciones.' });
  }
});

app.get('/api/jobs/saved', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Las ofertas guardadas están disponibles para candidatos.' });
    const candidate = await User.findById(req.user._id).select('savedJobs');
    const ids = candidate?.savedJobs || [];
    const jobs = await Job.find({ _id: { $in: ids }, active: true })
      .populate('companyId', 'name')
      .sort({ updatedAt: -1 });
    res.json(jobs);
  } catch (error) {
    console.error('Error cargando ofertas guardadas:', error);
    res.status(500).json({ message: 'No se pudieron cargar las ofertas guardadas.' });
  }
});

app.post('/api/jobs/:id/save', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden guardar ofertas.' });
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ message: 'Oferta no válida.' });
    const job = await Job.findOne({ _id: req.params.id, active: true });
    if (!job) return res.status(404).json({ message: 'La oferta no existe o ya no está disponible.' });
    await User.updateOne({ _id: req.user._id }, { $addToSet: { savedJobs: job._id } });
    res.json({ saved: true, jobId: String(job._id) });
  } catch (error) {
    console.error('Error guardando oferta:', error);
    res.status(500).json({ message: 'No se pudo guardar la oferta.' });
  }
});

app.delete('/api/jobs/:id/save', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden administrar ofertas guardadas.' });
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ message: 'Oferta no válida.' });
    await User.updateOne({ _id: req.user._id }, { $pull: { savedJobs: new mongoose.Types.ObjectId(req.params.id) } });
    res.json({ saved: false, jobId: req.params.id });
  } catch (error) {
    console.error('Error quitando oferta guardada:', error);
    res.status(500).json({ message: 'No se pudo quitar la oferta guardada.' });
  }
});

app.get('/api/jobs', auth, async (req, res) => {
  try {
    const clean = value => String(value || '').trim().slice(0, 100);
    const escapeRegex = value => value.split('').map(character => {
      const isMeta = '.^$*+?()[]{}|'.includes(character) || character.charCodeAt(0) === 92;
      return isMeta ? String.fromCharCode(92) + character : character;
    }).join('');
    const q = clean(req.query.q);
    const location = clean(req.query.location);
    const modality = clean(req.query.modality);
    const contractType = clean(req.query.contractType);
    const category = clean(req.query.category);
    const filter = { active: true };

    if (q) {
      const regex = new RegExp(escapeRegex(q), 'i');
      const companies = await User.find({ role: 'company', name: regex }).select('_id').limit(100);
      const alternatives = [
        { title: regex },
        { description: regex },
        { category: regex },
        { requiredSkills: regex },
        { preferredSkills: regex }
      ];
      if (companies.length) alternatives.push({ companyId: { $in: companies.map(company => company._id) } });
      filter.$or = alternatives;
    }
    if (location) filter.location = new RegExp(escapeRegex(location), 'i');
    if (modality) filter.modality = new RegExp('^' + escapeRegex(modality) + '$', 'i');
    if (contractType) filter.contractType = new RegExp('^' + escapeRegex(contractType) + '$', 'i');
    if (category) filter.category = new RegExp('^' + escapeRegex(category) + '$', 'i');

    let jobs = await Job.find(filter).populate('companyId', 'name').sort({ createdAt: -1 }).limit(100);
    // Una vez que el CV ya fue analizado, las búsquedas de candidatos priorizan
    // únicamente las ofertas con evidencia de relación profesional y compatibilidad.
    if (req.user.role === 'candidate' && req.user.cvAnalysis?.keywords?.length) {
      jobs = recommendJobsForUser(req.user, jobs);
    }
    res.json(jobs);
  } catch (error) {
    console.error('Error buscando ofertas:', error);
    res.status(500).json({ message: 'No se pudieron buscar las ofertas.' });
  }
});
app.get('/api/company/jobs', auth, async (req, res) => { const jobs = await Job.find({ active: true }).populate('companyId', 'name').sort({ createdAt: -1 }); res.json(jobs); });
app.get('/api/company/my-jobs', auth, async (req, res) => { if (req.user.role !== 'company') return res.status(403).json({ message: 'Solo las empresas pueden consultar sus ofertas.' }); const jobs = await Job.find({ companyId: req.user._id }).sort({ createdAt: -1 }); res.json(jobs); });
app.post('/api/company/jobs', auth, async (req, res) => {
  try {
    if (req.user.role !== 'company') return res.status(403).json({ message: 'Solo las empresas pueden publicar ofertas.' });
    const { title, description, category, modality, location, contractType, salary, requiredSkills, preferredSkills, experienceRequired, accessibilityDetails } = req.body || {};
    if (!title || !description) return res.status(400).json({ message: 'El título y la descripción son obligatorios.' });
    const rawSkills = Array.isArray(requiredSkills) ? requiredSkills : String(requiredSkills || '').split(',');
    const skills = rawSkills.map(skill => String(skill || '').trim().slice(0, 80)).filter(Boolean).slice(0, 40);
    const rawPreferredSkills = Array.isArray(preferredSkills) ? preferredSkills : String(preferredSkills || '').split(',');
    const desirableSkills = rawPreferredSkills.map(skill => String(skill || '').trim().slice(0, 80)).filter(Boolean).slice(0, 40);
    const years = Number(experienceRequired || 0);
    if (!Number.isFinite(years) || years < 0 || years > 60) {
      return res.status(400).json({ message: 'Los años de experiencia requeridos deben estar entre 0 y 60.' });
    }
    const job = await Job.create({
      companyId: req.user._id,
      title: String(title).trim().slice(0, 160),
      description: String(description).trim().slice(0, 5000),
      category: String(category || '').trim().slice(0, 100),
      modality: String(modality || '').trim().slice(0, 40),
      location: String(location || '').trim().slice(0, 160),
      contractType: String(contractType || '').trim().slice(0, 80),
      salary: String(salary || '').trim().slice(0, 100),
      requiredSkills: skills,
      preferredSkills: desirableSkills,
      accessibilityDetails: String(accessibilityDetails || '').trim().slice(0, 1200),
      experienceRequired: years
    });
    res.status(201).json(job);
  } catch (e) { console.error(e); res.status(500).json({ message: 'No se pudo publicar la oferta.' }); }
});
app.get('/api/applications', auth, async (req, res) => {
  let filter = {};
  if (req.user.role === 'candidate') filter.candidateId = req.user._id;
  else filter.jobId = { $in: (await Job.find({ companyId: req.user._id }).select('_id')).map(j => j._id) };

  // Optional server-side status filter (the Flutter UI also filters already-loaded data).
  if (req.query.status && req.query.status !== 'Todas') {
    const requestedStatus = String(req.query.status);
    const legacyStatus = {
      'Postulado': 'Postulada',
      'CV visto': 'En revisión',
      'En proceso': 'Entrevista',
      'Aceptado': 'Seleccionada',
      'Proceso terminado': 'No seleccionada'
    }[requestedStatus];
    filter.status = legacyStatus
      ? { $in: [requestedStatus, legacyStatus] }
      : requestedStatus;
  }

  const applications = await Application.find(filter)
    .populate('candidateId', 'name email phone profile cvAnalysis')
    .populate({ path: 'jobId', populate: { path: 'companyId', select: 'name' } })
    .sort({ createdAt: -1 });

  const jobIds = [...new Set(applications.map(a => String(a.jobId?._id || a.jobId)).filter(Boolean))];
  const countRows = jobIds.length
    ? await Application.aggregate([
        { $match: { jobId: { $in: jobIds.map(id => new mongoose.Types.ObjectId(id)) } } },
        { $group: { _id: '$jobId', count: { $sum: 1 } } }
      ])
    : [];
  const applicantCounts = new Map(countRows.map(row => [String(row._id), row.count]));

  res.json(applications.map(application => {
    const record = application.toObject();
    record.status = normalizeApplicationStatus(record.status);
    const history = Array.isArray(record.statusHistory) ? record.statusHistory : [];
    if (history.length === 0) {
      record.statusHistory = [{
        status: record.status,
        changedAt: record.updatedAt || record.createdAt,
        changedBy: null
      }];
    } else {
      record.statusHistory = history.map(entry => ({
        ...entry,
        status: normalizeApplicationStatus(entry.status)
      }));
    }
    record.applicantCount = applicantCounts.get(String(record.jobId?._id || record.jobId)) || 1;
    return record;
  }));
});
app.post('/api/applications', auth, async (req, res) => {
  try {
    if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden postularse.' });
    const job = await Job.findOne({ _id: req.body?.jobId, active: true });
    if (!job) return res.status(404).json({ message: 'La oferta no existe o ya no está disponible.' });
    const application = await Application.create({
      jobId: job._id,
      candidateId: req.user._id,
      status: 'Postulado',
      statusHistory: [{ status: 'Postulado', changedAt: new Date(), changedBy: req.user._id }]
    });
    try {
      await Notification.create({
        userId: job.companyId,
        title: 'Nueva postulación',
        message: `${req.user.name} se postuló a la oferta “${job.title}”.`,
        type: 'application',
        relatedId: application._id
      });
    } catch (notificationError) {
      console.error('No se pudo crear la notificación de postulación:', notificationError.message);
    }
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
    const nextStatus = req.body.status;
    if (normalizeApplicationStatus(application.status) !== nextStatus) {
      application.status = nextStatus;
      application.statusHistory.push({
        status: nextStatus,
        changedAt: new Date(),
        changedBy: req.user._id
      });
      await application.save();
      try {
        await Notification.create({
          userId: application.candidateId,
          title: 'Actualización de tu postulación',
          message: `Tu postulación a “${application.jobId.title}” cambió a: ${nextStatus}.`,
          type: 'application_status',
          relatedId: application._id
        });
      } catch (notificationError) {
        console.error('No se pudo crear la notificación de estado:', notificationError.message);
      }
    }
    res.json({
      ...application.toObject(),
      status: normalizeApplicationStatus(application.status),
      statusHistory: (application.statusHistory || []).map(item => ({
        status: normalizeApplicationStatus(item.status),
        changedAt: item.changedAt,
        changedBy: item.changedBy
      }))
    });
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
