import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

const _purple = Color(0xFF5B3CC4);
const _logoUrl = 'https://raw.githubusercontent.com/Isa18121999/Inklu/main/assets/logo.png';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INKLU',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: _purple, brightness: Brightness.light),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _purple, width: 2)),
        ),
      ),
      home: const WelcomePage(),
    );
  }
}

class InkluLogo extends StatelessWidget {
  final double size;
  const InkluLogo({super.key, this.size = 190});
  @override
  Widget build(BuildContext context) {
    return Image.network(
      _logoUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined, size: size * .45, color: Colors.black54),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const InkluLogo(size: 210),
                const SizedBox(height: 18),
                const Text('INKLU', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Talento, inclusión y oportunidades laborales', textAlign: TextAlign.center),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolePage())), child: const Text('Empezar'))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())), child: const Text('Iniciar sesión'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RolePage extends StatelessWidget {
  const RolePage({super.key});
  @override
  Widget build(BuildContext context) => PageShell(
    title: '¿Cómo quieres ingresar?',
    children: [
      RoleCard(title: 'Soy candidato', icon: Icons.person_outline, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CandidateRegisterPage()))),
      const SizedBox(height: 16),
      RoleCard(title: 'Soy empresa', icon: Icons.business_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyRegisterPage()))),
    ],
  );
}

bool _validPassword(String value) => value.length >= 8 &&
    RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value) &&
    RegExp(r'[0-9]').hasMatch(value) && RegExp(r'[^A-Za-z0-9]').hasMatch(value);

class CandidateRegisterPage extends StatefulWidget {
  const CandidateRegisterPage({super.key});
  @override
  State<CandidateRegisterPage> createState() => _CandidateRegisterPageState();
}

class _CandidateRegisterPageState extends State<CandidateRegisterPage> {
  final name = TextEditingController(), email = TextEditingController(), phone = TextEditingController(), conadis = TextEditingController(), password = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    final p = password.text;
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || conadis.text.isEmpty || phone.text.isEmpty || p.isEmpty) {
      _message('Completa todos los campos obligatorios.'); return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      _message('Ingresa un correo electrónico válido.'); return;
    }
    if (!RegExp(r'^\d{9}$').hasMatch(phone.text)) { _message('El teléfono debe tener 9 números.'); return; }
    if (!RegExp(r'^\d{8}$').hasMatch(conadis.text)) { _message('El número de CONADIS debe tener 8 números.'); return; }
    if (!_validPassword(p)) { _message('La contraseña debe tener mínimo 8 caracteres, mayúscula, minúscula, número y símbolo.'); return; }
    setState(() => loading = true);
    try {
      await ApiService().registerCandidate(name: name.text.trim(), email: email.text.trim(), phone: phone.text, password: p, conadisNumber: conadis.text);
      if (!mounted) return;
      _message('Registro exitoso. Ahora puedes iniciar sesión.');
      Navigator.pop(context);
    } catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => PageShell(
    title: 'Registro candidato',
    children: [
      const Text('Completa tus datos para crear tu cuenta.'), const SizedBox(height: 16),
      AppField(controller: name, label: 'Nombre completo *'),
      AppField(controller: email, label: 'Correo electrónico *', keyboardType: TextInputType.emailAddress),
      AppField(controller: phone, label: 'Teléfono *', keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]),
      AppField(controller: conadis, label: 'Número de CONADIS *', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)]),
      AppField(controller: password, label: 'Contraseña *', obscureText: true),
      const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Mínimo 8 caracteres: mayúscula, minúscula, número y símbolo.', style: TextStyle(fontSize: 12))),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : register, child: Text(loading ? 'Registrando...' : 'Crear cuenta'))),
    ],
  );
}

class CompanyRegisterPage extends StatefulWidget {
  const CompanyRegisterPage({super.key});
  @override
  State<CompanyRegisterPage> createState() => _CompanyRegisterPageState();
}

class _CompanyRegisterPageState extends State<CompanyRegisterPage> {
  final name = TextEditingController(), email = TextEditingController(), phone = TextEditingController(), ruc = TextEditingController(), password = TextEditingController();
  bool loading = false;
  Future<void> register() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || phone.text.isEmpty || ruc.text.isEmpty || password.text.isEmpty) { _message('Completa todos los campos obligatorios.'); return; }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) { _message('Ingresa un correo corporativo válido.'); return; }
    if (!RegExp(r'^\d{9}$').hasMatch(phone.text)) { _message('El teléfono debe tener 9 números.'); return; }
    if (!RegExp(r'^\d{11}$').hasMatch(ruc.text)) { _message('El RUC debe tener 11 números.'); return; }
    if (!_validPassword(password.text)) { _message('La contraseña debe tener mínimo 8 caracteres, mayúscula, minúscula, número y símbolo.'); return; }
    setState(() => loading = true);
    try {
      await ApiService().registerCompany(name: name.text.trim(), email: email.text.trim(), phone: phone.text, password: password.text, ruc: ruc.text);
      if (!mounted) return; _message('Empresa registrada correctamente.'); Navigator.pop(context);
    } catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => PageShell(title: 'Registro empresa', children: [
    AppField(controller: name, label: 'Razón social *'),
    AppField(controller: email, label: 'Correo corporativo *', keyboardType: TextInputType.emailAddress),
    AppField(controller: phone, label: 'Teléfono *', keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]),
    AppField(controller: ruc, label: 'RUC *', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]),
    AppField(controller: password, label: 'Contraseña *', obscureText: true),
    const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Mínimo 8 caracteres: mayúscula, minúscula, número y símbolo.', style: TextStyle(fontSize: 12))),
    SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : register, child: Text(loading ? 'Registrando...' : 'Crear empresa'))),
  ]);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController(); bool loading = false;
  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) { _message('Ingresa correo y contraseña.'); return; }
    setState(() => loading = true);
    try {
      final result = await ApiService().login(email.text.trim(), password.text);
      if (!mounted) return;
      final role = result['user']?['role']?.toString() ?? 'candidate';
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => role == 'company' ? const CompanyHomePage() : const CandidateHomePage()));
    } catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => PageShell(title: 'Iniciar sesión', children: [
    AppField(controller: email, label: 'Correo electrónico', keyboardType: TextInputType.emailAddress),
    AppField(controller: password, label: 'Contraseña', obscureText: true),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'Ingresando...' : 'Ingresar'))),
  ]);
}

class CandidateHomePage extends StatelessWidget {
  const CandidateHomePage({super.key});
  @override
  Widget build(BuildContext context) => PageShell(showBottomNav: true, title: 'Hola, candidato', children: [
    const Text('Encuentra oportunidades que se ajusten a tu perfil.'), const SizedBox(height: 16),
    AppField(controller: TextEditingController(), label: 'Buscar empleo'), const SizedBox(height: 16),
    const InfoCard(title: 'Completa tu perfil', subtitle: 'Agrega estudios, experiencia y habilidades para mejorar tu match.'), const SizedBox(height: 16),
    const Text('Empleos recomendados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
    const JobCard(title: 'Analista de datos', company: 'Empresa inclusiva', modality: 'Remoto'),
    const JobCard(title: 'Asistente administrativo', company: 'Empresa Perú', modality: 'Híbrido'),
  ]);
}

class CompanyHomePage extends StatelessWidget {
  const CompanyHomePage({super.key});
  @override
  Widget build(BuildContext context) => PageShell(showBottomNav: true, title: 'Dashboard empresa', children: [
    const Text('Gestiona tus oportunidades y encuentra talento.'), const SizedBox(height: 16),
    const Row(children: [Expanded(child: InfoCard(title: 'Ofertas', subtitle: '0')), SizedBox(width: 10), Expanded(child: InfoCard(title: 'Postulaciones', subtitle: '0'))]),
    const SizedBox(height: 16),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateJobPage())), icon: const Icon(Icons.add), label: const Text('Crear oferta'))),
    const SizedBox(height: 18), const Text('Ofertas recientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
    const InfoCard(title: 'Aún no tienes ofertas', subtitle: 'Crea tu primera oferta laboral inclusiva.'),
  ]);
}

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});
  @override State<CreateJobPage> createState() => _CreateJobPageState();
}
class _CreateJobPageState extends State<CreateJobPage> {
  final title = TextEditingController(), description = TextEditingController(), skills = TextEditingController(), location = TextEditingController();
  String modality = 'Remoto'; bool loading = false;
  Future<void> create() async {
    if (title.text.trim().isEmpty || description.text.trim().isEmpty) { _message('Completa título y descripción.'); return; }
    setState(() => loading = true);
    try { _message('Oferta preparada. Inicia sesión como empresa para publicarla.'); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => PageShell(showBottomNav: true, title: 'Crear oferta', children: [
    AppField(controller: title, label: 'Título *'), AppField(controller: description, label: 'Descripción *', maxLines: 5), AppField(controller: skills, label: 'Habilidades requeridas'), AppField(controller: location, label: 'Ubicación'),
    DropdownButtonFormField<String>(initialValue: modality, decoration: const InputDecoration(labelText: 'Modalidad'), items: const [DropdownMenuItem(value: 'Remoto', child: Text('Remoto')), DropdownMenuItem(value: 'Híbrido', child: Text('Híbrido')), DropdownMenuItem(value: 'Presencial', child: Text('Presencial'))], onChanged: (v) => setState(() => modality = v ?? modality)),
    const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : create, child: const Text('Publicar oferta'))),
  ]);
}

class PageShell extends StatelessWidget {
  final String title; final List<Widget> children; final bool showBottomNav;
  const PageShell({super.key, required this.title, required this.children, this.showBottomNav = false});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('INKLU')),
    body: ListView(padding: const EdgeInsets.all(20), children: [Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), const SizedBox(height: 18), ...children]),
    bottomNavigationBar: showBottomNav ? NavigationBar(selectedIndex: 0, destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.work_outline), label: 'Empleos'),
      NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Avisos'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
    ]) : null,
  );
}

class RoleCard extends StatelessWidget {
  final String title; final IconData icon; final VoidCallback onTap;
  const RoleCard({super.key, required this.title, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(22), child: Row(children: [Icon(icon, size: 34), const SizedBox(width: 16), Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))), const Icon(Icons.arrow_forward_ios, size: 18)]))));
}

class InfoCard extends StatelessWidget {
  final String title, subtitle;
  const InfoCard({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(subtitle)])));
}

class JobCard extends StatelessWidget {
  final String title, company, modality;
  const JobCard({super.key, required this.title, required this.company, required this.modality});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('$company · $modality'), trailing: const Icon(Icons.chevron_right)));
}

class AppField extends StatelessWidget {
  final TextEditingController controller; final String label; final bool obscureText; final TextInputType? keyboardType; final int maxLines; final List<TextInputFormatter>? inputFormatters;
  const AppField({super.key, required this.controller, required this.label, this.obscureText = false, this.keyboardType, this.maxLines = 1, this.inputFormatters});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: controller, obscureText: obscureText, keyboardType: keyboardType, maxLines: obscureText ? 1 : maxLines, inputFormatters: inputFormatters, decoration: InputDecoration(labelText: label)));
}
