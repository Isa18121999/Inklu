import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

const primary = Color(0xFF4F46E5);
const textDark = Color(0xFF111827);
const textMuted = Color(0xFF64748B);
const border = Color(0xFFE2E8F0);
const logoUrl = 'https://raw.githubusercontent.com/Isa18121999/Inklu/main/assets/logo.png';
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const InkluApp());
}

class InkluApp extends StatelessWidget {
  const InkluApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'INKLU',
        scaffoldMessengerKey: messengerKey,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: primary),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary, width: 1.6)),
            labelStyle: const TextStyle(color: textMuted),
          ),
        ),
        home: const WelcomePage(),
      );
}

class InkluLogo extends StatelessWidget {
  final double size;
  const InkluLogo({super.key, this.size = 86});
  @override
  Widget build(BuildContext context) => Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: primary, size: 48),
      );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          Positioned(left: -45, bottom: 18, child: _Blob(color: const Color(0xFFE8F7FF), size: 130)),
          Positioned(right: -48, top: 24, child: _Blob(color: const Color(0xFFF0EAFE), size: 150)),
          SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(children: [
            const InkluLogo(size: 155),
            const Text('INKLU', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textDark)),
            const SizedBox(height: 8),
            const Text('Talento, inclusión y\noportunidades laborales', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textMuted, height: 1.35)),
            const SizedBox(height: 34),
            PrimaryButton(text: 'Empezar', onPressed: () => _push(context, const RolePage())),
            const SizedBox(height: 10),
            OutlineButton(text: 'Iniciar sesión', onPressed: () => _push(context, const LoginPage())),
          ]))))
        ]),
      );
}

class _Blob extends StatelessWidget {
  final Color color; final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * .42)));
}

class RolePage extends StatelessWidget {
  const RolePage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        title: '¿Cómo quieres\nempezar?',
        subtitle: 'Elige el tipo de cuenta que mejor\nte describe.',
        child: Column(children: [
          RoleCard(icon: Icons.accessibility_new, title: 'Soy candidato', subtitle: 'Busco oportunidades laborales.', accent: const Color(0xFFEDE9FE), onTap: () => _push(context, const CandidateRegisterPage())),
          const SizedBox(height: 14),
          RoleCard(icon: Icons.business_center_outlined, title: 'Soy empresa', subtitle: 'Busco talento diverso.', accent: const Color(0xFFE0F2FE), onTap: () => _push(context, const CompanyRegisterPage())),
        ]),
      );
}

class CandidateRegisterPage extends StatefulWidget {
  const CandidateRegisterPage({super.key});
  @override State<CandidateRegisterPage> createState() => _CandidateRegisterPageState();
}
class _CandidateRegisterPageState extends State<CandidateRegisterPage> {
  int step = 0;
  final name = TextEditingController(), surname = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  final birth = TextEditingController(text: '15/03/1998'), phone = TextEditingController(), address = TextEditingController(text: 'Lima, Perú'), conadis = TextEditingController();
  final skills = TextEditingController();
  bool terms = false, hasConadis = true, loading = false;

  Future<void> next() async {
    if (step == 0) {
      if (name.text.trim().isEmpty || surname.text.trim().isEmpty || !_validEmail(email.text) || !_validPassword(password.text) || !terms) {
        _error('Revisa tus datos. Acepta los términos y usa una contraseña segura.'); return;
      }
    }
    if (step == 1) {
      if (!RegExp(r'^\d{9}$').hasMatch(phone.text) || (hasConadis && !RegExp(r'^\d{8,12}$').hasMatch(conadis.text))) {
        _error('El teléfono y el número de CONADIS deben contener solo números.'); return;
      }
    }
    if (step < 2) { setState(() => step++); return; }
    setState(() => loading = true);
    try {
      await ApiService().registerCandidate(name: '${name.text.trim()} ${surname.text.trim()}', email: email.text.trim(), phone: phone.text, password: password.text, conadisNumber: hasConadis ? conadis.text : '');
      if (!mounted) return;
      _success('Cuenta creada correctamente.');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CandidateDashboard()), (_) => false);
    } catch (e) { _error(_cleanError(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: step == 0 ? 'Crear cuenta\ncomo candidato' : step == 1 ? 'Información\npersonal' : 'Perfil profesional',
        subtitle: step == 0 ? 'Completa tus datos para comenzar.' : step == 1 ? 'Cuéntanos más sobre ti.' : 'Completa tu perfil para un mejor matching.',
        child: Column(children: [
          StepDots(current: step), const SizedBox(height: 18),
          if (step == 0) ...[
            Field(controller: name, label: 'Nombres'),
            Field(controller: surname, label: 'Apellidos'),
            Field(controller: email, label: 'Correo electrónico', keyboard: TextInputType.emailAddress),
            Field(controller: password, label: 'Contraseña', obscure: true),
            const Align(alignment: Alignment.centerLeft, child: Text('Mínimo 8 caracteres: mayúscula, minúscula, número y símbolo.', style: TextStyle(fontSize: 11, color: textMuted))),
            const SizedBox(height: 10),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: terms, activeColor: primary, onChanged: (v) => setState(() => terms = v ?? false), title: const Text('Acepto los términos y condiciones', style: TextStyle(fontSize: 13))),
          ] else if (step == 1) ...[
            Field(controller: birth, label: 'Fecha de nacimiento', keyboard: TextInputType.datetime),
            Field(controller: phone, label: 'Teléfono', keyboard: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]),
            Field(controller: address, label: 'Dirección'),
            Field(controller: email, label: 'Correo electrónico', keyboard: TextInputType.emailAddress),
            const Align(alignment: Alignment.centerLeft, child: Text('¿Cuentas con CONADIS?', style: TextStyle(fontWeight: FontWeight.w700))),
            Row(children: [Radio<bool>(value: true, groupValue: hasConadis, activeColor: primary, onChanged: (v) => setState(() => hasConadis = v ?? true)), const Text('Sí'), Radio<bool>(value: false, groupValue: hasConadis, activeColor: primary, onChanged: (v) => setState(() => hasConadis = v ?? false)), const Text('No')]),
            if (hasConadis) Field(controller: conadis, label: 'Número de CONADIS', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)]),
          ] else ...[
            ProfileOption(icon: Icons.school_outlined, title: 'Formación académica'),
            ProfileOption(icon: Icons.work_outline, title: 'Experiencia laboral'),
            ProfileOption(icon: Icons.link, title: 'Habilidades'),
            ProfileOption(icon: Icons.tune, title: 'Preferencias laborales'),
            Field(controller: skills, label: 'Habilidades principales (opcional)'),
          ],
          const SizedBox(height: 18),
          PrimaryButton(text: step == 2 ? (loading ? 'Guardando...' : 'Finalizar') : 'Siguiente', onPressed: loading ? null : next),
        ]),
      );
}

class CompanyRegisterPage extends StatefulWidget {
  const CompanyRegisterPage({super.key});
  @override State<CompanyRegisterPage> createState() => _CompanyRegisterPageState();
}
class _CompanyRegisterPageState extends State<CompanyRegisterPage> {
  int step = 0;
  final company = TextEditingController(), ruc = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  final sector = TextEditingController(), size = TextEditingController(), address = TextEditingController(text: 'Lima, Perú'), website = TextEditingController(), description = TextEditingController();
  final contact = TextEditingController(), position = TextEditingController(), phone = TextEditingController();
  bool terms = false, loading = false;

  Future<void> next() async {
    if (step == 0) {
      if (company.text.trim().isEmpty || !RegExp(r'^\d{11}$').hasMatch(ruc.text) || !_validEmail(email.text) || !_validPassword(password.text) || !terms) {
        _error('Completa los datos y verifica RUC, correo, contraseña y términos.'); return;
      }
    }
    if (step == 1 && (sector.text.trim().isEmpty || size.text.trim().isEmpty)) { _error('Completa sector y tamaño de la empresa.'); return; }
    if (step == 2) {
      if (contact.text.trim().isEmpty || position.text.trim().isEmpty || !RegExp(r'^\d{9}$').hasMatch(phone.text) || !_validEmail(email.text)) { _error('Revisa los datos de contacto.'); return; }
      setState(() => loading = true);
      try {
        await ApiService().registerCompany(name: company.text.trim(), email: email.text.trim(), phone: phone.text, password: password.text, ruc: ruc.text);
        if (!mounted) return;
        _success('Empresa registrada correctamente.');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CompanyDashboard()), (_) => false);
      } catch (e) { _error(_cleanError(e)); }
      finally { if (mounted) setState(() => loading = false); }
      return;
    }
    setState(() => step++);
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: step == 0 ? 'Crear cuenta\ncomo empresa' : step == 1 ? 'Información\nde la empresa' : 'Información de\ncontacto',
        subtitle: step == 0 ? 'Ingresa los datos de tu organización.' : step == 1 ? 'Completa los datos de tu organización.' : 'Datos de la persona de contacto.',
        child: Column(children: [
          StepDots(current: step), const SizedBox(height: 18),
          if (step == 0) ...[
            Field(controller: company, label: 'Nombre de la empresa'),
            Field(controller: ruc, label: 'RUC', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]),
            Field(controller: email, label: 'Correo institucional', keyboard: TextInputType.emailAddress),
            Field(controller: password, label: 'Contraseña', obscure: true),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: terms, activeColor: primary, onChanged: (v) => setState(() => terms = v ?? false), title: const Text('Acepto los términos y condiciones', style: TextStyle(fontSize: 13))),
          ] else if (step == 1) ...[
            Field(controller: sector, label: 'Sector', hint: 'Escribe el sector'),
            Field(controller: size, label: 'Tamaño de la empresa', hint: 'Ej. 11–50 empleados'),
            Field(controller: address, label: 'Dirección'),
            Field(controller: website, label: 'Sitio web'),
            Field(controller: description, label: 'Descripción de la empresa', maxLines: 4),
          ] else ...[
            Field(controller: contact, label: 'Nombre completo'),
            Field(controller: position, label: 'Cargo'),
            Field(controller: phone, label: 'Teléfono', keyboard: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]),
            Field(controller: email, label: 'Correo electrónico', keyboard: TextInputType.emailAddress),
          ],
          const SizedBox(height: 18),
          PrimaryButton(text: step == 2 ? (loading ? 'Guardando...' : 'Finalizar') : 'Siguiente', onPressed: loading ? null : next),
        ]),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool loading = false;
  Future<void> login() async {
    if (!_validEmail(email.text) || password.text.isEmpty) { _error('Ingresa un correo y una contraseña válidos.'); return; }
    setState(() => loading = true);
    try {
      final result = await ApiService().login(email.text.trim(), password.text);
      if (!mounted) return;
      final role = result['user']?['role']?.toString().toLowerCase() ?? 'candidate';
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => role == 'company' ? const CompanyDashboard() : const CandidateDashboard()), (_) => false);
    } catch (e) { _error(_cleanError(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => AppPage(title: 'Iniciar sesión', subtitle: 'Ingresa a tu cuenta de INKLU.', child: Column(children: [
    Field(controller: email, label: 'Correo electrónico', keyboard: TextInputType.emailAddress),
    Field(controller: password, label: 'Contraseña', obscure: true),
    const SizedBox(height: 10),
    PrimaryButton(text: loading ? 'Ingresando...' : 'Ingresar', onPressed: loading ? null : login),
  ]));
}

class CandidateDashboard extends StatefulWidget {
  const CandidateDashboard({super.key});
  @override State<CandidateDashboard> createState() => _CandidateDashboardState();
}
class _CandidateDashboardState extends State<CandidateDashboard> {
  int index = 0;
  @override
  Widget build(BuildContext context) => DashboardShell(index: index, onIndex: (v) => setState(() => index = v), title: index == 0 ? '¡Hola, María!' : ['Inicio', 'Empleos', 'Postulaciones', 'Perfil'][index], children: index == 0 ? [
    const Text('Aquí encontrarás oportunidades que se ajustan a tu perfil.', style: TextStyle(color: textMuted)),
    const SizedBox(height: 18),
    const SearchField(hint: 'Buscar empleos, empresas...'),
    const SizedBox(height: 18), const MatchCard(), const SizedBox(height: 22),
    const SectionTitle(title: 'Empleos recomendados'),
    const JobCard(title: 'Asistente Administrativo', company: 'BCP', location: 'Lima', modality: 'Tiempo completo', match: '85% Match'),
    const JobCard(title: 'Analista de Datos', company: 'Intercorp', location: 'Lima', modality: 'Híbrido', match: '72% Match'),
  ] : [const InfoCard(title: 'Sección preparada', subtitle: 'Aquí se mostrarán tus datos cuando estén conectados al backend.')]);
}

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});
  @override State<CompanyDashboard> createState() => _CompanyDashboardState();
}
class _CompanyDashboardState extends State<CompanyDashboard> {
  int index = 0;
  @override
  Widget build(BuildContext context) => DashboardShell(index: index, onIndex: (v) => setState(() => index = v), title: index == 0 ? '¡Hola, Carlos!' : ['Inicio', 'Ofertas', 'Candidatos', 'Notificaciones'][index], children: index == 0 ? [
    const Text('Gestiona tus ofertas y conecta con talento diverso.', style: TextStyle(color: textMuted)), const SizedBox(height: 18),
    const Row(children: [Expanded(child: StatCard(number: '5', label: 'Ofertas activas')), SizedBox(width: 8), Expanded(child: StatCard(number: '28', label: 'Postulaciones')), SizedBox(width: 8), Expanded(child: StatCard(number: '12', label: 'En revisión'))]),
    const SizedBox(height: 16), PrimaryButton(text: '+  Crear nueva oferta', onPressed: null),
    const SizedBox(height: 20), const SectionTitle(title: 'Últimas postulaciones'),
    const ApplicantRow(name: 'Ana Torres', role: 'Analista de marketing', match: '85%'),
    const ApplicantRow(name: 'Luis Mendoza', role: 'Asistente administrativo', match: '78%'),
    const ApplicantRow(name: 'Sofia Rojas', role: 'Analista de datos', match: '72%'),
  ] : [const InfoCard(title: 'Sección preparada', subtitle: 'Aquí se mostrarán los datos de tu empresa.')]);
}

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});
  @override State<CreateOfferPage> createState() => _CreateOfferPageState();
}
class _CreateOfferPageState extends State<CreateOfferPage> {
  final title = TextEditingController(), description = TextEditingController(), location = TextEditingController(text: 'Lima, Perú'), salary = TextEditingController();
  String contract = 'Selecciona', modality = 'Selecciona';
  @override
  Widget build(BuildContext context) => DashboardShell(index: 1, onIndex: (_) {}, title: 'Crear nueva oferta', children: [
    const Text('Completa la información del puesto.', style: TextStyle(color: textMuted)), const SizedBox(height: 18),
    Field(controller: title, label: 'Título del puesto'),
    Field(controller: description, label: 'Descripción del puesto', maxLines: 5, hint: 'Describe las funciones y responsabilidades...'),
    SelectField(label: 'Tipo de contrato', value: contract, options: const ['Tiempo completo', 'Medio tiempo', 'Prácticas'], onChanged: (v) => setState(() => contract = v)),
    SelectField(label: 'Modalidad', value: modality, options: const ['Presencial', 'Híbrido', 'Remoto'], onChanged: (v) => setState(() => modality = v)),
    Field(controller: location, label: 'Ubicación'),
    Field(controller: salary, label: 'Salario (opcional)', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
    const SizedBox(height: 8), PrimaryButton(text: 'Publicar oferta', onPressed: () => _success('Oferta creada.')),
  ]);
}

class AppPage extends StatelessWidget {
  final String title, subtitle; final Widget child;
  const AppPage({super.key, required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)) : null, title: const Text('INKLU', style: TextStyle(fontWeight: FontWeight.w900))),
        body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 14, 22, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 24, height: 1.12, fontWeight: FontWeight.w800, color: textDark)), const SizedBox(height: 8), Text(subtitle, style: const TextStyle(color: textMuted, height: 1.35)), const SizedBox(height: 14), child])),
      );
}

class DashboardShell extends StatelessWidget {
  final int index; final ValueChanged<int> onIndex; final String title; final List<Widget> children;
  const DashboardShell({super.key, required this.index, required this.onIndex, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Row(children: [const InkluLogo(size: 38), const SizedBox(width: 8), const Text('INKLU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))]), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)), const Padding(padding: EdgeInsets.only(right: 12), child: CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)))]),
        body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 4), ...children])),
        bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: onIndex, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'), NavigationDestination(icon: Icon(Icons.business_center_outlined), label: 'Ofertas'), NavigationDestination(icon: Icon(Icons.people_outline), label: 'Candidatos'), NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil')]),
      );
}

class StepDots extends StatelessWidget {
  final int current;
  const StepDots({super.key, required this.current});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: i == current ? 8 : 6, height: i == current ? 8 : 6, decoration: BoxDecoration(color: i == current ? primary : const Color(0xFFD8DCE7), shape: BoxShape.circle))));
}

class RoleCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Color accent; final VoidCallback onTap;
  const RoleCard({super.key, required this.icon, required this.title, required this.subtitle, required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: accent.withOpacity(.45), borderRadius: BorderRadius.circular(14), border: Border.all(color: border)), child: Row(children: [Container(width: 62, height: 74, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 38, color: primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 12))])), const CircleAvatar(radius: 14, backgroundColor: primary, child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white))])));
}

class ProfileOption extends StatelessWidget {
  final IconData icon; final String title;
  const ProfileOption({super.key, required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)), child: Row(children: [CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF1EEFF), child: Icon(icon, color: primary, size: 19)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))), const Icon(Icons.chevron_right, color: textMuted)]));
}

class Field extends StatelessWidget {
  final TextEditingController controller; final String label; final String? hint; final bool obscure; final TextInputType? keyboard; final int maxLines; final List<TextInputFormatter>? formatters;
  const Field({super.key, required this.controller, required this.label, this.hint, this.obscure = false, this.keyboard, this.maxLines = 1, this.formatters});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 11), child: TextField(controller: controller, obscureText: obscure, keyboardType: keyboard, maxLines: obscure ? 1 : maxLines, inputFormatters: formatters, decoration: InputDecoration(labelText: label, hintText: hint)));
}

class SelectField extends StatelessWidget {
  final String label, value; final List<String> options; final ValueChanged<String> onChanged;
  const SelectField({super.key, required this.label, required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 11), child: DropdownButtonFormField<String>(value: value, decoration: InputDecoration(labelText: label), items: [DropdownMenuItem(value: 'Selecciona', child: Text('Selecciona', style: TextStyle(color: textMuted))), ...options.map((x) => DropdownMenuItem(value: x, child: Text(x)))], onChanged: (v) { if (v != null) onChanged(v); }));
}

class PrimaryButton extends StatelessWidget {
  final String text; final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 48, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: onPressed, child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))));
}

class OutlineButton extends StatelessWidget {
  final String text; final VoidCallback onPressed;
  const OutlineButton({super.key, required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 46, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: primary, side: const BorderSide(color: primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: onPressed, child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))));
}

class SearchField extends StatelessWidget {
  final String hint;
  const SearchField({super.key, required this.hint});
  @override
  Widget build(BuildContext context) => TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune)), hintText: hint));
}

class MatchCard extends StatelessWidget {
  const MatchCard({super.key});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: border)), child: Row(children: [SizedBox(width: 58, height: 58, child: Stack(fit: StackFit.expand, children: [CircularProgressIndicator(value: .8, strokeWidth: 6, color: primary, backgroundColor: const Color(0xFFEAEAF5)), const Center(child: Text('80%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)))])), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tu perfil', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Completa tu perfil para mejorar tu matching.', style: TextStyle(fontSize: 12, color: textMuted)), SizedBox(height: 4), Text('Ver perfil →', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12))]))]));
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)));
}

class JobCard extends StatelessWidget {
  final String title, company, location, modality, match;
  const JobCard({super.key, required this.title, required this.company, required this.location, required this.modality, required this.match});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 9), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: border)), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFEDE9FE), child: Text(company.substring(0, 1), style: const TextStyle(color: primary, fontWeight: FontWeight.w800))), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), subtitle: Text('$company\n$location · $modality\n$match', style: const TextStyle(fontSize: 11, height: 1.35)), trailing: const Icon(Icons.favorite_border, size: 20)));
}

class StatCard extends StatelessWidget {
  final String number, label;
  const StatCard({super.key, required this.number, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(number, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: primary)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: textMuted))]));
}

class ApplicantRow extends StatelessWidget {
  final String name, role, match;
  const ApplicantRow({super.key, required this.name, required this.role, required this.match});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))), child: Row(children: [const CircleAvatar(radius: 20, child: Icon(Icons.person)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text(role, style: const TextStyle(fontSize: 11, color: textMuted))])), Text(match, style: const TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 12)), const Icon(Icons.chevron_right, size: 18)]));
}

class InfoCard extends StatelessWidget {
  final String title, subtitle;
  const InfoCard({super.key, required this.title, required this.subtitle});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: textMuted))]));
}

bool _validEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
bool _validPassword(String v) => v.length >= 8 && RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v) && RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[^A-Za-z0-9]').hasMatch(v);
String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '').trim().isEmpty ? 'No se pudo completar la operación. Inténtalo nuevamente.' : e.toString().replaceFirst('Exception: ', '').trim();
void _push(BuildContext c, Widget page) => Navigator.push(c, MaterialPageRoute(builder: (_) => page));
void _error(String message) => messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
void _success(String message) => messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
