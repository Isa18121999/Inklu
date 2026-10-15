import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

const primary=Color(0xFF4F46E5), ink=Color(0xFF111827), muted=Color(0xFF64748B), line=Color(0xFFE2E8F0);
final api=ApiService(); String? sessionToken; Map<String,dynamic>? sessionUser;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final prefs = await SharedPreferences.getInstance();
  accessibilityTextScale.value =
      (prefs.getDouble(_accessibilityTextScaleKey) ?? 1.0).clamp(1.0, 1.4).toDouble();
  runApp(const InkluApp());
}
void toast(String s) {
  SemanticsService.announce(s, TextDirection.ltr);
  final context = _nav.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
    );
  }
}
final GlobalKey<NavigatorState> _nav=GlobalKey<NavigatorState>();
final ValueNotifier<double> accessibilityTextScale = ValueNotifier<double>(1.0);
const String _accessibilityTextScaleKey = 'inklu_accessibility_text_scale';

Future<void> showAccessibilitySettings(BuildContext context) async {
  var selectedScale = accessibilityTextScale.value;
  final newScale = await showDialog<double>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Accesibilidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajusta el tamaño del texto para leer mejor la aplicación.'),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tamaño del texto'),
                Text('${(selectedScale * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800, color: primary)),
              ],
            ),
            Slider(
              value: selectedScale,
              min: 1.0,
              max: 1.4,
              divisions: 4,
              label: '${(selectedScale * 100).round()}%',
              onChanged: (value) => setDialogState(() => selectedScale = value),
            ),
            const SizedBox(height: 8),
            Text(
              'Vista previa del texto de INKLU',
              style: TextStyle(fontSize: 16 * selectedScale, height: 1.3, color: ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'El ajuste se guardará en este dispositivo.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 1.0),
            child: const Text('Restablecer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, selectedScale),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  if (newScale == null) return;
  accessibilityTextScale.value = newScale;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_accessibilityTextScaleKey, newScale);
  toast(newScale == 1.0
      ? 'Tamaño de texto estándar aplicado.'
      : 'Tamaño de texto aumentado al ${(newScale * 100).round()}%.');
}
class InkluApp extends StatelessWidget {
  const InkluApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: _nav,
        title: 'INKLU',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: primary),
        ),
        builder: (context, child) => ValueListenableBuilder<double>(
          valueListenable: accessibilityTextScale,
          child: child,
          builder: (context, scale, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(media.textScaler.scale(14.0) / 14.0 * scale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
        home: const AppStart(),
      );
}
const String _rememberKey='inklu_remember_session';
const String _tokenKey='inklu_saved_token';
const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

Future<void> saveLoginSession(bool remember) async {
  final prefs = await SharedPreferences.getInstance();
  if (remember && sessionToken != null && sessionToken!.isNotEmpty) {
    // Keep the preference only for the non-sensitive toggle; the JWT stays
    // in OS-backed secure storage (Android Keystore / iOS Keychain).
    await _secureStorage.write(key: _tokenKey, value: sessionToken);
    await prefs.setBool(_rememberKey, true);
  } else {
    await clearSavedSession();
  }
}

Future<void> clearSavedSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_rememberKey);
  await _secureStorage.delete(key: _tokenKey);
}

Future<void> confirmLogout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Deseas salir de tu cuenta de INKLU?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (shouldLogout != true || !context.mounted) return;
  try {
    await clearSavedSession();
  } catch (_) {}
  sessionToken = null;
  sessionUser = null;
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const Welcome()),
    (_) => false,
  );
}

Future<void> showNotifications(BuildContext context) async {
  final token = sessionToken;
  if (token == null || token.isEmpty) {
    toast('Inicia sesión para consultar tus notificaciones.');
    return;
  }
  try {
    final response = await api.notifications(token);
    if (!context.mounted) return;
    final items = response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Notificaciones'),
          content: SizedBox(
            width: 460,
            height: 360,
            child: items.isEmpty
                ? const Center(child: Text('Todavía no tienes notificaciones.', textAlign: TextAlign.center))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final read = item['read'] == true;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                          color: read ? muted : primary,
                        ),
                        title: Text(
                          item['title']?.toString() ?? 'Notificación',
                          style: TextStyle(fontWeight: read ? FontWeight.w500 : FontWeight.w800),
                        ),
                        subtitle: Text(item['message']?.toString() ?? ''),
                        onTap: read ? null : () async {
                          final id = item['id']?.toString() ?? '';
                          if (id.isEmpty) return;
                          try {
                            await api.markNotificationRead(token, id);
                            setDialogState(() => items[index]['read'] = true);
                          } catch (error) {
                            toast(error.toString().replaceFirst('Exception: ', ''));
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  } catch (error) {
    toast(error.toString().replaceFirst('Exception: ', ''));
  }
}

Future<void> deleteAccountFlow(BuildContext context, String token) async {
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar mi cuenta'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción es permanente. Se eliminará tu cuenta y los datos asociados de INKLU, incluidas las postulaciones y conversaciones relacionadas.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
                validator: (value) => (value ?? '').isEmpty ? 'Ingresa tu contraseña.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmation,
                decoration: const InputDecoration(labelText: 'Escribe ELIMINAR para confirmar'),
                validator: (value) => value?.trim() == 'ELIMINAR' ? null : 'Escribe ELIMINAR exactamente.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(dialogContext, true);
            }
          },
          child: const Text('Eliminar cuenta'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    password.dispose();
    confirmation.dispose();
    return;
  }

  try {
    final response = await api.deleteAccount(token, password.text);
    await clearSavedSession();
    sessionToken = null;
    sessionUser = null;
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Welcome()),
      (_) => false,
    );
    toast(response['message']?.toString() ?? 'Tu cuenta fue eliminada.');
  } catch (error) {
    toast(error.toString().replaceFirst('Exception: ', ''));
  } finally {
    password.dispose();
    confirmation.dispose();
  }
}

class DeleteAccountButton extends StatelessWidget {
  final String token;
  const DeleteAccountButton({super.key, required this.token});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => deleteAccountFlow(context, token),
      icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
      label: const Text('Eliminar mi cuenta', style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFF2B8B5)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    ),
  );
}

class AppStart extends StatefulWidget {
  const AppStart({super.key});
  @override
  State<AppStart> createState() => _AppStartState();
}

class _AppStartState extends State<AppStart> {
  bool loading = true;
  bool restored = false;

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_rememberKey) == true) {
        final token = await _secureStorage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty) {
          // Ask the API to validate the token. Expired sessions are not restored.
          final currentUser = await api.profile(token);
          sessionToken = token;
          sessionUser = currentUser;
          restored = true;
        }
      }
    } catch (_) {
      restored = false;
      sessionToken = null;
      sessionUser = null;
      try { await clearSavedSession(); } catch (_) {}
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primary)));
    }
    if (restored && sessionToken != null && sessionUser != null) {
      return sessionUser?['role'] == 'company' ? const CompanyHome() : const CandidateHome();
    }
    return const Welcome();
  }
}
class Logo extends StatefulWidget{final double size;const Logo({super.key,this.size=110});@override State<Logo> createState()=>_LogoState();}
class _LogoState extends State<Logo>{Uint8List? b;@override void initState(){super.initState();rootBundle.loadString('assets/logo.b64').then((x){if(mounted)setState(()=>b=base64Decode(x.trim()));});}@override Widget build(BuildContext c)=>b==null?SizedBox(width:widget.size,height:widget.size):Semantics(label:'Logo INKLU',image:true,child:Image.memory(b!,width:widget.size,height:widget.size,fit:BoxFit.contain));}
class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext c) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Logo(size: 150),
                  const Text(
                    'INKLU',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Conectamos talento,\noportunidades e inclusión',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Btn(
                    'Comenzar',
                    () => Navigator.push(
                      c,
                      MaterialPageRoute(builder: (_) => const Roles()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Out(
                    'Ya tengo una cuenta',
                    () => Navigator.push(
                      c,
                      MaterialPageRoute(builder: (_) => const Login()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
                    icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                    label: const Text('Privacidad y uso de datos'),
                    style: TextButton.styleFrom(foregroundColor: primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  Widget section(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(color: Color(0xFF4B5563), height: 1.45)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacidad y datos')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text('Cómo utiliza INKLU tu información', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ink)),
        const SizedBox(height: 10),
        const Text(
          'Esta información está diseñada para explicar de forma sencilla el uso de datos durante el piloto de INKLU.',
          style: TextStyle(color: muted, height: 1.4),
        ),
        const SizedBox(height: 22),
        section('Datos que puedes proporcionar', 'Datos de registro y contacto, información profesional, currículum, habilidades, experiencia, postulaciones, mensajes relacionados con procesos de selección y, para cuentas candidatas, información sobre acreditación de discapacidad cuando corresponda.'),
        section('Para qué se utilizan', 'Para administrar tu cuenta, mostrar ofertas, analizar palabras clave de tu CV, estimar coincidencias profesionales, permitir postulaciones, comunicar cambios de estado y apoyar procesos de contratación inclusivos.'),
        section('Quién puede consultar la información', 'Tu CV y los datos de postulación solo deben estar disponibles para las empresas pertinentes dentro del proceso de selección y para las funciones autorizadas de INKLU. No compartas contraseñas ni enlaces privados de recuperación.'),
        section('Recomendaciones automáticas', 'Las sugerencias de empleo utilizan palabras clave del CV, habilidades, formación, experiencia y datos de las ofertas. Son orientativas: no garantizan una entrevista ni una contratación, y no deben ser la única base de una decisión laboral.'),
        section('Seguridad', 'INKLU utiliza controles de acceso, autenticación y medidas técnicas para proteger la información. Ningún sistema conectado a Internet puede garantizar una seguridad absoluta.'),
        section('Acceso y eliminación', 'Puedes revisar los datos de tu perfil y solicitar la eliminación de la cuenta desde la aplicación. Al eliminar la cuenta, se eliminan la información del perfil y los registros asociados contemplados por el sistema, incluidas postulaciones y conversaciones relacionadas.'),
        section('Antes de un lanzamiento público', 'Esta pantalla es una explicación inicial para el piloto. Antes de abrir INKLU al público, el responsable del proyecto debe completar su identidad legal, canal de contacto para solicitudes de privacidad, plazos de conservación y los demás términos que correspondan, y revisar el texto con asesoría legal.'),
        const SizedBox(height: 8),
        Out('Volver', () => Navigator.pop(context)),
      ],
    ),
  );
}

class Roles extends StatelessWidget{const Roles({super.key});@override Widget build(BuildContext c)=>Shell(title:'¿Cómo quieres registrarte?',sub:'Selecciona el tipo de cuenta que deseas crear.',child:Column(children:[CardRole('Soy candidato','Busco oportunidades laborales inclusivas.',Icons.person,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CandidateRegister()))),const SizedBox(height:14),CardRole('Soy empresa','Quiero publicar ofertas y encontrar talento.',Icons.business,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CompanyRegister())))]));}
class CandidateRegister extends StatefulWidget{const CandidateRegister({super.key});@override State<CandidateRegister> createState()=>_CandidateRegisterState();}
class _CandidateRegisterState extends State<CandidateRegister>{int step=0;final n=TextEditingController(),a=TextEditingController(),e=TextEditingController(),p=TextEditingController(),birth=TextEditingController(),phone=TextEditingController(),address=TextEditingController(text:'Lima, Perú'),conadis=TextEditingController();String? cvPath,cvName;bool terms=false,busy=false;DateTime? bd;
Future<void> cv()async{final r=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['pdf','doc','docx'],withData:false);if(r!=null&&r.files.single.path!=null)setState((){cvPath=r.files.single.path;cvName=r.files.single.name;});}
Future<void> date()async{final d=await showDatePicker(context:context,initialDate:DateTime(2000),firstDate:DateTime(1900),lastDate:DateTime.now(),cancelText:'Cancelar',confirmText:'Aceptar');if(d!=null){bd=d;birth.text='${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';setState((){});}}
Future<void> next()async{if(step==0&&(!validEmail(e.text)||!validPass(p.text)||n.text.trim().isEmpty||a.text.trim().isEmpty||!terms)){toast('Completa los datos y acepta los términos.');return;}if(step==1&&(bd==null||!RegExp(r'^\d{9}$').hasMatch(phone.text)||conadis.text.trim().isEmpty)){toast('Completa fecha, teléfono y CONADIS.');return;}if(step==2&&(cvPath==null)){toast('Selecciona tu CV.');return;}if(step<2){setState(()=>step++);return;}setState(()=>busy=true);try{final r=await api.registerCandidate(name:'${n.text.trim()} ${a.text.trim()}',email:e.text.trim(),phone:phone.text,password:p.text,conadisNumber:conadis.text.trim(),cvPath:cvPath);sessionToken=r['token'];sessionUser=r['user'];await api.updateProfile(sessionToken!,{'birth':birth.text,'address':address.text});if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const CandidateHome()),(_)=>false);}catch(x){toast(x.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>busy=false);}}
  @override
  Widget build(BuildContext c) => Shell(
        title: [
          'Crear cuenta como candidato',
          'Información personal',
          'Perfil profesional',
        ][step],
        sub: step == 2
            ? 'Sube tu CV para completar tu perfil profesional.'
            : 'Completa tus datos para comenzar.',
        child: Column(
          children: [
            Dots(step),
            const SizedBox(height: 18),
            if (step == 0) ...[
              F(n, 'Nombres'),
              F(a, 'Apellidos'),
              F(e, 'Correo electrónico', type: TextInputType.emailAddress),
              F(p, 'Contraseña', obscure: true),
              const Text(
                'Mínimo 8: mayúscula, minúscula, número y símbolo.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              CheckboxListTile(
                value: terms,
                onChanged: (v) => setState(() => terms = v ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Acepto los términos y condiciones',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ] else if (step == 1) ...[
              F(
                birth,
                'Fecha de nacimiento',
                read: true,
                onTap: date,
                suffix: const Icon(Icons.calendar_today_outlined),
              ),
              F(phone, 'Teléfono',
                  type: TextInputType.phone, format: digits(9)),
              F(address, 'Dirección'),
              F(e, 'Correo electrónico', type: TextInputType.emailAddress),
              F(conadis, 'Número de CONADIS',
                  type: TextInputType.number, format: digits(20)),
            ] else ...[
              Semantics(
                button: true,
                label: cvName == null
                    ? 'Seleccionar CV. Archivos PDF, DOC o DOCX.'
                    : 'CV seleccionado: $cvName. Toca para cambiarlo.',
                child: InkWell(
                  onTap: cv,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: cvName == null ? line : primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined,
                            color: primary, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cvName ?? 'Seleccionar archivo',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.upload_file, color: primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Solo PDF, DOC o DOCX. Máximo 5 MB.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ],
            const SizedBox(height: 18),
            Btn(
              busy ? 'Guardando...' : step == 2 ? 'Finalizar' : 'Siguiente',
              busy ? null : next,
            ),
          ],
        ),
      );
}
class CompanyRegister extends StatefulWidget{const CompanyRegister({super.key});@override State<CompanyRegister> createState()=>_CompanyRegisterState();}
class _CompanyRegisterState extends State<CompanyRegister> {
  int step = 0;
  final company = TextEditingController();
  final ruc = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final size = TextEditingController();
  final address = TextEditingController(text: 'Lima, Perú');
  final web = TextEditingController();
  final desc = TextEditingController();
  String? sector;
  bool terms = false, busy = false;
  final sectors = [
    'Tecnología', 'Educación', 'Salud', 'Finanzas', 'Comercio',
    'Manufactura', 'Servicios', 'Construcción', 'Transporte', 'Turismo', 'Otro'
  ];

  Future<void> next() async {
    if (step == 0 &&
        (!validEmail(email.text) ||
            !validPass(pass.text) ||
            company.text.trim().isEmpty ||
            !RegExp(r'^\d{11}$').hasMatch(ruc.text) ||
            !terms)) {
      toast('Verifica empresa, RUC, correo y términos.');
      return;
    }
    if (step == 0) {
      setState(() => step = 1);
      return;
    }
    if (sector == null ||
        size.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        web.text.trim().isEmpty ||
        desc.text.trim().isEmpty) {
      toast('Completa todos los datos de la empresa.');
      return;
    }
    setState(() => busy = true);
    try {
      final r = await api.registerCompany(
        name: company.text.trim(),
        email: email.text.trim(),
        phone: '',
        password: pass.text,
        ruc: ruc.text,
        sector: sector!,
        size: size.text.trim(),
        address: address.text.trim(),
        website: web.text.trim(),
        description: desc.text.trim(),
      );
      sessionToken = r['token'];
      sessionUser = r['user'];
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CompanyHome()),
          (_) => false,
        );
      }
    } catch (x) {
      toast(x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Shell(
        title: step == 0
            ? 'Crear cuenta como empresa'
            : 'Información de la empresa',
        sub: 'Completa los datos de tu organización.',
        child: Column(
          children: [
            Dots(step),
            const SizedBox(height: 18),
            if (step == 0) ...[
              F(company, 'Nombre de la empresa'),
              F(ruc, 'RUC',
                  type: TextInputType.number, format: digits(11)),
              F(email, 'Correo institucional',
                  type: TextInputType.emailAddress),
              F(pass, 'Contraseña', obscure: true),
              CheckboxListTile(
                value: terms,
                onChanged: (v) => setState(() => terms = v ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Acepto los términos y condiciones',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                initialValue: sector,
                decoration: const InputDecoration(labelText: 'Sector'),
                items: sectors
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (v) => setState(() => sector = v),
              ),
              const SizedBox(height: 11),
              F(size, 'Tamaño de la empresa'),
              F(address, 'Dirección'),
              F(web, 'Sitio web'),
              F(desc, 'Descripción de la empresa', max: 4),
            ],
            const SizedBox(height: 18),
            Btn(busy ? 'Guardando...' : 'Finalizar', busy ? null : next),
          ],
        ),
      );
}
class Login extends StatefulWidget{const Login({super.key});@override State<Login> createState()=>_LoginState();}
class _LoginState extends State<Login> {
  final e = TextEditingController();
  final p = TextEditingController();
  bool busy = false;
  bool rememberSession = false;

  Future<void> go() async {
    if (!validEmail(e.text) || p.text.isEmpty) {
      toast('Ingresa correo y contraseña.');
      return;
    }
    setState(() => busy = true);
    try {
      final r = await api.login(e.text.trim(), p.text);
      sessionToken = r['token'];
      sessionUser = r['user'];
      await saveLoginSession(rememberSession);
      final company = sessionUser?['role'] == 'company';
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                company ? const CompanyHome() : const CandidateHome(),
          ),
          (_) => false,
        );
      }
    } catch (x) {
      toast(x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> forgotPassword() async {
    final emailController = TextEditingController(text: e.text.trim());
    final formKey = GlobalKey<FormState>();
    bool sending = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: !busy,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('¿Olvidaste tu contraseña?'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Escribe el correo asociado a tu cuenta de INKLU. Te enviaremos un enlace para crear una nueva contraseña.',
                  style: TextStyle(color: muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (value) => validEmail(value ?? '') ? null : 'Introduce un correo válido.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: sending ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: sending ? null : () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                setDialogState(() => sending = true);
                try {
                  final response = await api.requestPasswordReset(emailController.text);
                  if (!mounted || !dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (messageContext) => AlertDialog(
                      title: const Text('Revisa tu correo'),
                      content: Text(response['message']?.toString() ?? 'Si la cuenta existe y la recuperación está habilitada, recibirás instrucciones por correo.'),
                      actions: [FilledButton(onPressed: () => Navigator.pop(messageContext), child: const Text('Entendido'))],
                    ),
                  );
                } catch (error) {
                  if (!dialogContext.mounted) return;
                  toast(error.toString().replaceFirst('Exception: ', ''));
                  setDialogState(() => sending = false);
                }
              },
              child: sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar enlace'),
            ),
          ],
        ),
      ),
    );
    emailController.dispose();
  }

  @override
  Widget build(BuildContext c) => Shell(
        title: 'Iniciar sesión',
        sub: 'Bienvenido de nuevo a INKLU.',
        child: Column(
          children: [
            F(e, 'Correo electrónico', type: TextInputType.emailAddress),
            F(p, 'Contraseña', obscure: true),
            CheckboxListTile(
              value: rememberSession,
              onChanged: busy ? null : (value) => setState(() => rememberSession = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: const Text('Mantener sesión iniciada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Guarda tu acceso en este dispositivo.', style: TextStyle(fontSize: 11, color: muted)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: busy ? null : forgotPassword,
                icon: const Icon(Icons.lock_reset_rounded, size: 18),
                label: const Text('¿Olvidaste tu contraseña?'),
                style: TextButton.styleFrom(foregroundColor: primary),
              ),
            ),
            const SizedBox(height: 4),
            Btn(busy ? 'Ingresando...' : 'Iniciar sesión', busy ? null : go),
          ],
        ),
      );
}
class CandidateHome extends StatefulWidget{const CandidateHome({super.key});@override State<CandidateHome> createState()=>_CandidateHomeState();}
class _CandidateHomeState extends State<CandidateHome> {
  int tab = 0;
  List<dynamic> jobs = [];
  List<dynamic> apps = [];
  List<dynamic> recommendations = [];
  List<dynamic> savedJobs = [];
  Set<String> savedJobIds = <String>{};
  bool showSavedOnly = false;
  List<dynamic> cvSkills = [];
  bool scanningRecommendations = false;
  String? recommendationMessage;
  String selectedApplicationFilter = 'Todas';
  final TextEditingController jobSearchController = TextEditingController();
  String? selectedLocationFilter;
  String? selectedModalityFilter;
  String? selectedContractFilter;
  String? selectedCategoryFilter;
  bool onlyWithAccessibility = false;
  bool searchingJobs = false;
  bool filtersExpanded = false;
  static const applicationFilters = ['Todas', 'Postulado', 'CV Visto', 'En proceso', 'Aceptado', 'Proceso terminado'];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final results = await Future.wait([api.jobs(sessionToken!), api.applications(sessionToken!)]);
      List<dynamic> currentSaved = [];
      try { currentSaved = await api.savedJobs(sessionToken!); } catch (_) {}
      if (!mounted) return;
      setState(() {
        jobs = results[0];
        apps = results[1];
        savedJobs = currentSaved;
        savedJobIds = currentSaved.map((item) => (item['_id'] ?? item['id'] ?? '').toString()).where((id) => id.isNotEmpty).toSet();
      });

      // Intenta personalizar las ofertas automáticamente al abrir Inicio.
      // Si todavía no hay CV, las ofertas siguen disponibles y se muestra una guía.
      try {
        final suggested = await api.recommendations(sessionToken!);
        final relevantJobs = await api.jobs(sessionToken!);
        if (!mounted) return;
        setState(() {
          recommendations = suggested;
          jobs = relevantJobs;
          recommendationMessage = suggested.isEmpty
              ? 'Aún no encontramos ofertas relacionadas. Completa carrera y experiencia, y revisa que tu CV tenga texto seleccionable.'
              : 'Mostramos ofertas según las coincidencias con tu CV, carrera y experiencia.';
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            recommendationMessage = 'Sube un CV y completa carrera y años de experiencia para recibir ofertas personalizadas.';
          });
        }
      }
    } catch (x) {
      if (mounted) toast(x.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _jobId(dynamic job) => (job['_id'] ?? job['id'] ?? '').toString();

  Future<void> toggleSavedJob(dynamic job) async {
    final id = _jobId(job);
    if (id.isEmpty) {
      toast('No se pudo identificar esta oferta.');
      return;
    }
    final isSaved = savedJobIds.contains(id);
    try {
      if (isSaved) {
        await api.unsaveJob(sessionToken!, id);
      } else {
        await api.saveJob(sessionToken!, id);
      }
      final latestSaved = await api.savedJobs(sessionToken!);
      if (!mounted) return;
      setState(() {
        savedJobs = latestSaved;
        savedJobIds = latestSaved.map((item) => _jobId(item)).where((value) => value.isNotEmpty).toSet();
      });
      toast(isSaved ? 'Oferta quitada de Guardadas.' : 'Oferta guardada.');
    } catch (error) {
      toast(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  bool isJobSaved(dynamic job) => savedJobIds.contains(_jobId(job));

  @override
  void dispose() {
    jobSearchController.dispose();
    super.dispose();
  }

  Future<void> searchJobs({bool reset = false}) async {
    if (reset) {
      jobSearchController.clear();
      selectedLocationFilter = null;
      selectedModalityFilter = null;
      selectedContractFilter = null;
      selectedCategoryFilter = null;
      onlyWithAccessibility = false;
    }
    setState(() => searchingJobs = true);
    try {
      final result = await api.searchJobs(
        sessionToken!,
        query: jobSearchController.text.trim(),
        location: selectedLocationFilter,
        modality: selectedModalityFilter,
        contractType: selectedContractFilter,
        category: selectedCategoryFilter,
        withAccessibility: onlyWithAccessibility,
      );
      if (!mounted) return;
      setState(() => jobs = result);
      toast('${result.length} ofertas encontradas.');
    } catch (x) {
      if (mounted) toast(x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => searchingJobs = false);
    }
  }

  Future<void> apply(String id) async {
    try {
      await api.apply(sessionToken!, id);
      toast('Postulación enviada correctamente.');
      await load();
    } catch (x) {
      toast(x.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget buildJobFilters() {
    const locations = ['Lima', 'Callao', 'Arequipa', 'Trujillo', 'Chiclayo', 'Piura', 'Cusco', 'Huancayo', 'Iquitos'];
    const modalities = ['Remoto', 'Híbrido', 'Presencial'];
    const contracts = ['Tiempo completo', 'Medio tiempo', 'Temporal', 'Prácticas', 'Freelance', 'Por horas'];
    const categories = ['Tecnología', 'Administración', 'Diseño', 'Atención al cliente', 'Educación', 'Salud', 'Finanzas', 'Logística', 'Marketing', 'Otro'];

    Widget dropdown({
      required String label,
      required String? value,
      required List<String> values,
      required ValueChanged<String?> onChanged,
      required String allLabel,
      required IconData icon,
    }) => DropdownButtonFormField<String>(
      initialValue: value ?? '',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE5E0FA))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE5E0FA))),
      ),
      items: [
        DropdownMenuItem<String>(value: '', child: Text(allLabel, overflow: TextOverflow.ellipsis)),
        ...values.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (next) => onChanged(next == null || next.isEmpty ? null : next),
    );

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FF),
        border: Border.all(color: const Color(0xFFE5E0FA)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Filtra las ofertas', style: TextStyle(fontWeight: FontWeight.w800, color: ink))),
              TextButton(
                onPressed: searchingJobs ? null : () => searchJobs(reset: true),
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          dropdown(
            label: 'Área profesional',
            value: selectedCategoryFilter,
            values: categories,
            allLabel: 'Todas las áreas',
            icon: Icons.work_outline,
            onChanged: (value) => setState(() => selectedCategoryFilter = value),
          ),
          const SizedBox(height: 10),
          dropdown(
            label: 'Ubicación',
            value: selectedLocationFilter,
            values: locations,
            allLabel: 'Todas las ubicaciones',
            icon: Icons.location_on_outlined,
            onChanged: (value) => setState(() => selectedLocationFilter = value),
          ),
          const SizedBox(height: 10),
          dropdown(
            label: 'Modalidad',
            value: selectedModalityFilter,
            values: modalities,
            allLabel: 'Todas las modalidades',
            icon: Icons.laptop_mac_outlined,
            onChanged: (value) => setState(() => selectedModalityFilter = value),
          ),
          const SizedBox(height: 10),
          dropdown(
            label: 'Tipo de contrato',
            value: selectedContractFilter,
            values: contracts,
            allLabel: 'Todos los contratos',
            icon: Icons.description_outlined,
            onChanged: (value) => setState(() => selectedContractFilter = value),
          ),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: onlyWithAccessibility,
            activeColor: primary,
            title: const Text(
              'Solo ofertas con información de accesibilidad',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text(
              'La empresa ha declarado detalles; confirma los ajustes específicos antes de postular.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            onChanged: (value) => setState(() => onlyWithAccessibility = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: searchingJobs ? null : () => searchJobs(),
              icon: searchingJobs
                  ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search_rounded),
              label: Text(searchingJobs ? 'Buscando...' : 'Aplicar filtros'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> scanCvAndRecommend() async {
    setState(() { scanningRecommendations = true; recommendationMessage = null; });
    try {
      final analysis = await api.analyzeCv(sessionToken!);
      final results = await api.recommendations(sessionToken!);
      // Tras analizar el CV, recarga la pestaña de ofertas para aplicar el filtro
      // profesional del servidor en las búsquedas de este candidato.
      final filteredJobs = await api.jobs(sessionToken!);
      if (!mounted) return;
      setState(() {
        cvSkills = (analysis['skills'] as List?) ?? [];
        jobs = filteredJobs;
        recommendations = results;
        recommendationMessage = results.isEmpty
            ? 'No encontramos coincidencias claras todavía. Completa tus preferencias o revisa todas las ofertas.'
            : 'Encontramos ${results.length} ofertas ordenadas por coincidencia con tu CV.';
      });
      toast(cvSkills.isEmpty
          ? 'CV analizado. No se reconocieron habilidades del catálogo todavía.'
          : 'CV analizado. Habilidades detectadas: ${cvSkills.take(4).join(', ')}.');
    } catch (x) {
      if (mounted) {
        setState(() => recommendationMessage = x.toString().replaceFirst('Exception: ', ''));
        toast(x.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => scanningRecommendations = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final visibleApplications = apps.where((item) {
      if (selectedApplicationFilter == 'Todas') return true;
      return normalizeApplicationStatus(item['status']?.toString()).toLowerCase() == selectedApplicationFilter.toLowerCase();
    }).toList();

    return Dash(
      title: tab == 2 ? 'Mis postulaciones' : 'Hola, ${sessionUser?['name'] ?? 'candidato'}',
      tab: tab,
      onTab: (x) => setState(() => tab = x),
      children: tab == 0
          ? [
              const Text('Encuentra oportunidades laborales inclusivas.', style: TextStyle(color: muted)),
              const SizedBox(height: 16),
              const ProfileCard(),
              const SizedBox(height: 20),
              const Section('Ofertas sugeridas por análisis de CV'),
              const Text('Las sugerencias consideran tu CV, carrera, habilidades y años de experiencia.', style: TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 10),
              Btn(scanningRecommendations ? 'Analizando CV...' : 'Analizar mi CV y sugerir ofertas', scanningRecommendations ? null : scanCvAndRecommend),
              if (cvSkills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Habilidades detectadas: ${cvSkills.join(', ')}', style: const TextStyle(fontSize: 12, color: muted)),
              ],
              if (recommendationMessage != null) ...[
                const SizedBox(height: 8),
                Text(recommendationMessage!, style: const TextStyle(color: muted, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              if (recommendations.isNotEmpty)
                ...recommendations.map((j) => JobRecommendationCard(
                  job: Map<String, dynamic>.from(j),
                  onTap: () => showOffer(c, j, apply),
                  isSaved: isJobSaved(j),
                  onSave: () => toggleSavedJob(j),
                ))
              else ...[
                const Section('Ofertas recientes'),
                if (jobs.isEmpty)
                  const Info('Todavía no hay ofertas', 'Vuelve a revisar pronto.')
                else
                  ...jobs.take(3).map((j) => JobCard(
                    j,
                    onTap: () => showOffer(c, j, apply),
                    isSaved: isJobSaved(j),
                    onSave: () => toggleSavedJob(j),
                  )),
              ],
            ]
          : tab == 1
              ? [
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¡Ahora es el momento de cambiar!',
                          style: TextStyle(
                            fontSize: 21,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF272047),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3)),
                            ],
                          ),
                          child: TextField(
                            controller: jobSearchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => searchJobs(),
                            decoration: InputDecoration(
                              hintText: '¿Qué empleo buscas?',
                              hintStyle: const TextStyle(color: Color(0xFF89839F), fontSize: 15),
                              prefixIcon: const Icon(Icons.search_rounded, color: primary, size: 27),
                              suffixIcon: IconButton(
                                tooltip: 'Buscar empleo',
                                onPressed: searchingJobs ? null : () => searchJobs(),
                                icon: const Icon(Icons.arrow_forward_rounded, color: primary),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: primary, width: 1.5)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => filtersExpanded = !filtersExpanded),
                            icon: const Icon(Icons.tune_rounded, size: 19),
                            label: Text(filtersExpanded ? 'Ocultar filtros' : 'Filtrar ofertas'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD8D0FA)),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (filtersExpanded) ...[
                    const SizedBox(height: 12),
                    buildJobFilters(),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todas las ofertas'),
                        selected: !showSavedOnly,
                        onSelected: (_) => setState(() => showSavedOnly = false),
                      ),
                      ChoiceChip(
                        label: Text('Guardadas (${savedJobs.length})'),
                        selected: showSavedOnly,
                        onSelected: (_) => setState(() => showSavedOnly = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text(showSavedOnly ? 'Ofertas guardadas' : 'Ofertas disponibles', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink))),
                      Text('${(showSavedOnly ? savedJobs : jobs).length} resultado${(showSavedOnly ? savedJobs : jobs).length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (showSavedOnly && savedJobs.isEmpty)
                    const Info('Todavía no guardaste ofertas', 'Toca el icono de marcador en cualquier oferta para guardar una oportunidad y revisarla después.')
                  else if (!showSavedOnly && searchingJobs)
                    const Padding(
                      padding: EdgeInsets.all(25),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if ((showSavedOnly ? savedJobs : jobs).isEmpty)
                    const Info(
                      'No encontramos ofertas con esos filtros',
                      'Prueba otra palabra o limpia alguno de los filtros para ver más oportunidades.',
                    )
                  else
                    ...(showSavedOnly ? savedJobs : jobs).map((job) => JobCard(
                      job,
                      onTap: () => showOffer(c, job, apply),
                      isSaved: isJobSaved(job),
                      onSave: () => toggleSavedJob(job),
                    )),
                ]
              : tab == 2
                  ? [
                      const Text('Sigue cada etapa de selección y conversa con la empresa cuando tu postulación llegue a “En proceso”.', style: TextStyle(color: muted, fontSize: 12)),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 43,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: applicationFilters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = applicationFilters[index];
                            final selected = filter == selectedApplicationFilter;
                            return ChoiceChip(
                              label: Text(filter),
                              selected: selected,
                              showCheckmark: false,
                              onSelected: (_) => setState(() => selectedApplicationFilter = filter),
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : const Color(0xFF433D63),
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 12,
                              ),
                              backgroundColor: const Color(0xFFF0EDFF),
                              selectedColor: primary,
                              side: BorderSide(color: selected ? primary : const Color(0xFFE5E0FA)),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 9),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (visibleApplications.isEmpty)
                        Info(
                          selectedApplicationFilter == 'Todas' ? 'Aún no tienes postulaciones' : 'No hay postulaciones en esta etapa',
                          selectedApplicationFilter == 'Todas'
                              ? 'Cuando postules a una oferta, aparecerá aquí con su seguimiento.'
                              : 'Prueba otro filtro para revisar tus otras postulaciones.',
                        )
                      else
                        ...visibleApplications.map((item) => ApplicationProgressCard(
                          application: Map<String, dynamic>.from(item),
                          token: sessionToken!,
                        )),
                    ]
                  : [CandidateProfilePanel(token: sessionToken!)],
    );
  }
}


String normalizeApplicationStatus(String? raw) {
  switch (raw) {
    case 'Postulada':
      return 'Postulado';
    case 'En revisión':
      return 'CV visto';
    case 'Entrevista':
      return 'En proceso';
    case 'Seleccionada':
      return 'Aceptado';
    case 'No seleccionada':
      return 'Proceso terminado';
    default:
      return raw == null || raw.isEmpty ? 'Postulado' : raw;
  }
}

bool chatAvailableForStatus(String status) =>
    const ['En proceso', 'Aceptado', 'Proceso terminado']
        .contains(normalizeApplicationStatus(status));

class JobRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onSave;

  const JobRecommendationCard({
    super.key,
    required this.job,
    required this.onTap,
    this.isSaved = false,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final score = (job['matchScore'] as num?)?.round().clamp(0, 100) ?? 0;
    final rawReasons = job['matchReasons'];
    final reasons = rawReasons is List
        ? rawReasons.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList()
        : <String>[];
    final company = job['companyId'] is Map
        ? job['companyId']['name']?.toString() ?? 'Empresa'
        : 'Empresa';

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFEAE6FA)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDE9FF),
          child: Icon(Icons.auto_awesome_outlined, color: primary),
        ),
        title: Text(
          job['title']?.toString() ?? 'Oferta laboral',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(company),
              const SizedBox(height: 4),
              Text(
                '$score% de coincidencia orientativa',
                style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (reasons.isNotEmpty)
                Text(
                  reasons.take(2).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              TextButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (sheetContext) {
                    final requiredYears = int.tryParse(
                          (job['experienceRequired'] ?? 0).toString(),
                        ) ??
                        0;
                    final experienceFit = job['experienceFit'] == true;
                    final matchedSkillsRaw = job['matchedSkills'];
                    final matchedSkills = matchedSkillsRaw is List
                        ? matchedSkillsRaw.map((item) => item.toString()).toList()
                        : <String>[];
                    final preferredSkillsRaw = job['matchedPreferredSkills'];
                    final preferredSkills = preferredSkillsRaw is List
                        ? preferredSkillsRaw.map((item) => item.toString()).toList()
                        : <String>[];

                    Widget sectionTitle(String title) => Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 6),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );

                    Widget skillChips(List<String> skills) => Wrap(
                          spacing: 6,
                          runSpacing: 0,
                          children: skills
                              .map((skill) => Chip(
                                    label: Text(skill),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: const Color(0xFFF1EEFF),
                                    side: BorderSide.none,
                                  ))
                              .toList(),
                        );

                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Por qué te recomendamos esta oferta?',
                                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                                      color: ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                job['title']?.toString() ?? 'Oferta laboral',
                                style: const TextStyle(color: muted),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$score% de coincidencia orientativa',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                  Text('$score/100', style: const TextStyle(color: muted)),
                                ],
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: score / 100,
                                  minHeight: 7,
                                  backgroundColor: const Color(0xFFEAE6FA),
                                  color: primary,
                                ),
                              ),
                              sectionTitle('Criterios que contribuyeron'),
                              if (reasons.isEmpty)
                                const Text(
                                  'Aún no hay suficiente detalle para explicar todas las coincidencias. Revisa que tu CV y tu perfil estén actualizados.',
                                  style: TextStyle(color: muted),
                                )
                              else
                                ...reasons.map(
                                  (reason) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 18, color: primary),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(reason)),
                                      ],
                                    ),
                                  ),
                                ),
                              if (matchedSkills.isNotEmpty) ...[
                                sectionTitle('Habilidades de tu perfil que coinciden'),
                                skillChips(matchedSkills),
                              ],
                              if (preferredSkills.isNotEmpty) ...[
                                sectionTitle('Habilidades deseables coincidentes'),
                                skillChips(preferredSkills),
                              ],
                              sectionTitle('Experiencia requerida'),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    requiredYears == 0
                                        ? Icons.info_outline
                                        : experienceFit
                                            ? Icons.check_circle_outline
                                            : Icons.warning_amber_rounded,
                                    color: requiredYears == 0 || experienceFit
                                        ? primary
                                        : Colors.deepOrange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      requiredYears == 0
                                          ? 'La empresa no indicó un mínimo de años de experiencia.'
                                          : experienceFit
                                              ? 'Tu perfil indica experiencia compatible con el requisito de $requiredYears año(s).'
                                              : 'La oferta solicita $requiredYears año(s). Revisa los requisitos antes de postular.',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Este porcentaje es una estimación basada en la información disponible en tu CV, tu perfil y la oferta. No garantiza una entrevista ni una contratación.',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    Navigator.of(sheetContext).pop();
                                    onTap();
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: primary),
                                  child: const Text('Ver oferta completa'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Ver por qué se recomienda'),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSave != null)
              IconButton(
                tooltip: isSaved ? 'Quitar de ofertas guardadas' : 'Guardar oferta',
                onPressed: onSave,
                icon: Icon(isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: primary),
              ),
            const Icon(Icons.chevron_right, color: primary),
          ],
        ),
      ),
    );
  }
}

class ApplicationProgressCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final String token;
  const ApplicationProgressCard({super.key, required this.application, required this.token});

  static const stages = ['Postulado', 'CV visto', 'En proceso', 'Aceptado', 'Proceso terminado'];
  static const descriptions = [
    'La empresa recibió tu candidatura. Todavía no ha marcado el CV como visto.',
    'La empresa indicó que ha revisado tu currículum.',
    'La selección continúa. Ya puedes conversar con la empresa a través del chat privado.',
    'La empresa marcó tu candidatura como aceptada.',
    'La empresa ha finalizado el proceso de selección para esta postulación.',
  ];

  int stageIndex(String status) {
    final normalized = normalizeApplicationStatus(status).toLowerCase();
    final index = stages.indexWhere((stage) => stage.toLowerCase() == normalized);
    return index < 0 ? 0 : index;
  }

  DateTime? dateFrom(dynamic value) => value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

  String timeAgo(DateTime? date) {
    if (date == null) return 'Fecha pendiente';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hace 1 día';
    if (diff.inDays < 30) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} meses';
    return 'Hace ${(diff.inDays / 365).floor()} años';
  }

  Map<String, dynamic>? historyFor(String status) {
    final history = application['statusHistory'];
    if (history is! List) return null;
    for (final item in history.reversed) {
      if (item is Map && normalizeApplicationStatus(item['status']?.toString()).toLowerCase() == status.toLowerCase()) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final status = normalizeApplicationStatus(application['status']?.toString());
    final activeIndex = stageIndex(status);
    final job = application['jobId'] is Map ? Map<String, dynamic>.from(application['jobId']) : <String, dynamic>{};
    final company = job['companyId'] is Map ? job['companyId']['name']?.toString() ?? 'Empresa' : 'Empresa';
    final id = (application['_id'] ?? application['id'] ?? '').toString();
    final title = job['title']?.toString() ?? 'Oferta laboral';
    final location = job['location']?.toString().trim() ?? '';
    final modality = job['modality']?.toString().trim() ?? '';
    final applicantCount = (application['applicantCount'] as num?)?.toInt() ?? 1;
    final rawHistory = application['statusHistory'];
    final lastHistory = rawHistory is List && rawHistory.isNotEmpty ? Map<String, dynamic>.from(rawHistory.last) : <String, dynamic>{};
    final changedAt = dateFrom(lastHistory['changedAt'] ?? application['createdAt']);
    final isWeb = title.toLowerCase().contains('web') || title.toLowerCase().contains('desarroll') || title.toLowerCase().contains('frontend');
    final isHealth = title.toLowerCase().contains('salud') || title.toLowerCase().contains('enfer') || title.toLowerCase().contains('clínic');
    final IconData jobIcon = isWeb ? Icons.code_rounded : isHealth ? Icons.favorite_rounded : Icons.apartment_rounded;
    final Color iconColor = isWeb ? const Color(0xFF0F9278) : isHealth ? const Color(0xFFE83E83) : const Color(0xFF6555E8);
    final Color iconBg = isWeb ? const Color(0xFFDDF7F0) : isHealth ? const Color(0xFFFFE5F0) : const Color(0xFFEDE9FF);

    return Card(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: const Color(0x20654CE8),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFEAE6FA)), borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(15)), child: Icon(jobIcon, color: iconColor, size: 29)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, height: 1.25, fontWeight: FontWeight.w900, color: Color(0xFF19162D))),
              const SizedBox(height: 4),
              Text(company, style: const TextStyle(fontSize: 13, color: Color(0xFF514B70))),
              const SizedBox(height: 7),
              Wrap(spacing: 12, runSpacing: 6, children: [
                if (location.isNotEmpty) _JobMeta(icon: Icons.location_on_outlined, text: location),
                if (modality.isNotEmpty) _JobMeta(icon: Icons.work_outline, text: modality),
              ]),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF6555B8), size: 25),
          ]),
          const SizedBox(height: 18),
          Row(children: List.generate(stages.length, (index) {
            final completed = index < activeIndex;
            final active = index == activeIndex;
            final color = completed || active ? primary : const Color(0xFFE6E4F0);
            return Expanded(child: Row(children: [
              Semantics(
                button: true,
                label: 'Etapa ${index + 1} de ${stages.length}: ${stages[index]}. ${index < activeIndex ? 'Completada' : index == activeIndex ? 'Etapa actual' : 'Pendiente'}. Toca para consultar detalles.',
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => showDialog<void>(context: context, builder: (dialogContext) {
                  final stageHistory = historyFor(stages[index]);
                  final stageDate = dateFrom(stageHistory?['changedAt']);
                  final reached = index <= activeIndex;
                  final fallbackDate = index == 0 ? dateFrom(application['createdAt']) : null;
                  return AlertDialog(
                    title: Text(stages[index]),
                    content: Text(
                      '${descriptions[index]}'
                      '${reached ? '\n\nEstado: alcanzado.' : '\n\nEsta etapa todavía no se ha alcanzado.'}'
                      '${reached ? '\n${timeAgo(stageDate ?? fallbackDate)}' : ''}',
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar'))],
                  );
                }),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: completed ? primary : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: active ? primary : color, width: active ? 2.3 : 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: completed ? Colors.white : active ? primary : const Color(0xFF77728D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (index < stages.length - 1)
                Expanded(child: Container(height: 3, color: index < activeIndex ? primary : const Color(0xFFE6E4F0))),
            ]));
          })),
          const SizedBox(height: 12),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 3, children: [
            Text(status, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: primary)),
            const Text('•', style: TextStyle(color: Color(0xFF9690AF))),
            Text(timeAgo(changedAt), style: const TextStyle(fontSize: 12, color: Color(0xFF6F698A))),
          ]),
          const SizedBox(height: 7),
          Row(children: [
            const Icon(Icons.groups_2_outlined, size: 17, color: Color(0xFF696386)),
            const SizedBox(width: 6),
            Expanded(child: Text('$applicantCount ${applicantCount == 1 ? 'persona postulada' : 'personas postuladas'}', style: const TextStyle(fontSize: 12, color: Color(0xFF6F698A)))),
          ]),
          const SizedBox(height: 12),
          if (chatAvailableForStatus(status))
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEDE9FF), foregroundColor: primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(applicationId: id, token: token, title: 'Chat con $company'))),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Conversar con la empresa'),
            ))
          else
            const Text('El chat se habilita cuando la empresa actualice la etapa a “En proceso”.', style: TextStyle(color: Color(0xFF77728D), fontSize: 11)),
        ]),
      ),
    );
  }
}

class _JobMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _JobMeta({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 15, color: const Color(0xFF655D83)),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(color: Color(0xFF655D83), fontSize: 11.5)),
  ]);
}

class ChatScreen extends StatefulWidget {
  final String applicationId;
  final String token;
  final String title;
  const ChatScreen({
    super.key,
    required this.applicationId,
    required this.token,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  List<dynamic> messages = [];
  bool loading = true;
  bool sending = false;
  String? error;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    loadMessages();
    refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!sending) loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadMessages({bool silent = false}) async {
    if (!silent && mounted) setState(() => loading = true);
    try {
      final items = await api.chatMessages(widget.token, widget.applicationId);
      if (mounted) {
        setState(() {
          messages = items;
          error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (x) {
      if (mounted && !silent) setState(() => error = x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !silent) setState(() => loading = false);
    }
  }

  Future<void> sendMessage() async {
    final content = controller.text.trim();
    if (content.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await api.sendChatMessage(widget.token, widget.applicationId, content);
      controller.clear();
      await loadMessages(silent: true);
    } catch (x) {
      toast(x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = (sessionUser?['id'] ?? sessionUser?['_id'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Actualizar mensajes',
            onPressed: () => loadMessages(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Text(
                'Chat privado de esta postulación. Evita compartir información sensible innecesaria.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null && messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(error!, textAlign: TextAlign.center),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: () => loadMessages(),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : messages.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Todavía no hay mensajes. Escribe para iniciar la conversación.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: muted),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(14),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = Map<String, dynamic>.from(messages[index]);
                                final mine = message['senderId']?.toString() == currentUserId;
                                return Align(
                                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 9),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: mine ? const Color(0xFFEDE9FE) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!mine)
                                          Text(message['senderName']?.toString() ?? 'Usuario',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primary)),
                                        Text(message['content']?.toString() ?? ''),
                                        const SizedBox(height: 4),
                                        Text(
                                          _messageTime(message['createdAt']),
                                          style: const TextStyle(fontSize: 10, color: muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            if (error != null && messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(error!, style: const TextStyle(fontSize: 11, color: Colors.red)),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(),
                        maxLength: 2000,
                        maxLines: 3,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Enviar mensaje',
                      onPressed: sending ? null : sendMessage,
                      icon: sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _messageTime(dynamic raw) {
  if (raw == null) return '';
  final date = DateTime.tryParse(raw.toString())?.toLocal();
  if (date == null) return '';
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class CandidateProfilePanel extends StatefulWidget {
  final String token;
  const CandidateProfilePanel({super.key, required this.token});

  @override
  State<CandidateProfilePanel> createState() => _CandidateProfilePanelState();
}

class _CandidateProfilePanelState extends State<CandidateProfilePanel> {
  Map<String, dynamic>? user;
  bool loading = true;
  bool saving = false;
  bool uploadingCv = false;
  bool analyzingCv = false;
  bool uploadingPhoto = false;
  Uint8List? profilePhotoBytes;
  String? error;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Map<String, dynamic> get profile {
    final raw = user?['profile'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  String valueOf(dynamic value) {
    final valueText = value?.toString().trim() ?? '';
    return valueText.isEmpty ? 'Pendiente de completar' : valueText;
  }

  bool filled(dynamic value) => value != null && value.toString().trim().isNotEmpty;

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.profile(widget.token);
      Uint8List? photoBytes;
      if (result['hasProfilePhoto'] == true) {
        try {
          photoBytes = await api.profilePhoto(widget.token);
        } catch (_) {
          // Keep the rest of the profile usable if the image cannot be loaded.
        }
      }
      if (mounted) {
        setState(() {
          user = result;
          profilePhotoBytes = photoBytes;
        });
      }
    } catch (x) {
      if (mounted) setState(() => error = x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> uploadProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      toast('No se pudo leer la foto. Selecciónala nuevamente.');
      return;
    }

    setState(() => uploadingPhoto = true);
    try {
      await api.uploadProfilePhoto(widget.token, path);
      await loadProfile();
      toast('Foto de perfil actualizada correctamente.');
    } catch (x) {
      toast(x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  Future<void> editProfile() async {
    if (user == null) return;
    final birth = TextEditingController(text: profile['birth']?.toString() ?? '');
    final address = TextEditingController(text: profile['address']?.toString() ?? '');
    final education = TextEditingController(text: profile['education']?.toString() ?? '');
    final professionalSummary = TextEditingController(text: profile['professionalSummary']?.toString() ?? '');
    final experience = TextEditingController(text: profile['experience']?.toString() ?? '0');
    final skillsController = TextEditingController(text: profile['skills'] is List ? (profile['skills'] as List).join(', ') : '');
    final projectsController = TextEditingController(text: profile['projects'] is List ? (profile['projects'] as List).join('\n') : '');
    final certificationsController = TextEditingController(text: profile['certifications'] is List ? (profile['certifications'] as List).join('\n') : '');
    const locationOptions = [
      'Lima Metropolitana',
      'Callao',
      'Arequipa',
      'Trujillo',
      'Chiclayo',
      'Piura',
      'Cusco',
      'Huancayo',
      'Iquitos',
      'Otra',
    ];
    const modalityOptions = ['Remoto', 'Híbrido', 'Presencial', 'Indistinto'];
    final savedLocation = profile['location']?.toString();
    String? selectedLocation = locationOptions.contains(savedLocation)
        ? savedLocation
        : (savedLocation?.toLowerCase().contains('lima') == true
            ? 'Lima Metropolitana'
            : null);
    final savedModality = profile['modality']?.toString();
    String? selectedModality =
        modalityOptions.contains(savedModality) ? savedModality : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Editar información personal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                F(birth, 'Fecha de nacimiento (dd/mm/aaaa)'),
                F(address, 'Dirección'),
                F(education, 'Carrera o formación profesional'),
                F(professionalSummary, 'Resumen profesional', max: 4),
                F(experience, 'Años de experiencia', type: TextInputType.number, format: digits(2)),
                F(skillsController, 'Habilidades (separadas por comas)', max: 3),
                F(projectsController, 'Proyectos relevantes (uno por línea)', max: 3),
                F(certificationsController, 'Certificaciones o cursos (uno por línea)', max: 3),
                const SizedBox(height: 4),
                const Text(
                  'Estos datos, junto con las palabras clave de tu CV, nos ayudan a mostrar ofertas adecuadas a tu perfil.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('location-$selectedLocation'),
                  initialValue: selectedLocation,
                  decoration: const InputDecoration(labelText: 'Ubicación preferida'),
                  items: locationOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedLocation = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('modality-$selectedModality'),
                  initialValue: selectedModality,
                  decoration: const InputDecoration(labelText: 'Modalidad laboral'),
                  items: modalityOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedModality = value),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La ubicación y la modalidad ayudan a calcular tus recomendaciones.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final years = int.tryParse(experience.text.trim());
                if (selectedLocation == null || selectedModality == null) {
                  toast('Selecciona tu ubicación y modalidad laboral.');
                  return;
                }
                if (experience.text.trim().isNotEmpty && (years == null || years < 0 || years > 60)) {
                  toast('Introduce años de experiencia válidos entre 0 y 60.');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      setState(() => saving = true);
      try {
        final updated = await api.updateProfile(widget.token, {
          'birth': birth.text.trim(),
          'address': address.text.trim(),
          'education': education.text.trim(),
          'professionalSummary': professionalSummary.text.trim(),
          'experience': int.tryParse(experience.text.trim()) ?? 0,
          'skills': skillsController.text.split(',').map((skill) => skill.trim()).where((skill) => skill.isNotEmpty).take(40).toList(),
          'projects': projectsController.text.split('\n').map((item) => item.trim()).where((item) => item.isNotEmpty).take(20).toList(),
          'certifications': certificationsController.text.split('\n').map((item) => item.trim()).where((item) => item.isNotEmpty).take(20).toList(),
          'location': selectedLocation,
          'modality': selectedModality,
        });
        if (mounted) {
          setState(() => user = updated);
          toast('Tu perfil se actualizó correctamente.');
        }
      } catch (x) {
        toast(x.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => saving = false);
      }
    }

    birth.dispose();
    address.dispose();
    education.dispose();
    professionalSummary.dispose();
    experience.dispose();
    skillsController.dispose();
    projectsController.dispose();
    certificationsController.dispose();
  }

  Future<void> replaceCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: false,
    );
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      toast('No se pudo leer el archivo. Selecciona el CV nuevamente.');
      return;
    }
    setState(() => uploadingCv = true);
    try {
      await api.uploadCv(widget.token, path);
      await loadProfile();
      toast('Tu CV se guardó correctamente.');
    } catch (x) {
      toast(x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => uploadingCv = false);
    }
  }

  Future<void> analyzeCvForSuggestions() async {
    setState(() => analyzingCv = true);
    try {
      final analysis = await api.analyzeCv(widget.token);
      await loadProfile();
      final skills = (analysis['skills'] as List?)?.map((e) => e.toString()).toList() ?? [];
      toast(skills.isEmpty
          ? 'CV revisado, pero no se detectaron habilidades conocidas. Prueba con un PDF de texto o DOCX.'
          : 'Habilidades detectadas: ${skills.take(6).join(', ')}. En Inicio puedes ver las ofertas sugeridas.');
    } catch (x) {
      toast(x.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => analyzingCv = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && user == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && user == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Info('No se pudo cargar tu perfil', 'Comprueba tu conexión e inténtalo de nuevo.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    final data = user ?? <String, dynamic>{};
    final name = valueOf(data['name']);
    final email = valueOf(data['email']);
    final phone = valueOf(data['phone']);
    final birth = profile['birth'];
    final address = profile['address'];
    final conadis = data['conadisNumber'];
    final hasCv = data['hasCv'] == true;
    final completionFields = [
      data['name'],
      data['email'],
      data['phone'],
      birth,
      address,
      profile['education'],
      profile['professionalSummary'],
      profile['experience'],
      profile['skills'] is List && (profile['skills'] as List).isNotEmpty ? 'skills' : null,
      profile['projects'] is List && (profile['projects'] as List).isNotEmpty ? 'projects' : null,
      profile['certifications'] is List && (profile['certifications'] as List).isNotEmpty ? 'certifications' : null,
      profile['location'],
      profile['modality'],
      conadis,
      hasCv ? 'cv' : null,
    ];
    final completed =
        completionFields.where((item) => filled(item)).length;
    final percent = completed / completionFields.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7FF),
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFEDE9FE),
                    backgroundImage: profilePhotoBytes == null
                        ? null
                        : MemoryImage(profilePhotoBytes!),
                    child: profilePhotoBytes == null
                        ? const Icon(Icons.person_outline, color: primary, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        const Text('Perfil de candidato',
                            style: TextStyle(color: muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar perfil',
                    onPressed: loading ? null : loadProfile,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: uploadingPhoto ? null : uploadProfilePhoto,
                  icon: uploadingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    uploadingPhoto
                        ? 'Subiendo foto...'
                        : profilePhotoBytes == null
                            ? 'Subir foto de perfil'
                            : 'Cambiar foto de perfil',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Completitud del perfil',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('${(percent * 100).round()}%',
                      style: const TextStyle(
                          color: primary, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: line,
                  color: primary,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: saving ? null : editProfile,
                icon: const Icon(Icons.edit_outlined),
                label: Text(saving ? 'Guardando...' : 'Editar información'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Section('Información personal'),
        _ProfileValue(icon: Icons.email_outlined, label: 'Correo electrónico', value: email),
        _ProfileValue(icon: Icons.phone_outlined, label: 'Teléfono', value: phone),
        _ProfileValue(icon: Icons.cake_outlined, label: 'Fecha de nacimiento', value: valueOf(birth)),
        _ProfileValue(icon: Icons.location_on_outlined, label: 'Dirección', value: valueOf(address)),
        _ProfileValue(icon: Icons.school_outlined, label: 'Carrera o formación', value: valueOf(profile['education'])),
        _ProfileValue(icon: Icons.notes_outlined, label: 'Resumen profesional', value: valueOf(profile['professionalSummary'])),
        _ProfileValue(icon: Icons.work_history_outlined, label: 'Años de experiencia', value: valueOf(profile['experience'])),
        _ProfileValue(icon: Icons.stars_outlined, label: 'Habilidades', value: valueOf(profile['skills'] is List ? (profile['skills'] as List).join(', ') : '')),
        _ProfileValue(icon: Icons.folder_open_outlined, label: 'Proyectos', value: valueOf(profile['projects'] is List ? (profile['projects'] as List).join(' · ') : '')),
        _ProfileValue(icon: Icons.workspace_premium_outlined, label: 'Certificaciones y cursos', value: valueOf(profile['certifications'] is List ? (profile['certifications'] as List).join(' · ') : '')),
        _ProfileValue(icon: Icons.map_outlined, label: 'Ubicación preferida', value: valueOf(profile['location'])),
        _ProfileValue(icon: Icons.work_outline, label: 'Modalidad laboral', value: valueOf(profile['modality'])),
        _ProfileValue(icon: Icons.verified_user_outlined, label: 'Número de CONADIS', value: valueOf(conadis)),
        const SizedBox(height: 18),
        const Section('Mi currículum'),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: primary, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCv ? valueOf(data['cvFileName']) : 'Todavía no has subido un CV',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCv ? 'Documento guardado en tu perfil.' : 'Aceptamos PDF, DOC y DOCX. Máximo 5 MB.',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: uploadingCv ? null : replaceCv,
            icon: uploadingCv
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file),
            label: Text(uploadingCv ? 'Subiendo CV...' : hasCv ? 'Actualizar CV' : 'Subir CV'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: !hasCv || analyzingCv ? null : analyzeCvForSuggestions,
            icon: analyzingCv
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(analyzingCv ? 'Analizando CV...' : 'Analizar CV y sugerir ofertas'),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        const Section('Privacidad y cuenta'),
        const Text('Puedes eliminar tu cuenta y los datos asociados desde aquí.', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 8),
        DeleteAccountButton(token: widget.token),
      ],
    );
  }
}

class _ProfileValue extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CompanyMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _CompanyMetric({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E0FA))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: primary, size: 18),
      const SizedBox(width: 7),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF211B43))),
        Text(label, style: const TextStyle(fontSize: 11, color: muted)),
      ]),
    ]),
  );
}

class _EmptyCompanyOffers extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyCompanyOffers({required this.onCreate});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE6E1F5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(color: Color(0xFFF0EDFF), shape: BoxShape.circle),
        child: const Icon(Icons.work_outline_rounded, color: primary, size: 34),
      ),
      const SizedBox(height: 12),
      const Text('Tu primera oferta empieza aquí', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF211B43))),
      const SizedBox(height: 6),
      const Text('Publica una vacante clara y accesible para que las personas candidatas puedan conocerla y postular.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.4)),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Publicar mi primera oferta')),
    ]),
  );
}

class _CompanyOfferCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _CompanyOfferCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final title = (job['title'] ?? 'Oferta laboral').toString();
    final description = (job['description'] ?? '').toString().trim();
    final location = (job['location'] ?? '').toString().trim();
    final modality = (job['modality'] ?? '').toString().trim();
    final category = (job['category'] ?? '').toString().trim();
    final contractType = (job['contractType'] ?? '').toString().trim();
    final active = job['active'] != false;
    final tags = <String>[if (category.isNotEmpty) category, if (modality.isNotEmpty) modality, if (contractType.isNotEmpty) contractType];

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E0FA))),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: const Color(0xFFEDE9FF), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.work_outline_rounded, color: primary, size: 24),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF211B43))),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 6, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: active ? const Color(0xFFE4F8EE) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99)), child: Text(active ? 'Activa' : 'Cerrada', style: TextStyle(color: active ? const Color(0xFF137B4B) : muted, fontSize: 11, fontWeight: FontWeight.w800))),
                ...tags.map((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF4F1FF), borderRadius: BorderRadius.circular(99)), child: Text(tag, style: const TextStyle(color: Color(0xFF59508A), fontSize: 11, fontWeight: FontWeight.w600)))),
              ]),
            ])),
          ]),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: muted), const SizedBox(width: 5), Expanded(child: Text(location, style: const TextStyle(color: muted, fontSize: 12)))]),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5F5A77), fontSize: 12, height: 1.35)),
          ],
        ]),
      ),
    );
  }
}

class CompanyHome extends StatefulWidget{const CompanyHome({super.key});@override State<CompanyHome> createState()=>_CompanyHomeState();}
class _CompanyHomeState extends State<CompanyHome> {
  int tab = 0;
  List<dynamic> mine = [];
  List<dynamic> apps = [];
  bool loading = true;
  String? loadError;

  String selectedApplicantJobId = 'Todas';
  String selectedApplicantStatus = 'Todas';
  String selectedApplicantCriterion = 'Todas';
  String selectedApplicantSort = 'Más recientes';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }
    try {
      final token = sessionToken;
      if (token == null || token.isEmpty) {
        throw Exception('Tu sesión ha expirado. Inicia sesión nuevamente.');
      }
      final jobs = await api.myJobs(token);
      if (mounted) setState(() => mine = jobs);
      final applications = await api.applications(token);
      if (mounted) {
        setState(() {
          apps = applications;
          loadError = null;
        });
      }
    } catch (x) {
      final message = x.toString().replaceFirst('Exception: ', '');
      if (mounted) setState(() => loadError = message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic> _applicationCandidate(dynamic application) {
    final value = application is Map ? application['candidateId'] : null;
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  Map<String, dynamic> _applicationJob(dynamic application) {
    final value = application is Map ? application['jobId'] : null;
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  String _applicationJobId(dynamic application) {
    final job = _applicationJob(application);
    return (job['_id'] ?? job['id'] ?? '').toString();
  }

  String _candidateName(dynamic application) =>
      _applicationCandidate(application)['name']?.toString().trim().toLowerCase() ?? '';

  String _jobTitle(dynamic application) =>
      _applicationJob(application)['title']?.toString().trim().toLowerCase() ?? '';

  String _normalizeApplicantTerm(String value) => value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàäâã]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöôõ]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll('ñ', 'n');

  List<String> _candidateSkillTerms(dynamic application) {
    final candidate = _applicationCandidate(application);
    final profile = candidate['profile'] is Map
        ? Map<String, dynamic>.from(candidate['profile'])
        : <String, dynamic>{};
    final analysis = candidate['cvAnalysis'] is Map
        ? Map<String, dynamic>.from(candidate['cvAnalysis'])
        : <String, dynamic>{};
    final profileSkills = profile['skills'] is List
        ? (profile['skills'] as List).map((item) => item.toString())
        : const <String>[];
    final cvSkills = analysis['skills'] is List
        ? (analysis['skills'] as List).map((item) => item.toString())
        : const <String>[];
    return <String>{...profileSkills, ...cvSkills}
        .map(_normalizeApplicantTerm)
        .where((value) => value.isNotEmpty)
        .toList();
  }

  List<String> _jobRequiredSkills(dynamic application) {
    final job = _applicationJob(application);
    final raw = job['requiredSkills'];
    if (raw is! List) return <String>[];
    return raw.map((item) => _normalizeApplicantTerm(item.toString())).where((value) => value.isNotEmpty).toList();
  }

  bool _hasRequiredSkillMatch(dynamic application) {
    final required = _jobRequiredSkills(application);
    final candidateSkills = _candidateSkillTerms(application);
    if (required.isEmpty || candidateSkills.isEmpty) return false;
    return required.any((requirement) => candidateSkills.any((skill) =>
        skill == requirement || skill.contains(requirement) || requirement.contains(skill)));
  }

  bool _experienceIsCompatible(dynamic application) {
    final candidate = _applicationCandidate(application);
    final profile = candidate['profile'] is Map
        ? Map<String, dynamic>.from(candidate['profile'])
        : <String, dynamic>{};
    final job = _applicationJob(application);
    final requiredYears = num.tryParse((job['experienceRequired'] ?? '').toString());
    final candidateYears = num.tryParse((profile['experience'] ?? '').toString());
    return requiredYears != null &&
        requiredYears > 0 &&
        candidateYears != null &&
        candidateYears >= requiredYears;
  }

  bool _profileNeedsReview(dynamic application) {
    final candidate = _applicationCandidate(application);
    final profile = candidate['profile'] is Map
        ? Map<String, dynamic>.from(candidate['profile'])
        : <String, dynamic>{};
    final hasEducation = (profile['education']?.toString().trim().isNotEmpty ?? false);
    final hasSummary = (profile['professionalSummary']?.toString().trim().isNotEmpty ?? false);
    final hasSkills = _candidateSkillTerms(application).isNotEmpty;
    return !hasEducation || !hasSummary || !hasSkills;
  }

  List<Map<String, dynamic>> get filteredCompanyApplications {
    final result = apps
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((application) {
      if (selectedApplicantJobId != 'Todas' &&
          _applicationJobId(application) != selectedApplicantJobId) {
        return false;
      }
      if (selectedApplicantStatus != 'Todas' &&
          normalizeApplicationStatus(application['status']?.toString()).toLowerCase() !=
              selectedApplicantStatus.toLowerCase()) {
        return false;
      }
      switch (selectedApplicantCriterion) {
        case 'Habilidades coincidentes':
          if (!_hasRequiredSkillMatch(application)) return false;
          break;
        case 'Experiencia compatible':
          if (!_experienceIsCompatible(application)) return false;
          break;
        case 'Datos por revisar':
          if (!_profileNeedsReview(application)) return false;
          break;
      }
      return true;
    }).toList();

    switch (selectedApplicantSort) {
      case 'Nombre del postulante':
        result.sort((a, b) => _candidateName(a).compareTo(_candidateName(b)));
        break;
      case 'Nombre de la oferta':
        result.sort((a, b) => _jobTitle(a).compareTo(_jobTitle(b)));
        break;
      default:
        result.sort((a, b) {
          final dateA = DateTime.tryParse((a['createdAt'] ?? '').toString());
          final dateB = DateTime.tryParse((b['createdAt'] ?? '').toString());
          return (dateB ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(dateA ?? DateTime.fromMillisecondsSinceEpoch(0));
        });
    }
    return result;
  }

  Widget _applicantDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget applicantFiltersPanel() {
    const statuses = ['Todas', 'Postulado', 'CV visto', 'En proceso', 'Aceptado', 'Proceso terminado'];
    const criteria = ['Todas', 'Habilidades coincidentes', 'Experiencia compatible', 'Datos por revisar'];
    const sortOptions = ['Más recientes', 'Nombre del postulante', 'Nombre de la oferta'];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        border: Border.all(color: const Color(0xFFE5E0FA)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtrar y organizar', style: TextStyle(fontWeight: FontWeight.w900, color: ink, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Los criterios solo ayudan a localizar postulaciones. “Datos por revisar” significa información incompleta, no falta de capacidad. Revisa los requisitos y ajustes de forma individual; no uses un filtro como decisión de contratación.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          _applicantDropdown(
            label: 'Oferta laboral',
            value: selectedApplicantJobId,
            hint: 'Muestra postulaciones para una oferta concreta.',
            items: [
              const DropdownMenuItem(value: 'Todas', child: Text('Todas las ofertas')),
              ...mine.map((job) {
                final map = Map<String, dynamic>.from(job as Map);
                final id = (map['_id'] ?? map['id'] ?? '').toString();
                final title = map['title']?.toString() ?? 'Oferta';
                return DropdownMenuItem<String>(
                  value: id.isEmpty ? 'Todas' : id,
                  child: Text(title, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ],
            onChanged: (value) => setState(() => selectedApplicantJobId = value ?? 'Todas'),
          ),
          const SizedBox(height: 10),
          _applicantDropdown(
            label: 'Etapa de selección',
            value: selectedApplicantStatus,
            items: statuses.map((value) => DropdownMenuItem(value: value, child: Text(value == 'Todas' ? 'Todas las etapas' : value))).toList(),
            onChanged: (value) => setState(() => selectedApplicantStatus = value ?? 'Todas'),
          ),
          const SizedBox(height: 10),
          _applicantDropdown(
            label: 'Criterio de organización',
            value: selectedApplicantCriterion,
            hint: 'Sin puntuación total ni ranking automático de personas.',
            items: criteria.map((value) => DropdownMenuItem(value: value, child: Text(value == 'Todas' ? 'Sin criterio adicional' : value))).toList(),
            onChanged: (value) => setState(() => selectedApplicantCriterion = value ?? 'Todas'),
          ),
          const SizedBox(height: 10),
          _applicantDropdown(
            label: 'Ordenar por',
            value: selectedApplicantSort,
            items: sortOptions.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => setState(() => selectedApplicantSort = value ?? 'Más recientes'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                selectedApplicantJobId = 'Todas';
                selectedApplicantStatus = 'Todas';
                selectedApplicantCriterion = 'Todas';
                selectedApplicantSort = 'Más recientes';
              }),
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpiar filtros'),
            ),
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              'Mostrando ${filteredCompanyApplications.length} de ${apps.length} postulaciones.',
              style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> create() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final experience = TextEditingController(text: '0');
    final requiredSkills = TextEditingController();
    final preferredSkills = TextEditingController();
    final accessibilityDetails = TextEditingController();
    final selectedAccessibilityOptions = <String>{};
    const accessibilityOptions = [
      'Acceso sin escalones o ascensor',
      'Baño accesible',
      'Puesto de trabajo adaptable',
      'Tecnología de asistencia compatible',
      'Entrevista remota disponible',
      'Horario flexible',
      'Modalidad remota',
    ];
    final salary = TextEditingController();
    final location = TextEditingController(text: 'Lima, Perú');
    const modalities = ['Remoto', 'Híbrido', 'Presencial'];
    const categories = ['Tecnología', 'Administración', 'Diseño', 'Atención al cliente', 'Educación', 'Salud', 'Finanzas', 'Logística', 'Marketing', 'Otro'];
    const contracts = ['Tiempo completo', 'Medio tiempo', 'Temporal', 'Prácticas', 'Freelance', 'Por horas'];
    String modality = 'Remoto';
    String category = 'Tecnología';
    String contractType = 'Tiempo completo';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Nueva oferta laboral'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                F(title, 'Título del puesto'),
                F(description, 'Descripción del puesto', max: 5),
                F(requiredSkills, 'Habilidades obligatorias (separadas por comas)', max: 3),
                F(preferredSkills, 'Habilidades deseables (separadas por comas)', max: 3),
                F(experience, 'Experiencia requerida en años (0 = sin requisito)', type: TextInputType.number, format: digits(2)),
                F(accessibilityDetails, 'Otros detalles de accesibilidad (opcional)', max: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 2, bottom: 6),
                    child: Text(
                      'Marca únicamente las condiciones que realmente ofrece el puesto.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 0,
                    children: accessibilityOptions.map((option) => FilterChip(
                      label: Text(option),
                      selected: selectedAccessibilityOptions.contains(option),
                      onSelected: (selected) => setDialogState(() {
                        if (selected) {
                          selectedAccessibilityOptions.add(option);
                        } else {
                          selectedAccessibilityOptions.remove(option);
                        }
                      }),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                F(salary, 'Salario o rango salarial (opcional)'),
                F(location, 'Ubicación'),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Área profesional'),
                  items: categories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => category = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: modality,
                  decoration: const InputDecoration(labelText: 'Modalidad'),
                  items: modalities
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => modality = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: contractType,
                  decoration: const InputDecoration(labelText: 'Tipo de contrato'),
                  items: contracts.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => contractType = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true &&
        title.text.trim().isNotEmpty &&
        description.text.trim().isNotEmpty) {
      try {
        await api.createJob(sessionToken!, {
          'title': title.text.trim(),
          'description': description.text.trim(),
          'location': location.text.trim(),
          'category': category,
          'modality': modality,
          'contractType': contractType,
          'experienceRequired': int.tryParse(experience.text.trim()) ?? 0,
          'requiredSkills': requiredSkills.text.split(',').map((skill) => skill.trim()).where((skill) => skill.isNotEmpty).take(40).toList(),
          'preferredSkills': preferredSkills.text.split(',').map((skill) => skill.trim()).where((skill) => skill.isNotEmpty).take(40).toList(),
          'accessibilityDetails': [
            accessibilityDetails.text.trim(),
            ...selectedAccessibilityOptions,
          ].where((item) => item.trim().isNotEmpty).join('\n'),
          'salary': salary.text.trim(),
        });
        toast('Oferta publicada correctamente.');
        await load();
      } catch (x) {
        toast(x.toString().replaceFirst('Exception: ', ''));
      }
    }
    title.dispose();
    description.dispose();
    experience.dispose();
    requiredSkills.dispose();
    preferredSkills.dispose();
    accessibilityDetails.dispose();
    salary.dispose();
    location.dispose();
  }

  Future<void> changeApplicationStatus(String id, String status) async {
    try {
      await api.updateApplicationStatus(sessionToken!, id, status);
      toast('Etapa actualizada a: $status.');
      await load();
    } catch (x) {
      toast(x.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext c) => Dash(
        title: 'Hola, ${sessionUser?['name'] ?? 'empresa'}',
        tab: tab,
        onTab: (x) {
          setState(() => tab = x);
          if (x == 0 || x == 1 || x == 2) load(showLoading: false);
        },
        labels: const ['Inicio', 'Ofertas', 'Candidatos', 'Perfil'],
        children: tab == 0
            ? [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0EDFF), Color(0xFFFDFBFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFE5E0FA)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.diversity_3_outlined, color: primary),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Talento sin barreras',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF211B43)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Publica oportunidades accesibles y encuentra personas con talento que pueden aportar a tu equipo.',
                        style: TextStyle(color: Color(0xFF5E5878), height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CompanyMetric(value: loading && mine.isEmpty ? '—' : '${mine.length}', label: 'Ofertas publicadas', icon: Icons.work_outline),
                          _CompanyMetric(value: loading && apps.isEmpty ? '—' : '${apps.length}', label: 'Postulaciones', icon: Icons.groups_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Btn('+ Crear nueva oferta', create),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(child: Section('Mis ofertas')),
                    IconButton(
                      tooltip: 'Actualizar ofertas',
                      onPressed: loading ? null : () => load(),
                      icon: const Icon(Icons.refresh, color: primary),
                    ),
                  ],
                ),
                if (loading && mine.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (mine.isEmpty && loadError != null) ...[
                  Info('No se pudieron cargar tus ofertas', loadError!),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ]
                else if (mine.isEmpty)
                  _EmptyCompanyOffers(onCreate: create)
                else ...[
                  ...mine.take(3).map((job) => _CompanyOfferCard(job: Map<String, dynamic>.from(job))),
                  if (mine.length > 3)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => tab = 1),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text('Ver las ${mine.length} ofertas'),
                      ),
                    ),
                ],
                if (loadError != null && mine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Aviso de actualización: $loadError', style: const TextStyle(color: Colors.deepOrange, fontSize: 12)),
                  ),
              ]
            : tab == 1
                ? [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(child: Section('Todas tus ofertas')),
                        IconButton(
                          tooltip: 'Actualizar ofertas',
                          onPressed: loading ? null : () => load(),
                          icon: const Icon(Icons.refresh, color: primary),
                        ),
                      ],
                    ),
                    Btn('+ Crear oferta', create),
                    const SizedBox(height: 14),
                    if (loading && mine.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (mine.isEmpty && loadError != null) ...[
                      Info('No se pudieron cargar tus ofertas', loadError!),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(onPressed: () => load(), icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                    ]
                    else if (mine.isEmpty)
                      _EmptyCompanyOffers(onCreate: create)
                    else
                      ...mine.map((job) => _CompanyOfferCard(job: Map<String, dynamic>.from(job))),
                  ]
                : tab == 2
                    ? [
                        const Section('Postulaciones recibidas'),
                        const Text(
                          'Organiza las candidaturas por oferta, etapa y requisitos declarados. Los filtros no asignan puntuaciones ni sustituyen la revisión individual. Considera los ajustes de accesibilidad y las competencias relevantes para el puesto.',
                          style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        if (mine.isNotEmpty) applicantFiltersPanel(),
                        if (loading && apps.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (apps.isEmpty && loadError != null) ...[
                          Info('No se pudieron cargar las postulaciones', loadError!),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(onPressed: () => load(), icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                        ]
                        else if (apps.isEmpty)
                          const Info('Aún no hay postulaciones', 'Cuando una persona postule a tus ofertas, aparecerá aquí para que puedas actualizar su etapa y conversar cuando corresponda.')
                        else if (filteredCompanyApplications.isEmpty)
                          const Info('No hay postulaciones con estos filtros', 'Prueba otra oferta, etapa o criterio. Un dato ausente no significa que la persona no cumpla con el puesto.')
                        else
                          ...filteredCompanyApplications.map((a) => CompanyApplicationCard(
                                application: Map<String, dynamic>.from(a),
                                onStatusChanged: (nextStatus) => changeApplicationStatus(
                                  (a['_id'] ?? a['id']).toString(),
                                  nextStatus,
                                ),
                                token: sessionToken!,
                              )),
]
                    : [CompanyProfilePanel(token: sessionToken!)],
      );
}

class CompanyApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final ValueChanged<String> onStatusChanged;
  final String token;

  const CompanyApplicationCard({
    super.key,
    required this.application,
    required this.onStatusChanged,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final status = normalizeApplicationStatus(application['status']?.toString());
    final candidateData = application['candidateId'] is Map
        ? Map<String, dynamic>.from(application['candidateId'])
        : <String, dynamic>{};
    final candidate = candidateData['name']?.toString() ?? 'Candidato';
    final candidateProfile = candidateData['profile'] is Map
        ? Map<String, dynamic>.from(candidateData['profile'])
        : <String, dynamic>{};
    final cvAnalysis = candidateData['cvAnalysis'] is Map
        ? Map<String, dynamic>.from(candidateData['cvAnalysis'])
        : <String, dynamic>{};
    final job = application['jobId'] is Map
        ? Map<String, dynamic>.from(application['jobId'])
        : <String, dynamic>{};
    final appId = (application['_id'] ?? application['id'] ?? '').toString();
    final jobTitle = job['title']?.toString() ?? 'Oferta';
    const stages = ['Postulado', 'CV visto', 'En proceso', 'Aceptado', 'Proceso terminado'];

    String fieldText(dynamic value) => value == null ? '' : value.toString().trim();

    final profileSkills = candidateProfile['skills'] is List
        ? (candidateProfile['skills'] as List).map((item) => item.toString().trim()).where((item) => item.isNotEmpty)
        : const <String>[];
    final cvSkills = cvAnalysis['skills'] is List
        ? (cvAnalysis['skills'] as List).map((item) => item.toString().trim()).where((item) => item.isNotEmpty)
        : const <String>[];
    final skills = <String>{...profileSkills, ...cvSkills}.toList();

    Widget profileField(String label, String value) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: ink)),
          ],
        ),
      );
    }

    final hasProfessionalDetails = [
      fieldText(candidateProfile['education']),
      fieldText(candidateProfile['professionalSummary']),
      fieldText(candidateProfile['experience']),
      fieldText(candidateProfile['projects'] is List ? (candidateProfile['projects'] as List).join(' · ') : ''),
      fieldText(candidateProfile['certifications'] is List ? (candidateProfile['certifications'] as List).join(' · ') : ''),
    ].any((value) => value.isNotEmpty) || skills.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(candidate,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 3),
            Text(jobTitle, style: const TextStyle(color: muted)),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: const Icon(Icons.badge_outlined, color: primary),
                title: const Text(
                  'Ver perfil profesional',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                ),
                subtitle: const Text(
                  'Formación, experiencia, habilidades y proyectos',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
                children: [
                  if (!hasProfessionalDetails)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'La persona aún no ha completado estos datos en su perfil.',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  profileField('Carrera o formación', fieldText(candidateProfile['education'])),
                  profileField('Resumen profesional', fieldText(candidateProfile['professionalSummary'])),
                  profileField(
                    'Experiencia',
                    candidateProfile['experience'] == null
                        ? ''
                        : '${candidateProfile['experience']} año(s)',
                  ),
                  if (skills.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Habilidades', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted)),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: skills.take(16).map((skill) => Chip(
                          label: Text(skill),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFF1EEFF),
                          side: BorderSide.none,
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  profileField(
                    'Proyectos relevantes',
                    fieldText(candidateProfile['projects'] is List ? (candidateProfile['projects'] as List).join(' · ') : ''),
                  ),
                  profileField(
                    'Certificaciones y cursos',
                    fieldText(candidateProfile['certifications'] is List ? (candidateProfile['certifications'] as List).join(' · ') : ''),
                  ),
                  const Text(
                    'Solo se muestran los datos profesionales que la persona ha completado en su perfil.',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('$appId-$status'),
              initialValue: stages.contains(status) ? status : 'Postulado',
              decoration: const InputDecoration(labelText: 'Etapa del proceso'),
              items: stages
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (nextStatus) {
                if (nextStatus != null && nextStatus != status) {
                  onStatusChanged(nextStatus);
                }
              },
            ),
            const SizedBox(height: 10),
            if (chatAvailableForStatus(status))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        applicationId: appId,
                        token: token,
                        title: 'Chat con $candidate',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Abrir chat'),
                ),
              )
            else
              const Text(
                'El chat aparecerá cuando actualices el estado a “En proceso”.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class CompanyProfilePanel extends StatefulWidget {
  final String token;
  const CompanyProfilePanel({super.key, required this.token});

  @override
  State<CompanyProfilePanel> createState() => _CompanyProfilePanelState();
}

class _CompanyProfilePanelState extends State<CompanyProfilePanel> {
  Map<String, dynamic>? user;
  bool loading = true;
  bool uploadingPhoto = false;
  bool savingProfile = false;
  Uint8List? profilePhotoBytes;
  String? error;

  Map<String, dynamic> get companyProfile {
    final value = user?['companyProfile'];
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.profile(widget.token);
      Uint8List? photoBytes = profilePhotoBytes;
      if (result['hasProfilePhoto'] == true && photoBytes == null) {
        try {
          photoBytes = await api.profilePhoto(widget.token);
        } catch (_) {
          // The profile should remain usable if its image is unavailable.
        }
      } else if (result['hasProfilePhoto'] != true) {
        photoBytes = null;
      }
      if (mounted) {
        setState(() {
          user = result;
          profilePhotoBytes = photoBytes;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> uploadProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      toast('No se pudo leer la foto. Selecciónala nuevamente.');
      return;
    }

    setState(() => uploadingPhoto = true);
    try {
      await api.uploadProfilePhoto(widget.token, path);
      profilePhotoBytes = null;
      await load();
      toast('Foto de perfil de empresa actualizada.');
    } catch (e) {
      toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  String showValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Pendiente de completar' : text;
  }

  Future<void> editCompanyProfile() async {
    final data = user ?? <String, dynamic>{};
    final profile = companyProfile;
    final name = TextEditingController(text: data['name']?.toString() ?? '');
    final phone = TextEditingController(text: data['phone']?.toString() ?? '');
    final sector = TextEditingController(text: profile['sector']?.toString() ?? '');
    final size = TextEditingController(text: profile['size']?.toString() ?? '');
    final address = TextEditingController(text: profile['address']?.toString() ?? '');
    final website = TextEditingController(text: profile['website']?.toString() ?? '');
    final description = TextEditingController(text: profile['description']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Completar perfil de empresa'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                F(name, 'Nombre de la empresa'),
                F(phone, 'Teléfono de contacto', type: TextInputType.phone),
                F(sector, 'Sector'),
                F(size, 'Tamaño de la empresa (ej. 11-50 empleados)'),
                F(address, 'Dirección'),
                F(website, 'Sitio web', type: TextInputType.url),
                F(description, 'Descripción de la empresa', max: 4),
                const SizedBox(height: 4),
                const Text(
                  'Estos datos se guardarán en tu perfil y podrás modificarlos después.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) {
                toast('El nombre de la empresa es obligatorio.');
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );

    if (ok != true) {
      for (final controller in [name, phone, sector, size, address, website, description]) {
        controller.dispose();
      }
      return;
    }

    setState(() => savingProfile = true);
    try {
      final updated = await api.updateProfile(widget.token, {
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'companyProfile': {
          'sector': sector.text.trim(),
          'size': size.text.trim(),
          'address': address.text.trim(),
          'website': website.text.trim(),
          'description': description.text.trim(),
        },
      });
      if (mounted) {
        setState(() => user = updated);
        if (sessionUser != null) sessionUser = {...sessionUser!, ...updated};
      }
      toast('Perfil de empresa guardado correctamente.');
    } catch (e) {
      toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      for (final controller in [name, phone, sector, size, address, website, description]) {
        controller.dispose();
      }
      if (mounted) setState(() => savingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && user == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && user == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Info('No se pudo cargar el perfil de empresa', error!),
          OutlinedButton.icon(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    final data = user ?? <String, dynamic>{};
    final profile = companyProfile;
    final email = data['email']?.toString() ?? '';
    final completionFields = [
      data['name'], data['email'], data['ruc'], data['phone'],
      profile['sector'], profile['size'], profile['address'],
      profile['website'], profile['description'],
    ];
    final completeCount = completionFields.where((value) => value != null && value.toString().trim().isNotEmpty).length;
    final completion = completeCount / completionFields.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8F7FF), Color(0xFFF0EDFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFEDE9FE),
                backgroundImage: profilePhotoBytes == null ? null : MemoryImage(profilePhotoBytes!),
                child: profilePhotoBytes == null ? const Icon(Icons.business_outlined, color: primary, size: 33) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showValue(data['name']),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF211B43)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (profile['sector']?.toString().trim().isNotEmpty ?? false) ? profile['sector'].toString() : 'Perfil de empresa',
                      style: const TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar perfil',
                onPressed: loading ? null : load,
                icon: const Icon(Icons.refresh, color: primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: uploadingPhoto ? null : uploadProfilePhoto,
          icon: uploadingPhoto
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add_a_photo_outlined),
          label: Text(uploadingPhoto ? 'Subiendo foto...' : profilePhotoBytes == null ? 'Subir foto de perfil' : 'Cambiar foto de perfil'),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: Text('Completitud del perfil', style: TextStyle(fontWeight: FontWeight.w800))),
                  Text('${(completion * 100).round()}%', style: const TextStyle(color: primary, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: completion, minHeight: 8, backgroundColor: line, color: primary),
              ),
              const SizedBox(height: 10),
              Text(
                completion >= 1 ? '¡Perfil completo! Tu empresa ya cuenta con la información principal.' : 'Completa los datos de tu empresa para que los candidatos conozcan mejor tu organización.',
                style: const TextStyle(color: muted, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: savingProfile ? null : editCompanyProfile,
                  icon: savingProfile ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.edit_outlined),
                  label: Text(savingProfile ? 'Guardando...' : 'Editar información de empresa'),
                  style: FilledButton.styleFrom(backgroundColor: primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Section('Datos registrados'),
        _ProfileValue(icon: Icons.email_outlined, label: 'Correo institucional', value: showValue(email)),
        _ProfileValue(icon: Icons.business_outlined, label: 'RUC', value: showValue(data['ruc'])),
        _ProfileValue(icon: Icons.phone_outlined, label: 'Teléfono', value: showValue(data['phone'])),
        const SizedBox(height: 12),
        const Section('Información de la empresa'),
        _ProfileValue(icon: Icons.category_outlined, label: 'Sector', value: showValue(profile['sector'])),
        _ProfileValue(icon: Icons.groups_outlined, label: 'Tamaño', value: showValue(profile['size'])),
        _ProfileValue(icon: Icons.location_on_outlined, label: 'Dirección', value: showValue(profile['address'])),
        _ProfileValue(icon: Icons.language_outlined, label: 'Sitio web', value: showValue(profile['website'])),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Descripción', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                profile['description']?.toString().trim().isNotEmpty == true ? profile['description'].toString() : 'Añade una descripción para presentar tu empresa y su compromiso con la inclusión laboral.',
                style: TextStyle(color: profile['description']?.toString().trim().isNotEmpty == true ? ink : muted, height: 1.4),
              ),
            ],
          ),
        ),
        if (loading) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator(minHeight: 2)),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        const Section('Privacidad y cuenta'),
        const Text('Puedes eliminar la cuenta empresarial y sus datos asociados.', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 8),
        DeleteAccountButton(token: widget.token),
      ],
    );
  }
}

void showOffer(
  BuildContext c,
  dynamic d,
  Future<void> Function(String) apply,
) {
  final requiredSkills = d['requiredSkills'] is List
      ? (d['requiredSkills'] as List).map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList()
      : <String>[];
  final preferredSkills = d['preferredSkills'] is List
      ? (d['preferredSkills'] as List).map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList()
      : <String>[];
  final accessibility = d['accessibilityDetails']?.toString().trim() ?? '';
  final company = d['companyId'] is Map
      ? (d['companyId']['name']?.toString() ?? 'Empresa')
      : 'Empresa';
  final years = (d['experienceRequired'] as num?)?.toInt() ?? 0;
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.88,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              d['title']?.toString() ?? 'Oferta',
              style: const TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(company, style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if ((d['category']?.toString() ?? '').trim().isNotEmpty)
                  Chip(avatar: const Icon(Icons.work_outline, size: 17), label: Text(d['category'].toString())),
                if ((d['location']?.toString() ?? '').trim().isNotEmpty)
                  Chip(avatar: const Icon(Icons.location_on_outlined, size: 17), label: Text(d['location'].toString())),
                if ((d['modality']?.toString() ?? '').trim().isNotEmpty)
                  Chip(avatar: const Icon(Icons.laptop_mac_outlined, size: 17), label: Text(d['modality'].toString())),
                if ((d['contractType']?.toString() ?? '').trim().isNotEmpty)
                  Chip(avatar: const Icon(Icons.description_outlined, size: 17), label: Text(d['contractType'].toString())),
                Chip(
                  avatar: const Icon(Icons.work_history_outlined, size: 17),
                  label: Text(years == 0 ? 'Sin experiencia mínima' : '$years año(s) de experiencia'),
                ),
                if ((d['salary']?.toString() ?? '').trim().isNotEmpty)
                  Chip(avatar: const Icon(Icons.payments_outlined, size: 17), label: Text(d['salary'].toString())),
              ],
            ),
            const SizedBox(height: 16),
            const Section('Sobre el puesto'),
            Text(d['description']?.toString() ?? 'La empresa no ha añadido una descripción.'),
            const SizedBox(height: 18),
            const Section('Habilidades requeridas'),
            if (requiredSkills.isEmpty)
              const Text('La empresa todavía no especifica habilidades concretas.', style: TextStyle(color: muted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: requiredSkills.map((skill) => Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 17),
                  label: Text(skill),
                  backgroundColor: const Color(0xFFF0EDFF),
                )).toList(),
              ),
            if (preferredSkills.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Section('Habilidades deseables'),
              const Text('Son habilidades valoradas, pero no deberían tratarse como requisitos obligatorios.', style: TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: preferredSkills.map((skill) => Chip(
                  avatar: const Icon(Icons.star_outline_rounded, size: 17),
                  label: Text(skill),
                  backgroundColor: const Color(0xFFF7F5FF),
                )).toList(),
              ),
            ],
            const SizedBox(height: 18),
            const Section('Accesibilidad del puesto'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: Text(
                accessibility.isNotEmpty
                    ? accessibility
                    : 'La empresa no ha detallado los ajustes o condiciones de accesibilidad. Puedes solicitar más información antes de continuar.',
                style: TextStyle(color: accessibility.isNotEmpty ? ink : muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            Btn('Postular ahora', () => apply((d['_id'] ?? d['id'] ?? '').toString())),
            const SizedBox(height: 8),
            Out('Cerrar detalles', () => Navigator.pop(sheetContext)),
          ],
        ),
      ),
    ),
  );
}
class Shell extends StatelessWidget {
  final String title, sub;
  final Widget child;
  const Shell({
    super.key,
    required this.title,
    required this.sub,
    required this.child,
  });

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: const Text('INKLU',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: ink)),
                const SizedBox(height: 8),
                Text(sub, style: const TextStyle(color: muted)),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      );
}
class EmailVerificationBanner extends StatefulWidget {
  final String token;
  const EmailVerificationBanner({super.key, required this.token});

  @override
  State<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool sending = false;
  bool verified = false;

  Future<void> checkOrSendVerification() async {
    if (sending) return;
    setState(() => sending = true);
    try {
      // Reconsulta el perfil para reconocer un enlace que ya se abrió en el navegador.
      final currentProfile = await api.profile(widget.token);
      final merged = Map<String, dynamic>.from(sessionUser ?? <String, dynamic>{});
      merged.addAll(currentProfile);
      sessionUser = merged;
      if (currentProfile['emailVerified'] == true) {
        if (mounted) setState(() => verified = true);
        toast('Tu correo ya está verificado.');
        return;
      }

      final response = await api.requestEmailVerification(widget.token);
      toast(response['message']?.toString() ??
          'Si el envío está configurado, recibirás un enlace de verificación.');
    } catch (error) {
      toast(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (verified) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mark_email_unread_outlined, color: Color(0xFF92400E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verifica tu correo electrónico',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirma que la dirección de tu cuenta te pertenece. El enlace se enviará cuando el servicio de correo de INKLU esté configurado.',
            style: TextStyle(color: Color(0xFF78350F), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: sending ? null : checkOrSendVerification,
            icon: sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.mark_email_read_outlined),
            label: Text(sending ? 'Comprobando...' : 'Verificar / reenviar correo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF92400E),
              side: const BorderSide(color: Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsAction extends StatefulWidget {
  const NotificationsAction({super.key});

  @override
  State<NotificationsAction> createState() => _NotificationsActionState();
}

class _NotificationsActionState extends State<NotificationsAction> {
  int unreadCount = 0;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    refreshUnreadCount();
  }

  Future<void> refreshUnreadCount() async {
    final token = sessionToken;
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => unreadCount = 0);
      return;
    }

    if (mounted) setState(() => loading = true);
    try {
      final items = await api.notifications(token);
      final count = items.where((item) => item is Map && item['read'] != true).length;
      if (mounted) setState(() => unreadCount = count);
    } catch (_) {
      // A temporary notification failure should not block the rest of the dashboard.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openNotifications() async {
    await showNotifications(context);
    await refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final label = unreadCount == 0
        ? 'Notificaciones'
        : 'Notificaciones, $unreadCount sin leer';
    return IconButton(
      tooltip: label,
      onPressed: openNotifications,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
        child: const Icon(Icons.notifications_active_outlined, color: primary),
      ),
    );
  }
}

class Dash extends StatelessWidget {
  final String title;
  final int tab;
  final ValueChanged<int> onTab;
  final List<Widget> children;
  final List<String> labels;

  const Dash({super.key, required this.title, required this.tab, required this.onTab, required this.children, this.labels = const ['Inicio', 'Ofertas', 'Postulaciones', 'Perfil']});

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: const Color(0xFFFAF9FF),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAF9FF),
      surfaceTintColor: Colors.transparent,
      title: Row(children: [
        const Logo(size: 34),
        const SizedBox(width: 6),
        const Text('INKLU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF19162D))),
      ]),
      actions: [
        IconButton(
          tooltip: 'Accesibilidad y tamaño del texto',
          onPressed: () => showAccessibilitySettings(c),
          icon: const Icon(Icons.accessibility_new_rounded, color: primary),
        ),
        const NotificationsAction(),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () => confirmLogout(c),
          icon: const Icon(Icons.logout_rounded, color: primary),
        ),
        const SizedBox(width: 4),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 24),
      children: [
        Align(
          alignment: tab == 2 ? Alignment.center : Alignment.centerLeft,
          child: Text(
            title,
            textAlign: tab == 2 ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontSize: 25,
              height: 1.22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF19162D),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (sessionUser?['emailVerified'] == false && sessionToken != null)
          EmailVerificationBanner(token: sessionToken!),
        ...children,
      ],
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: const Color(0xFFF0EDFF),
      indicatorColor: const Color(0xFFDCD4FF),
      selectedIndex: tab,
      onDestinationSelected: onTab,
      destinations: [
        NavigationDestination(icon: const Icon(Icons.home_outlined), label: labels[0]),
        NavigationDestination(icon: const Icon(Icons.business_center_outlined), label: labels[1]),
        NavigationDestination(icon: const Icon(Icons.people_outline), label: labels[2]),
        NavigationDestination(icon: const Icon(Icons.person_outline), label: labels[3]),
      ],
    ),
  );
}

class F extends StatelessWidget{final TextEditingController c;final String label;final bool obscure,read;final TextInputType? type;final int max;final List<TextInputFormatter>? format;final VoidCallback? onTap;final Widget? suffix;const F(this.c,this.label,{super.key,this.obscure=false,this.read=false,this.type,this.max=1,this.format,this.onTap,this.suffix});@override Widget build(BuildContext cxt)=>Padding(padding:const EdgeInsets.only(bottom:11),child:TextField(controller:c,obscureText:obscure,readOnly:read,keyboardType:type,maxLines:obscure?1:max,inputFormatters:format,onTap:onTap,decoration:InputDecoration(labelText:label,suffixIcon:suffix)));}
class Btn extends StatelessWidget{final String text;final VoidCallback? on;const Btn(this.text,this.on,{super.key});@override Widget build(BuildContext c)=>SizedBox(width:double.infinity,height:48,child:FilledButton(onPressed:on,style:FilledButton.styleFrom(backgroundColor:primary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),child:Text(text,style:const TextStyle(fontWeight:FontWeight.w700))));}
class Out extends StatelessWidget{final String text;final VoidCallback on;const Out(this.text,this.on,{super.key});@override Widget build(BuildContext c)=>SizedBox(width:double.infinity,height:46,child:OutlinedButton(onPressed:on,child:Text(text)));}
class CardRole extends StatelessWidget{final String title,sub;final IconData icon;final VoidCallback on;const CardRole(this.title,this.sub,this.icon,this.on,{super.key});@override Widget build(BuildContext c)=>InkWell(onTap:on,borderRadius:BorderRadius.circular(14),child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(14)),child:Row(children:[CircleAvatar(radius:28,backgroundColor:const Color(0xFFEDE9FE),child:Icon(icon,color:primary,size:30)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17)),Text(sub,style:const TextStyle(color:muted,fontSize:12))])),const Icon(Icons.arrow_forward_ios,color:primary,size:16)])));}
class Dots extends StatelessWidget{final int i;const Dots(this.i,{super.key});@override Widget build(BuildContext c)=>Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(3,(x)=>Container(width:x==i?8:6,height:x==i?8:6,margin:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,color:x==i?primary:line))));}
class JobCard extends StatelessWidget {
  final dynamic j;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onSave;

  const JobCard(this.j, {super.key, this.onTap, this.isSaved = false, this.onSave});

  @override
  Widget build(BuildContext c) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: line)),
    child: ListTile(
      onTap: onTap,
      title: Text(j['title']?.toString() ?? 'Oferta', style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('${j['companyId'] is Map ? (j['companyId']['name'] ?? 'Empresa') : 'Empresa'}\n${j['location'] ?? ''} · ${j['modality'] ?? ''}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onSave != null)
            IconButton(
              tooltip: isSaved ? 'Quitar de ofertas guardadas' : 'Guardar oferta',
              onPressed: onSave,
              icon: Icon(isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: primary),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}
class ProfileCard extends StatelessWidget{const ProfileCard({super.key});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(14)),child:const Row(children:[CircleAvatar(radius:27,child:Icon(Icons.person)),SizedBox(width:12),Expanded(child:Text('Tu perfil\nCompleta tu perfil para recibir mejores recomendaciones.',style:TextStyle(fontWeight:FontWeight.w700)))]));}
class Section extends StatelessWidget{final String s;const Section(this.s,{super.key});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:9),child:Text(s,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)));}
class Info extends StatelessWidget{final String a,b;const Info(this.a,this.b,{super.key});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(b,style:const TextStyle(color:muted))]));}
List<TextInputFormatter> digits(int n)=>[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(n)];bool validEmail(String s)=>RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());bool validPass(String s)=>s.length>=8&&RegExp(r'[A-Z]').hasMatch(s)&&RegExp(r'[a-z]').hasMatch(s)&&RegExp(r'[0-9]').hasMatch(s)&&RegExp(r'[^A-Za-z0-9]').hasMatch(s);
