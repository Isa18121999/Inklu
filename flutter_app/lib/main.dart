import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

const primary = Color(0xFF4F46E5);
const ink = Color(0xFF111827);
const muted = Color(0xFF64748B);
const line = Color(0xFFE2E8F0);
final messenger = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'INKLU',
        scaffoldMessengerKey: messenger,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: primary),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary, width: 1.5)),
          ),
        ),
        home: const WelcomePage(),
      );
}

class Logo extends StatefulWidget {
  final double size;
  const Logo({super.key, this.size = 100});
  @override State<Logo> createState() => _LogoState();
}
class _LogoState extends State<Logo> {
  Uint8List? bytes;
  @override void initState() { super.initState(); _loadLogo(); }
  Future<void> _loadLogo() async {
    try {
      final encoded = await rootBundle.loadString('assets/logo.b64');
      if (mounted) setState(() => bytes = base64Decode(encoded.trim()));
    } catch (_) {}
  }
  @override Widget build(BuildContext context) => bytes == null
      ? SizedBox(width: widget.size, height: widget.size, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primary)))
      : Image.memory(bytes!, width: widget.size, height: widget.size, fit: BoxFit.contain, filterQuality: FilterQuality.high);
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(body: Stack(children: [
    Positioned(left: -50, bottom: 20, child: blob(const Color(0xFFE8F7FF), 140)),
    Positioned(right: -55, top: 20, child: blob(const Color(0xFFF1EDFF), 150)),
    SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(children: [
      const Logo(size: 155), const Text('INKLU', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: ink)),
      const SizedBox(height: 8), const Text('Talento, inclusión y\noportunidades laborales', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: muted, height: 1.35)),
      const SizedBox(height: 34), Button('Empezar', () => push(context, const RolePage())), const SizedBox(height: 10), OutlinedAction('Iniciar sesión', () => push(context, const LoginPage())),
    ])))
  ]));
}
Widget blob(Color color, double size) => Container(width: size, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * .4)));
void push(BuildContext c, Widget p) => Navigator.push(c, MaterialPageRoute(builder: (_) => p));
void message(String text) => messenger.currentState?.showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

class RolePage extends StatelessWidget {
  const RolePage({super.key});
  @override Widget build(BuildContext context) => Page(title: '¿Cómo quieres\nempezar?', subtitle: 'Elige el tipo de cuenta que mejor\nte describe.', child: Column(children: [
    RoleCard(Icons.accessibility_new, 'Soy candidato', 'Busco oportunidades laborales.', const Color(0xFFEDE9FE), () => push(context, const CandidateRegister())),
    const SizedBox(height: 14), RoleCard(Icons.business_center_outlined, 'Soy empresa', 'Busco talento diverso.', const Color(0xFFE0F2FE), () => push(context, const CompanyRegister())),
  ]));
}

class CandidateRegister extends StatefulWidget {
  const CandidateRegister({super.key});
  @override State<CandidateRegister> createState() => _CandidateRegisterState();
}
class _CandidateRegisterState extends State<CandidateRegister> {
  int step = 0;
  final name = TextEditingController(), surname = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  final birth = TextEditingController(), phone = TextEditingController(), address = TextEditingController(text: 'Lima, Perú'), conadis = TextEditingController(), cv = TextEditingController();
  bool terms = false, loading = false;
  DateTime? birthDate;

  Future<void> pickBirthDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now(), helpText: 'Selecciona tu fecha de nacimiento', cancelText: 'Cancelar', confirmText: 'Aceptar');
    if (picked != null) {
      birthDate = picked;
      birth.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }

  Future<void> pickCv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'], withData: false);
    if (result != null && result.files.single.name.isNotEmpty) setState(() => cv.text = result.files.single.name);
  }

  Future<void> next() async {
    if (step == 0 && (name.text.trim().isEmpty || surname.text.trim().isEmpty || !validEmail(email.text) || !validPassword(password.text) || !terms)) {
      message('Completa nombres, apellidos, correo, contraseña y acepta los términos.'); return;
    }
    if (step == 1 && (!RegExp(r'^\d{9}$').hasMatch(phone.text) || birthDate == null || !RegExp(r'^\d+$').hasMatch(conadis.text.trim()) || conadis.text.trim().isEmpty)) {
      message('Completa la fecha de nacimiento, teléfono y número de CONADIS.'); return;
    }
    if (step == 2 && cv.text.trim().isEmpty) {
      message('Debes subir tu CV para finalizar el registro.'); return;
    }
    if (step < 2) { setState(() => step++); return; }
    setState(() => loading = true);
    try {
      await ApiService().registerCandidate(name: '${name.text.trim()} ${surname.text.trim()}', email: email.text.trim(), phone: phone.text, password: password.text, conadisNumber: conadis.text.trim());
      if (!mounted) return;
      message('Cuenta creada correctamente.');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CandidateDashboard()), (_) => false);
    } catch (e) { message(cleanError(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override Widget build(BuildContext context) => Page(
    title: step == 0 ? 'Crear cuenta\ncomo candidato' : step == 1 ? 'Información\npersonal' : 'Perfil profesional',
    subtitle: step == 0 ? 'Completa tus datos para comenzar.' : step == 1 ? 'Cuéntanos más sobre ti.' : 'Sube tu CV para completar tu perfil profesional.',
    child: Column(children: [
      Dots(step), const SizedBox(height: 18),
      if (step == 0) ...[
        Field(name, 'Nombres'), Field(surname, 'Apellidos'), Field(email, 'Correo electrónico', keyboard: TextInputType.emailAddress), Field(password, 'Contraseña', obscure: true),
        const Align(alignment: Alignment.centerLeft, child: Text('Mínimo 8: mayúscula, minúscula, número y símbolo.', style: TextStyle(fontSize: 11, color: muted))),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: terms, activeColor: primary, onChanged: (v) => setState(() => terms = v ?? false), title: const Text('Acepto los términos y condiciones', style: TextStyle(fontSize: 13))),
      ] else if (step == 1) ...[
        Field(birth, 'Fecha de nacimiento', readOnly: true, onTap: pickBirthDate, suffix: const Icon(Icons.calendar_today_outlined, color: primary)),
        Field(phone, 'Teléfono', keyboard: TextInputType.phone, formatters: digits(9)),
        Field(address, 'Dirección'),
        Field(email, 'Correo electrónico', keyboard: TextInputType.emailAddress),
        Field(conadis, 'Número de CONADIS', keyboard: TextInputType.number, formatters: digits(20)),
      ] else ...[
        InkWell(onTap: pickCv, borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(border: Border.all(color: cv.text.isEmpty ? line : primary, width: cv.text.isEmpty ? 1 : 1.5), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.upload_file_outlined, color: primary, size: 30), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cv.text.isEmpty ? 'Subir CV' : cv.text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), const SizedBox(height: 5), Text(cv.text.isEmpty ? 'PDF, DOC o DOCX' : 'Archivo seleccionado', style: const TextStyle(fontSize: 12, color: muted))])), const Icon(Icons.chevron_right, color: muted)]))),
      ],
      const SizedBox(height: 18), Button(step == 2 ? (loading ? 'Guardando...' : 'Finalizar') : 'Siguiente', loading ? null : next),
    ]));
}

class CompanyRegister extends StatefulWidget {
  const CompanyRegister({super.key});
  @override State<CompanyRegister> createState() => _CompanyRegisterState();
}
class _CompanyRegisterState extends State<CompanyRegister> {
  int step = 0;
  final company = TextEditingController(), ruc = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  final size = TextEditingController(), address = TextEditingController(text: 'Lima, Perú'), website = TextEditingController(), description = TextEditingController();
  bool terms = false, loading = false;
  String? selectedSector;
  final sectors = const ['Tecnología', 'Educación', 'Salud', 'Finanzas', 'Comercio', 'Manufactura', 'Servicios', 'Construcción', 'Transporte', 'Turismo', 'Otro'];

  Future<void> next() async {
    if (step == 0 && (company.text.trim().isEmpty || !RegExp(r'^\d{11}$').hasMatch(ruc.text) || !validEmail(email.text) || !validPassword(password.text) || !terms)) {
      message('Verifica empresa, RUC, correo, contraseña y términos.'); return;
    }
    if (step == 1) {
      if (selectedSector == null || size.text.trim().isEmpty || address.text.trim().isEmpty || website.text.trim().isEmpty || description.text.trim().isEmpty) { message('Completa todos los datos de la empresa.'); return; }
      setState(() => loading = true);
      try {
        await ApiService().registerCompany(name: company.text.trim(), email: email.text.trim(), phone: '', password: password.text, ruc: ruc.text);
        if (!mounted) return;
        message('Empresa registrada correctamente.');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CompanyDashboard()), (_) => false);
      } catch (e) { message(cleanError(e)); }
      finally { if (mounted) setState(() => loading = false); }
      return;
    }
  }

  @override Widget build(BuildContext context) => Page(
    title: step == 0 ? 'Crear cuenta\ncomo empresa' : 'Información\nde la empresa',
    subtitle: step == 0 ? 'Ingresa los datos de tu organización.' : 'Completa los datos de tu organización.',
    child: Column(children: [
      Dots(step), const SizedBox(height: 18),
      if (step == 0) ...[
        Field(company, 'Nombre de la empresa'), Field(ruc, 'RUC', keyboard: TextInputType.number, formatters: digits(11)), Field(email, 'Correo institucional', keyboard: TextInputType.emailAddress), Field(password, 'Contraseña', obscure: true),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: terms, activeColor: primary, onChanged: (v) => setState(() => terms = v ?? false), title: const Text('Acepto los términos y condiciones', style: TextStyle(fontSize: 13))),
      ] else ...[
        DropdownButtonFormField<String>(value: selectedSector, decoration: const InputDecoration(labelText: 'Sector'), items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => selectedSector = v), hint: const Text('Selecciona un sector')),
        const SizedBox(height: 11), Field(size, 'Tamaño de la empresa'), Field(address, 'Dirección'), Field(website, 'Sitio web'), Field(description, 'Descripción de la empresa', maxLines: 4),
      ],
      const SizedBox(height: 18), Button(step == 1 ? (loading ? 'Guardando...' : 'Finalizar') : 'Siguiente', loading ? null : next),
    ]));
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState() => _LoginState(); }
class _LoginState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController(); bool loading = false;
  Future<void> login() async {
    if (!validEmail(email.text) || password.text.isEmpty) { message('Ingresa un correo y una contraseña válidos.'); return; }
    setState(() => loading = true);
    try { final result = await ApiService().login(email.text.trim(), password.text); if (!mounted) return; final role = result['user']?['role']?.toString().toLowerCase() ?? 'candidate'; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => role == 'company' ? const CompanyDashboard() : const CandidateDashboard()), (_) => false); }
    catch (e) { message(cleanError(e)); } finally { if (mounted) setState(() => loading = false); }
  }
  @override Widget build(BuildContext context) => Page(title: 'Iniciar sesión', subtitle: 'Ingresa a tu cuenta de INKLU.', child: Column(children: [Field(email, 'Correo electrónico', keyboard: TextInputType.emailAddress), Field(password, 'Contraseña', obscure: true), const SizedBox(height: 8), Button(loading ? 'Ingresando...' : 'Ingresar', loading ? null : login)]));
}

class CandidateDashboard extends StatefulWidget { const CandidateDashboard({super.key}); @override State<CandidateDashboard> createState() => _CandidateDashState(); }
class _CandidateDashState extends State<CandidateDashboard> {
  int tab = 0;
  @override Widget build(BuildContext context) => Dashboard(title: tab == 0 ? '¡Hola, María!' : ['Inicio', 'Empleos', 'Postulaciones', 'Perfil'][tab], tab: tab, onTab: (v) => setState(() => tab = v), children: tab == 0 ? [
    const Text('Aquí encontrarás oportunidades que se ajustan a tu perfil.', style: TextStyle(color: muted)), const SizedBox(height: 18), const Search(hint: 'Buscar empleos, empresas...'), const SizedBox(height: 18), const Match(), const SizedBox(height: 22), const Section('Empleos recomendados'), const Job('Asistente Administrativo', 'BCP', 'Lima · Tiempo completo', '85% Match'), const Job('Analista de Datos', 'Intercorp', 'Lima · Híbrido', '72% Match'),
  ] : [const Info('Sección preparada', 'Aquí se mostrarán tus datos conectados al backend.')]);
}

class CompanyDashboard extends StatefulWidget { const CompanyDashboard({super.key}); @override State<CompanyDashboard> createState() => _CompanyDashState(); }
class _CompanyDashState extends State<CompanyDashboard> {
  int tab = 0;
  @override Widget build(BuildContext context) => Dashboard(title: tab == 0 ? '¡Hola, Carlos!' : ['Inicio', 'Ofertas', 'Candidatos', 'Notificaciones'][tab], tab: tab, onTab: (v) => setState(() => tab = v), children: tab == 0 ? [
    const Text('Gestiona tus ofertas y conecta con talento diverso.', style: TextStyle(color: muted)), const SizedBox(height: 18), const Row(children: [Expanded(child: Stat('5', 'Ofertas activas')), SizedBox(width: 8), Expanded(child: Stat('28', 'Postulaciones')), SizedBox(width: 8), Expanded(child: Stat('12', 'En revisión'))]), const SizedBox(height: 16), Button('+  Crear nueva oferta', () => push(context, const CreateOfferPage())), const SizedBox(height: 20), const Section('Últimas postulaciones'), const Applicant('Ana Torres', 'Analista de marketing', '85%'), const Applicant('Luis Mendoza', 'Asistente administrativo', '78%'), const Applicant('Sofia Rojas', 'Analista de datos', '72%'),
  ] : [const Info('Sección preparada', 'Aquí se mostrarán los datos de tu empresa.')]);
}

class CreateOfferPage extends StatefulWidget { const CreateOfferPage({super.key}); @override State<CreateOfferPage> createState() => _OfferState(); }
class _OfferState extends State<CreateOfferPage> {
  final title = TextEditingController(), description = TextEditingController(), location = TextEditingController(text: 'Lima, Perú'), salary = TextEditingController(); String contract = 'Selecciona', modality = 'Selecciona';
  @override Widget build(BuildContext context) => Dashboard(title: 'Crear nueva oferta', tab: 1, onTab: (_) {}, children: [const Text('Completa la información del puesto.', style: TextStyle(color: muted)), const SizedBox(height: 18), Field(title, 'Título del puesto'), Field(description, 'Descripción del puesto', maxLines: 5), Select(contract, 'Tipo de contrato', ['Tiempo completo', 'Medio tiempo', 'Prácticas'], (v) => setState(() => contract = v)), Select(modality, 'Modalidad', ['Presencial', 'Híbrido', 'Remoto'], (v) => setState(() => modality = v)), Field(location, 'Ubicación'), Field(salary, 'Salario (opcional)', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]), const SizedBox(height: 8), Button('Publicar oferta', () => message('Oferta creada correctamente.'))]);
}

class Page extends StatelessWidget {
  final String title, subtitle; final Widget child;
  const Page({super.key, required this.title, required this.subtitle, required this.child});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)) : null, title: const Text('INKLU', style: TextStyle(fontWeight: FontWeight.w900))), body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 14, 22, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 24, height: 1.12, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 8), Text(subtitle, style: const TextStyle(color: muted, height: 1.35)), const SizedBox(height: 14), child]))));
}
class Dashboard extends StatelessWidget {
  final String title; final int tab; final ValueChanged<int> onTab; final List<Widget> children;
  const Dashboard({super.key, required this.title, required this.tab, required this.onTab, required this.children});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Row(children: [const Logo(size: 38), const SizedBox(width: 7), const Text('INKLU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))]), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)), const Padding(padding: EdgeInsets.only(right: 12), child: CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)))]), body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 4), ...children]), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: onTab, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'), NavigationDestination(icon: Icon(Icons.business_center_outlined), label: 'Ofertas'), NavigationDestination(icon: Icon(Icons.people_outline), label: 'Candidatos'), NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil')]));
}
class Dots extends StatelessWidget { final int step; const Dots(this.step, {super.key}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: i == step ? 8 : 6, height: i == step ? 8 : 6, decoration: BoxDecoration(shape: BoxShape.circle, color: i == step ? primary : const Color(0xFFD8DCE7))))); }
class RoleCard extends StatelessWidget { final IconData icon; final String title, sub; final Color bg; final VoidCallback tap; const RoleCard(this.icon, this.title, this.sub, this.bg, this.tap, {super.key}); @override Widget build(BuildContext c) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: bg.withOpacity(.45), borderRadius: BorderRadius.circular(14), border: Border.all(color: line)), child: Row(children: [Container(width: 62, height: 74, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 38, color: primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(sub, style: const TextStyle(color: muted, fontSize: 12))])), const CircleAvatar(radius: 14, backgroundColor: primary, child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white))]))); }
class Field extends StatelessWidget {
  final TextEditingController c; final String label; final bool obscure; final bool readOnly; final TextInputType? keyboard; final int maxLines; final List<TextInputFormatter>? formatters; final VoidCallback? onTap; final Widget? suffix;
  const Field(this.c, this.label, {super.key, this.obscure = false, this.readOnly = false, this.keyboard, this.maxLines = 1, this.formatters, this.onTap, this.suffix});
  @override Widget build(BuildContext x) => Padding(padding: const EdgeInsets.only(bottom: 11), child: TextField(controller: c, obscureText: obscure, readOnly: readOnly, keyboardType: keyboard, maxLines: obscure ? 1 : maxLines, inputFormatters: formatters, onTap: onTap, decoration: InputDecoration(labelText: label, suffixIcon: suffix)));
}
class Button extends StatelessWidget { final String text; final VoidCallback? tap; const Button(this.text, this.tap, {super.key}); @override Widget build(BuildContext c) => SizedBox(width: double.infinity, height: 48, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: tap, child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)))); }
class OutlinedAction extends StatelessWidget { final String text; final VoidCallback tap; const OutlinedAction(this.text, this.tap, {super.key}); @override Widget build(BuildContext c) => SizedBox(width: double.infinity, height: 46, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: primary, side: const BorderSide(color: primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: tap, child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)))); }
class Search extends StatelessWidget { final String hint; const Search({super.key, required this.hint}); @override Widget build(BuildContext c) => TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune)), hintText: hint)); }
class Match extends StatelessWidget { const Match({super.key}); @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: line), borderRadius: BorderRadius.circular(14)), child: Row(children: [SizedBox(width: 58, height: 58, child: Stack(fit: StackFit.expand, children: [const CircularProgressIndicator(value: .8, strokeWidth: 6, color: primary, backgroundColor: Color(0xFFEAEAF5)), const Center(child: Text('80%', style: TextStyle(fontWeight: FontWeight.w800)))])), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tu perfil', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Completa tu perfil para mejorar tu matching.', style: TextStyle(fontSize: 12, color: muted)), SizedBox(height: 4), Text('Ver perfil →', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12))]))])); }
class Section extends StatelessWidget { final String text; const Section(this.text, {super.key}); @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))); }
class Job extends StatelessWidget { final String title, company, details, match; const Job(this.title, this.company, this.details, this.match, {super.key}); @override Widget build(BuildContext c) => Card(margin: const EdgeInsets.only(bottom: 9), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: line)), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFEDE9FE), child: Text(company[0], style: const TextStyle(color: primary, fontWeight: FontWeight.w800))), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), subtitle: Text('$company\n$details\n$match', style: const TextStyle(fontSize: 11)), trailing: const Icon(Icons.favorite_border, size: 20))); }
class Stat extends StatelessWidget { final String n, label; const Stat(this.n, this.label, {super.key}); @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 3), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(n, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: primary)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: muted))])); }
class Applicant extends StatelessWidget { final String name, role, match; const Applicant(this.name, this.role, this.match, {super.key}); @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: line))), child: Row(children: [const CircleAvatar(radius: 20, child: Icon(Icons.person)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text(role, style: const TextStyle(fontSize: 11, color: muted))])), Text(match, style: const TextStyle(color: primary, fontWeight: FontWeight.w800)), const Icon(Icons.chevron_right, size: 18)])); }
class Info extends StatelessWidget { final String title, sub; const Info(this.title, this.sub, {super.key}); @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(border: Border.all(color: line), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(sub, style: const TextStyle(color: muted))])); }
class Select extends StatelessWidget { final String value, label; final List<String> options; final ValueChanged<String> onChanged; const Select(this.value, this.label, this.options, this.onChanged, {super.key}); @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 11), child: DropdownButtonFormField<String>(value: value, decoration: InputDecoration(labelText: label), items: [const DropdownMenuItem(value: 'Selecciona', child: Text('Selecciona')), ...options.map((e) => DropdownMenuItem(value: e, child: Text(e)))], onChanged: (v) { if (v != null) onChanged(v); })); }
List<TextInputFormatter> digits(int max) => [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(max)];
bool validEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
bool validPassword(String v) => v.length >= 8 && RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v) && RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[^A-Za-z0-9]').hasMatch(v);
String cleanError(Object e) => e.toString().replaceFirst('Exception: ', '').trim();