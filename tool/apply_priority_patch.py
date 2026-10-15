from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path, old, new):
    p = ROOT / path
    s = p.read_text(encoding='utf-8')
    if old not in s:
        raise SystemExit(f'No se encontró el patrón esperado en {path}: {old[:100]}')
    p.write_text(s.replace(old, new, 1), encoding='utf-8')


# 1) Candidate accessibility preferences + company verification state.
replace_once('backend/models/User.js',
"const CandidateProfileSchema = new mongoose.Schema({\n",
"const AccessibilityPreferencesSchema = new mongoose.Schema({\n  share: { type: Boolean, default: false },\n  needType: { type: String, trim: true, maxlength: 80, default: '' },\n  preferences: { type: [String], default: [] }\n}, { _id: false });\n\nconst CandidateProfileSchema = new mongoose.Schema({\n")
replace_once('backend/models/User.js',
"  location: { type: String, trim: true }\n}, { _id: false });",
"  location: { type: String, trim: true },\n  accessibility: { type: AccessibilityPreferencesSchema, default: () => ({}) }\n}, { _id: false });")
replace_once('backend/models/User.js',
"  companyProfile: { type: CompanyProfileSchema, default: () => ({}) },",
"  companyProfile: { type: CompanyProfileSchema, default: () => ({}) },\n  companyVerification: {\n    status: { type: String, enum: ['unverified', 'pending', 'verified'], default: 'unverified' },\n    verifiedAt: { type: Date, default: null },\n    verificationNote: { type: String, trim: true, maxlength: 500, default: '' }\n  },")

# 2) Structured accessibility data for jobs, while keeping legacy free-text compatibility.
replace_once('backend/models/Job.js',
"const JobSchema = new mongoose.Schema({",
"const JobAccessibilitySchema = new mongoose.Schema({\n  remote: { type: Boolean, default: false },\n  hybrid: { type: Boolean, default: false },\n  physicalAccess: { type: Boolean, default: false },\n  flexibleSchedule: { type: Boolean, default: false },\n  workplaceAdaptation: { type: Boolean, default: false },\n  assistiveTechnology: { type: Boolean, default: false },\n  accessibleRestroom: { type: Boolean, default: false },\n  elevator: { type: Boolean, default: false },\n  accessibleParking: { type: Boolean, default: false },\n  transportationSupport: { type: Boolean, default: false },\n  interpreter: { type: Boolean, default: false },\n  notes: { type: String, trim: true, maxlength: 1200, default: '' }\n}, { _id: false });\n\nconst JobSchema = new mongoose.Schema({")
replace_once('backend/models/Job.js',
"  accessibilityDetails: { type: String, trim: true, maxlength: 1200, default: '' },",
"  accessibilityDetails: { type: String, trim: true, maxlength: 1200, default: '' },\n  accessibility: { type: JobAccessibilitySchema, default: () => ({}) },")

# 3) Add report model.
report = ROOT / 'backend/models/Report.js'
if not report.exists():
    report.write_text("""const mongoose = require('mongoose');\n\nconst ReportSchema = new mongoose.Schema({\n  reporterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },\n  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },\n  reason: { type: String, required: true, trim: true, maxlength: 120 },\n  details: { type: String, trim: true, maxlength: 1500, default: '' },\n  status: { type: String, enum: ['open', 'reviewing', 'resolved'], default: 'open' }\n}, { timestamps: true });\n\nReportSchema.index({ reporterId: 1, jobId: 1 }, { unique: true });\nmodule.exports = mongoose.model('Report', ReportSchema);\n""", encoding='utf-8')

# 4) Backend routes. They are inserted before the generic error handler.
server = ROOT / 'backend/server.js'
s = server.read_text(encoding='utf-8')
if "const Report = require('./models/Report');" not in s:
    s = s.replace("const Notification = require('./models/Notification');", "const Notification = require('./models/Notification');\nconst Report = require('./models/Report');", 1)

routes = r'''

// --- INKLU accessibility priorities ---
app.get('/api/profile/accessibility', auth, async (req, res) => {
  if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden consultar sus preferencias.' });
  res.json({ accessibility: req.user.profile?.accessibility || { share: false, needType: '', preferences: [] } });
});

app.patch('/api/profile/accessibility', auth, async (req, res) => {
  if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden guardar preferencias.' });
  const input = req.body?.accessibility || req.body || {};
  const allowed = new Set([
    'Trabajo remoto','Trabajo híbrido','Horario flexible','Acceso sin escaleras','Ascensor',
    'Baño accesible','Estacionamiento accesible','Adaptación del puesto','Tecnología asistiva',
    'Intérprete','Apoyo para desplazamiento','Otro'
  ]);
  const preferences = Array.isArray(input.preferences)
    ? input.preferences.map(v => String(v).trim()).filter(v => allowed.has(v)).slice(0, 20)
    : [];
  req.user.profile.accessibility = {
    share: input.share === true,
    needType: String(input.needType || '').trim().slice(0, 80),
    preferences
  };
  await req.user.save();
  res.json({ message: 'Preferencias de accesibilidad guardadas.', accessibility: req.user.profile.accessibility });
});

app.post('/api/company/verification', auth, async (req, res) => {
  if (req.user.role !== 'company') return res.status(403).json({ message: 'Solo las empresas pueden solicitar verificación.' });
  const ruc = String(req.user.ruc || '').trim();
  if (!/^\d{11}$/.test(ruc)) return res.status(400).json({ message: 'La empresa necesita un RUC de 11 dígitos para solicitar verificación.' });
  const autoVerify = String(process.env.AUTO_VERIFY_COMPANIES || '').toLowerCase() === 'true';
  req.user.companyVerification = {
    status: autoVerify ? 'verified' : 'pending',
    verifiedAt: autoVerify ? new Date() : null,
    verificationNote: autoVerify ? 'Verificación básica automática: RUC y datos de empresa presentes.' : 'Solicitud pendiente de validación administrativa.'
  };
  await req.user.save();
  res.json({ message: autoVerify ? 'Empresa verificada.' : 'Solicitud de verificación enviada.', verification: req.user.companyVerification });
});

app.post('/api/jobs/:jobId/report', auth, async (req, res) => {
  if (req.user.role !== 'candidate') return res.status(403).json({ message: 'Solo los candidatos pueden reportar ofertas.' });
  const job = await Job.findOne({ _id: req.params.jobId, active: true }).select('_id companyId');
  if (!job) return res.status(404).json({ message: 'Oferta no encontrada.' });
  const reason = String(req.body?.reason || '').trim();
  const details = String(req.body?.details || '').trim();
  const allowedReasons = ['Información falsa','Empresa sospechosa','Discriminación','Accesibilidad indicada no disponible','Requisitos discriminatorios','Salario engañoso','Otro'];
  if (!allowedReasons.includes(reason)) return res.status(400).json({ message: 'Selecciona un motivo válido.' });
  if (details.length > 1500) return res.status(400).json({ message: 'La descripción es demasiado larga.' });
  try {
    const report = await Report.create({ reporterId: req.user._id, jobId: job._id, reason, details });
    res.status(201).json({ message: 'Reporte recibido. Gracias por ayudar a mantener INKLU segura e inclusiva.', id: report._id });
  } catch (error) {
    if (error?.code === 11000) return res.status(409).json({ message: 'Ya reportaste esta oferta. Nuestro equipo podrá revisar el reporte existente.' });
    throw error;
  }
});

'''
if "app.get('/api/profile/accessibility'" not in s:
    marker = "app.use((err, req, res, next) => {"
    if marker not in s:
        raise SystemExit('No se encontró el punto de inserción de rutas en server.js')
    s = s.replace(marker, routes + marker, 1)
server.write_text(s, encoding='utf-8')

# 5) Flutter API client methods.
api = ROOT / 'flutter_app/lib/services/api_service.dart'
a = api.read_text(encoding='utf-8')
needle = "  Future<Map<String, dynamic>> deleteAccount(String token, String password) async => _deleteAuth('/profile/me', token, {'password': password});"
if 'accessibilityProfile(String token)' not in a:
    additions = needle + "\n  Future<Map<String, dynamic>> accessibilityProfile(String token) async => _getMap('/profile/accessibility', token);\n  Future<Map<String, dynamic>> updateAccessibilityProfile(String token, Map<String, dynamic> data) async => _patch('/profile/accessibility', token, data);\n  Future<Map<String, dynamic>> reportJob(String token, String jobId, {required String reason, String details = ''}) async => _postAuth('/jobs/$jobId/report', token, {'reason': reason, 'details': details});\n  Future<Map<String, dynamic>> verifyCompany(String token, {String? evidence}) async => _postAuth('/company/verification', token, {'evidence': evidence ?? ''});"
    if needle not in a:
        raise SystemExit('No se encontró deleteAccount en api_service.dart')
    a = a.replace(needle, additions, 1)
    api.write_text(a, encoding='utf-8')

# 6) Integrate the accessibility page and report action into the Flutter UI.
main = ROOT / 'flutter_app/lib/main.dart'
m = main.read_text(encoding='utf-8')
if "services/accessibility_page.dart" not in m:
    m = m.replace("import 'services/api_service.dart';", "import 'services/api_service.dart';\nimport 'services/accessibility_page.dart';", 1)

profile_marker = "        const SizedBox(height: 8),\n        DeleteAccountButton(token: widget.token),"
if profile_marker in m and "AccessibilityPreferencesPage(token: widget.token)" not in m:
    replacement = """        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccessibilityPreferencesPage(token: widget.token))),
            icon: const Icon(Icons.accessibility_new_rounded),
            label: const Text('Preferencias de accesibilidad'),
          ),
        ),
        const SizedBox(height: 8),
        DeleteAccountButton(token: widget.token),"""
    m = m.replace(profile_marker, replacement, 1)

report_marker = "            Out('Cerrar detalles', () => Navigator.pop(sheetContext)),"
if report_marker in m and 'showJobReportDialog(sheetContext' not in m:
    replacement = """            Out('Reportar oferta', () {
              final id = (d['_id'] ?? d['id'] ?? '').toString();
              if (id.isNotEmpty && sessionToken != null) showJobReportDialog(sheetContext, sessionToken!, id);
            }),
            const SizedBox(height: 8),
            Out('Cerrar detalles', () => Navigator.pop(sheetContext)),"""
    m = m.replace(report_marker, replacement, 1)

main.write_text(m, encoding='utf-8')
print('Priority patch applied successfully.')
