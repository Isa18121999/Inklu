const mongoose = require('mongoose');
const { PDFParse } = require('pdf-parse');
const mammoth = require('mammoth');

const AccessibilityPreferencesSchema = new mongoose.Schema({
  share: { type: Boolean, default: false },
  needType: { type: String, trim: true, maxlength: 80, default: '' },
  preferences: { type: [String], default: [] }
}, { _id: false });

const CandidateProfileSchema = new mongoose.Schema({
  birth: { type: String, trim: true },
  address: { type: String, trim: true },
  education: { type: String, trim: true },
  professionalSummary: { type: String, trim: true, maxlength: 1200, default: '' },
  experience: { type: Number, min: 0, max: 60, default: 0 },
  skills: { type: [String], default: [] },
  projects: { type: [String], default: [] },
  certifications: { type: [String], default: [] },
  modality: { type: String, trim: true },
  location: { type: String, trim: true },
  accessibility: { type: AccessibilityPreferencesSchema, default: () => ({}) }
}, { _id: false });

const CvSchema = new mongoose.Schema({
  fileName: { type: String, trim: true },
  mimeType: { type: String, trim: true },
  data: { type: Buffer, select: false },
  size: { type: Number, min: 0 },
  uploadedAt: { type: Date, default: Date.now }
}, { _id: false });

const CvAnalysisSchema = new mongoose.Schema({
  skills: { type: [String], default: [] },
  keywords: [{ term: { type: String, required: true }, count: { type: Number, min: 1, required: true } }],
  textLength: { type: Number, default: 0 },
  analyzedAt: { type: Date },
  sourceUploadedAt: { type: Date }
}, { _id: false });

const ProfilePhotoSchema = new mongoose.Schema({
  fileName: { type: String, trim: true },
  mimeType: { type: String, enum: ['image/jpeg', 'image/png', 'image/webp'], required: true },
  data: { type: Buffer, required: true, select: false },
  size: { type: Number, min: 1, required: true },
  updatedAt: { type: Date, default: Date.now }
}, { _id: false });

const CompanyProfileSchema = new mongoose.Schema({
  sector: { type: String, trim: true, default: '' },
  size: { type: String, trim: true, default: '' },
  address: { type: String, trim: true, default: '' },
  website: { type: String, trim: true, default: '' },
  description: { type: String, trim: true, default: '' }
}, { _id: false });

const SavedJobSearchSchema = new mongoose.Schema({
  label: { type: String, required: true, trim: true, maxlength: 60 },
  query: { type: String, trim: true, maxlength: 100, default: '' },
  location: { type: String, trim: true, maxlength: 100, default: '' },
  modality: { type: String, trim: true, maxlength: 40, default: '' },
  contractType: { type: String, trim: true, maxlength: 80, default: '' },
  category: { type: String, trim: true, maxlength: 100, default: '' },
  withAccessibility: { type: Boolean, default: false }
}, { timestamps: true });

const CV_PROFILE_SKILLS = [
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

const CV_SECTION_HEADINGS = ['perfil profesional', 'resumen profesional', 'perfil', 'objetivo profesional', 'objetivo', 'sobre mi', 'acerca de mi', 'educacion', 'educación', 'formacion academica', 'formación académica', 'formacion', 'formación', 'experiencia laboral', 'experiencia profesional', 'experiencia', 'proyectos', 'proyectos destacados', 'certificaciones', 'certificados', 'cursos', 'habilidades', 'skills', 'competencias', 'idiomas', 'referencias', 'contacto'];

function cleanCvText(value) { return String(value || '').replace(/\r/g, '\n').replace(/[ \t]+/g, ' ').replace(/\n{3,}/g, '\n\n').trim(); }
function cleanCvLine(value) { return String(value || '').replace(/^[\s•·▪◦\-–—*]+/, '').replace(/\s+/g, ' ').trim(); }
function escaped(value) { return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+'); }
function extractSection(text, aliases, maxLength) {
  const heading = aliases.map(escaped).join('|');
  const next = CV_SECTION_HEADINGS.map(escaped).join('|');
  const match = cleanCvText(text).match(new RegExp(`(?:^|\\n)\\s*(?:${heading})\\s*[:\\-]?\\s*\\n?([\\s\\S]*?)(?=\\n\\s*(?:${next})\\s*[:\\-]?\\s*(?:\\n|$)|$)`, 'i'));
  return match ? match[1].trim().slice(0, maxLength) : '';
}
function extractLabeled(text, aliases, maxLength = 180) {
  const label = aliases.map(escaped).join('|');
  const match = cleanCvText(text).match(new RegExp(`(?:^|\\n|\\.)\\s*(?:${label})\\s*[:\\-]\\s*([^\\n|]+)`, 'i'));
  return match ? cleanCvLine(match[1]).slice(0, maxLength) : '';
}
function sectionItems(section, maxItems = 20) { if (!section) return []; return section.split(/\n|•|·|▪|◦/).map(cleanCvLine).filter(v => v.length >= 3).filter((v, i, a) => a.findIndex(x => x.toLowerCase() === v.toLowerCase()) === i).slice(0, maxItems); }
function experienceYears(text) { const matches = [...cleanCvText(text).toLowerCase().matchAll(/(\d+(?:[.,]\d+)?)\s*(?:años|anos)\s+(?:de\s+)?experiencia/g)]; const values = matches.map(m => Number(String(m[1]).replace(',', '.'))).filter(v => Number.isFinite(v) && v >= 0 && v <= 60); return values.length ? Math.max(...values) : 0; }

async function extractProfileFromCv(buffer, fileName) {
  const extension = String(fileName || '').toLowerCase().split('.').pop();
  let text = '';
  if (extension === 'pdf') { const parser = new PDFParse({ data: buffer }); try { text = (await parser.getText()).text || ''; } finally { await parser.destroy(); } }
  else if (extension === 'docx') text = (await mammoth.extractRawText({ buffer })).value || '';
  else if (extension === 'doc') text = buffer.toString('latin1').replace(/[^\x20-\x7E\u00A0-\u00FF\r\n\t]/g, ' ');
  else return {};
  text = cleanCvText(text); if (text.length < 30) return {};
  const normalized = text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  const skills = CV_PROFILE_SKILLS.filter(skill => skill.terms.some(term => normalized.includes(term))).map(skill => skill.label);
  const educationSection = extractSection(text, ['educacion', 'educación', 'formacion academica', 'formación académica', 'formacion', 'formación'], 600);
  const summary = extractSection(text, ['perfil profesional', 'resumen profesional', 'objetivo profesional', 'sobre mi', 'acerca de mi'], 1200);
  const projects = sectionItems(extractSection(text, ['proyectos', 'proyectos destacados'], 1200));
  const certifications = sectionItems(extractSection(text, ['certificaciones', 'certificados', 'cursos'], 1000));
  let education = educationSection;
  if (!education) education = text.split('\n').map(cleanCvLine).filter(line => /(universidad|instituto|institución|licenciatura|ingenier[ií]a|bachiller|t[ée]cnico|maestr[ií]a|doctorado)/i.test(line)).slice(0, 3).join(' · ').slice(0, 600);
  let modality = extractLabeled(text, ['modalidad', 'modalidad laboral', 'tipo de trabajo']);
  if (!modality) modality = /\btrabajo\s+remoto\b|\bmodalidad\s+remota\b/i.test(text) ? 'Remoto' : /\btrabajo\s+h[ií]brido\b|\bmodalidad\s+h[ií]brida\b/i.test(text) ? 'Híbrido' : /\btrabajo\s+presencial\b|\bmodalidad\s+presencial\b/i.test(text) ? 'Presencial' : '';
  return { education, professionalSummary: summary, experience: experienceYears(text), skills, projects, certifications, modality, location: extractLabeled(text, ['ubicacion', 'ubicación', 'residencia', 'ciudad', 'localidad'], 120) };
}

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  emailVerified: { type: Boolean, default: true },
  emailVerificationTokenHash: { type: String, select: false },
  emailVerificationExpires: { type: Date, select: false },
  emailVerificationRequestedAt: { type: Date, select: false },
  phone: { type: String, trim: true },
  passwordHash: { type: String, required: true },
  passwordResetTokenHash: { type: String, select: false },
  passwordResetExpires: { type: Date, select: false },
  passwordResetRequestedAt: { type: Date, select: false },
  role: { type: String, enum: ['candidate', 'company'], required: true },
  country: { type: String, default: 'PE' },
  ruc: { type: String, trim: true },
  companyProfile: { type: CompanyProfileSchema, default: () => ({}) },
  companyVerification: { status: { type: String, enum: ['unverified', 'pending', 'verified'], default: 'unverified' }, verifiedAt: { type: Date, default: null }, verificationNote: { type: String, trim: true, maxlength: 500, default: '' } },
  conadisNumber: { type: String, trim: true, default: null },
  accreditationType: { type: String, trim: true, default: 'Carné CONADIS' },
  profile: { type: CandidateProfileSchema, default: () => ({}) },
  cv: { type: CvSchema, default: undefined },
  cvAnalysis: { type: CvAnalysisSchema, default: undefined },
  profilePhoto: { type: ProfilePhotoSchema, default: undefined },
  savedJobs: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Job' }],
  savedJobSearches: { type: [SavedJobSearchSchema], default: [] }
}, { timestamps: true });

UserSchema.pre('save', async function autofillProfileFromCv() {
  if (this.role !== 'candidate' || !this.cv?.data?.length) return;
  if (!this.isModified('cv') && !this.isModified('cvAnalysis')) return;
  try {
    const extracted = await extractProfileFromCv(Buffer.from(this.cv.data), this.cv.fileName);
    const profile = this.profile || {};
    if (!String(profile.education || '').trim() && extracted.education) profile.education = extracted.education;
    if (!String(profile.professionalSummary || '').trim() && extracted.professionalSummary) profile.professionalSummary = extracted.professionalSummary;
    if ((!Number(profile.experience) || Number(profile.experience) < 1) && extracted.experience > 0) profile.experience = extracted.experience;
    if (!String(profile.modality || '').trim() && extracted.modality) profile.modality = extracted.modality;
    if (!String(profile.location || '').trim() && extracted.location) profile.location = extracted.location;
    profile.skills = [...new Set([...(Array.isArray(profile.skills) ? profile.skills.map(String) : []), ...(extracted.skills || [])])].slice(0, 40);
    profile.projects = [...new Set([...(Array.isArray(profile.projects) ? profile.projects.map(String) : []), ...(extracted.projects || [])])].slice(0, 20);
    profile.certifications = [...new Set([...(Array.isArray(profile.certifications) ? profile.certifications.map(String) : []), ...(extracted.certifications || [])])].slice(0, 20);
    this.profile = profile;
  } catch (error) { console.error('No se pudo autocompletar el perfil desde el CV:', error.message); }
});

UserSchema.index({ conadisNumber: 1 }, { unique: true, partialFilterExpression: { conadisNumber: { $type: 'string' } } });
module.exports = mongoose.model('User', UserSchema);
