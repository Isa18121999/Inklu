import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const InkluApp());
}

class InkluApp extends StatelessWidget {
  const InkluApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INKLU',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B3CC4),
      ),
      home: const WelcomePage(),
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
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diversity_3, size: 92, color: Color(0xFF5B3CC4)),
                const SizedBox(height: 18),
                const Text(
                  'INKLU',
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Talento, inclusión y oportunidades laborales',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RolePage()),
                      );
                    },
                    child: const Text('Empezar'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text('Iniciar sesión'),
                  ),
                ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona tu rol')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _roleCard(
              context,
              'Soy candidato',
              Icons.person_outline,
              const CandidateRegisterPage(),
            ),
            const SizedBox(height: 16),
            _roleCard(
              context,
              'Soy empresa',
              Icons.business_outlined,
              const CompanyRegisterPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: Icon(icon, size: 34),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}

class CandidateRegisterPage extends StatefulWidget {
  const CandidateRegisterPage({super.key});

  @override
  State<CandidateRegisterPage> createState() => _CandidateRegisterPageState();
}

class _CandidateRegisterPageState extends State<CandidateRegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final conadisController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    conadisController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final conadis = conadisController.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 8) {
      _showMessage('Completa los campos obligatorios.');
      return;
    }

    if (!RegExp(r'^[A-Za-z0-9-]{5,30}$').hasMatch(conadis)) {
      _showMessage('Ingresa un número de CONADIS válido.');
      return;
    }

    setState(() => loading = true);

    try {
      await ApiService().registerCandidate(
        name: name,
        email: email,
        phone: phone,
        password: password,
        conadisNumber: conadis,
      );
      if (!mounted) return;
      _showMessage('Cuenta creada correctamente.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro candidato')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('1 de 3', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _field('Nombre completo *', nameController),
          _field('Correo electrónico *', emailController, type: TextInputType.emailAddress),
          _field('Teléfono', phoneController, type: TextInputType.phone),
          _field('Contraseña *', passwordController, obscure: true),
          _field('Número de CONADIS *', conadisController),
          const Text('El número de CONADIS es obligatorio.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading ? null : submit,
            child: Text(loading ? 'Registrando...' : 'Crear cuenta'),
          ),
        ],
      ),
    );
  }
}

class CompanyRegisterPage extends StatefulWidget {
  const CompanyRegisterPage({super.key});

  @override
  State<CompanyRegisterPage> createState() => _CompanyRegisterPageState();
}

class _CompanyRegisterPageState extends State<CompanyRegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final rucController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    rucController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        rucController.text.trim().isEmpty ||
        passwordController.text.length < 8) {
      _showMessage('Completa los campos obligatorios.');
      return;
    }

    setState(() => loading = true);
    try {
      await ApiService().registerCompany(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        ruc: rucController.text.trim(),
      );
      if (!mounted) return;
      _showMessage('Empresa registrada correctamente.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro empresa')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('1 de 3', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _field('Nombre de empresa *', nameController),
          _field('Correo electrónico *', emailController, type: TextInputType.emailAddress),
          _field('Teléfono', phoneController, type: TextInputType.phone),
          _field('RUC *', rucController, type: TextInputType.number),
          _field('Contraseña *', passwordController, obscure: true),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading ? null : submit,
            child: Text(loading ? 'Registrando...' : 'Crear cuenta'),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showMessage('Ingresa correo y contraseña.');
      return;
    }

    setState(() => loading = true);
    try {
      final response = await ApiService().login(
        emailController.text.trim(),
        passwordController.text,
      );
      if (!mounted) return;
      final user = response['user'];
      final role = user is Map ? user['role'] : null;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'company'
              ? const CompanyHomePage()
              : const CandidateHomePage(),
        ),
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _field('Correo electrónico', emailController, type: TextInputType.emailAddress),
          _field('Contraseña', passwordController, obscure: true),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : submit,
            child: Text(loading ? 'Ingresando...' : 'Ingresar'),
          ),
        ],
      ),
    );
  }
}

class CandidateHomePage extends StatelessWidget {
  const CandidateHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomePage(
      title: 'Hola, candidato 👋',
      children: const [
        Text('Encuentra oportunidades que se ajusten a tu perfil.'),
        SizedBox(height: 18),
        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar empleos',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 18),
        Card(
          child: ListTile(
            title: Text('Completa tu perfil'),
            subtitle: Text('Mejora tus coincidencias con empresas.'),
          ),
        ),
        SizedBox(height: 12),
        Text('Empleos recomendados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Card(child: ListTile(title: Text('Analista de datos'), subtitle: Text('Remoto · Tiempo completo'))),
        Card(child: ListTile(title: Text('Desarrollador Flutter'), subtitle: Text('Híbrido · Lima'))),
      ],
    );
  }
}

class CompanyHomePage extends StatelessWidget {
  const CompanyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomePage(
      title: 'Hola, empresa 👋',
      children: [
        const Text('Gestiona tus oportunidades y candidatos.'),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(child: Card(child: ListTile(title: Text('3'), subtitle: Text('Ofertas')))),
            SizedBox(width: 10),
            Expanded(child: Card(child: ListTile(title: Text('12'), subtitle: Text('Postulaciones')))),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateJobPage()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Crear oferta'),
        ),
      ],
    );
  }
}

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear oferta')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _field('Título de puesto', titleController),
          _field('Descripción', descriptionController, maxLines: 5),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Publicar oferta'),
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _HomePage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('INKLU')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
      bottomNavigationBar: const NavigationBar(
        selectedIndex: 0,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Empleos'),
          NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Avisos'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

Widget _field(
  String label,
  TextEditingController controller, {
  TextInputType? type,
  bool obscure = false,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}
