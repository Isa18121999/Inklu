import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'services/api_service.dart';

const primary=Color(0xFF4F46E5), ink=Color(0xFF111827), muted=Color(0xFF64748B), line=Color(0xFFE2E8F0);
final api=ApiService(); String? sessionToken; Map<String,dynamic>? sessionUser;
void main() async{WidgetsFlutterBinding.ensureInitialized();await SystemChrome.setPreferredOrientations(const[DeviceOrientation.portraitUp,DeviceOrientation.portraitDown]);runApp(const InkluApp());}
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
class InkluApp extends StatelessWidget{const InkluApp({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,navigatorKey:_nav,title:'INKLU',theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:Colors.white,colorScheme:ColorScheme.fromSeed(seedColor:primary)),home:const Welcome());}
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
                ],
              ),
            ),
          ),
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
                value: sector,
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

  @override
  Widget build(BuildContext c) => Shell(
        title: 'Iniciar sesión',
        sub: 'Bienvenido de nuevo a INKLU.',
        child: Column(
          children: [
            F(e, 'Correo electrónico', type: TextInputType.emailAddress),
            F(p, 'Contraseña', obscure: true),
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
  List<dynamic> cvSkills = [];
  bool scanningRecommendations = false;
  String? recommendationMessage;
  String selectedApplicationFilter = 'Todas';
  final TextEditingController jobSearchController = TextEditingController();
  String? selectedLocationFilter;
  String? selectedModalityFilter;
  String? selectedContractFilter;
  String? selectedCategoryFilter;
  bool searchingJobs = false;
  bool filtersExpanded = false;
  static const applicationFilters = ['Todas', 'Postulado', 'CV Visto', 'En proceso', 'Aceptado', 'Proceso terminado'];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final results = await Future.wait([api.jobs(sessionToken!), api.applications(sessionToken!)]);
      if (!mounted) return;
      setState(() { jobs = results[0]; apps = results[1]; });
    } catch (x) {
      if (mounted) toast(x.toString().replaceFirst('Exception: ', ''));
    }
  }

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
      if (!mounted) return;
      setState(() {
        cvSkills = (analysis['skills'] as List?) ?? [];
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
              const Text('Analiza el texto de tu CV y compáralo con las ofertas publicadas.', style: TextStyle(color: muted, fontSize: 12)),
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
                ...recommendations.map((j) => JobRecommendationCard(job: Map<String, dynamic>.from(j), onTap: () => showOffer(c, j, apply)))
              else ...[
                const Section('Ofertas recientes'),
                if (jobs.isEmpty)
                  const Info('Todavía no hay ofertas', 'Vuelve a revisar pronto.')
                else
                  ...jobs.take(3).map((j) => JobCard(j, onTap: () => showOffer(c, j, apply))),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Text('Ofertas disponibles', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink))),
                      Text('${jobs.length} resultado${jobs.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (searchingJobs)
                    const Padding(
                      padding: EdgeInsets.all(25),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (jobs.isEmpty)
                    const Info(
                      'No encontramos ofertas con esos filtros',
                      'Prueba otra palabra o limpia alguno de los filtros para ver más oportunidades.',
                    )
                  else
                    ...jobs.map((job) => JobCard(job, onTap: () => showOffer(c, job, apply))),
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

  const JobRecommendationCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = (job['matchScore'] as num?)?.round() ?? 0;
    final rawReasons = job['matchReasons'];
    final reasons = rawReasons is List
        ? rawReasons.map((item) => item.toString()).toList()
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
                '$score% de coincidencia',
                style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (reasons.isNotEmpty)
                Text(
                  reasons.take(2).join(' · '),
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: primary),
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
              InkWell(
                borderRadius: BorderRadius.circular(22),
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
                child: Container(width: 31, height: 31,
                  decoration: BoxDecoration(color: completed ? primary : Colors.white, shape: BoxShape.circle, border: Border.all(color: active ? primary : color, width: active ? 2.3 : 1.5)),
                  alignment: Alignment.center,
                  child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: completed ? Colors.white : active ? primary : const Color(0xFF77728D))),
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
                if (selectedLocation == null || selectedModality == null) {
                  toast('Selecciona tu ubicación y modalidad laboral.');
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

  Future<void> create() async {
    final title = TextEditingController();
    final description = TextEditingController();
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
                F(description, 'Descripción', max: 5),
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
        });
        toast('Oferta publicada correctamente.');
        await load();
      } catch (x) {
        toast(x.toString().replaceFirst('Exception: ', ''));
      }
    }
    title.dispose();
    description.dispose();
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
                          'Actualiza cada etapa para que la persona candidata pueda seguir el proceso. El chat se habilita en “En proceso”.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
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
                        else
                          ...apps.map((a) => CompanyApplicationCard(
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
    final candidate = application['candidateId'] is Map
        ? application['candidateId']['name']?.toString() ?? 'Candidato'
        : 'Candidato';
    final job = application['jobId'] is Map
        ? Map<String, dynamic>.from(application['jobId'])
        : <String, dynamic>{};
    final appId = (application['_id'] ?? application['id'] ?? '').toString();
    final jobTitle = job['title']?.toString() ?? 'Oferta';
    const stages = ['Postulado', 'CV visto', 'En proceso', 'Aceptado', 'Proceso terminado'];

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
            const SizedBox(height: 12),
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
      ],
    );
  }
}

void showOffer(
  BuildContext c,
  dynamic d,
  Future<void> Function(String) apply,
) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d['title']?.toString() ?? 'Oferta',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            d['companyId']?['name']?.toString() ?? 'Empresa',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 14),
          Text(d['description']?.toString() ?? ''),
          const SizedBox(height: 18),
          Btn('Postular ahora', () => apply(d['_id'].toString())),
        ],
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
class JobCard extends StatelessWidget{final dynamic j;final VoidCallback? onTap;const JobCard(this.j,{super.key,this.onTap});@override Widget build(BuildContext c)=>Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12),side:const BorderSide(color:line)),child:ListTile(onTap:onTap,title:Text(j['title']?.toString()??'Oferta',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${j['companyId']?['name']?.toString()??'Empresa'}\n${j['location']??''} · ${j['modality']??''}'),trailing:const Icon(Icons.chevron_right)));}
class ProfileCard extends StatelessWidget{const ProfileCard({super.key});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(14)),child:const Row(children:[CircleAvatar(radius:27,child:Icon(Icons.person)),SizedBox(width:12),Expanded(child:Text('Tu perfil\nCompleta tu perfil para recibir mejores recomendaciones.',style:TextStyle(fontWeight:FontWeight.w700)))]));}
class Section extends StatelessWidget{final String s;const Section(this.s,{super.key});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:9),child:Text(s,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)));}
class Info extends StatelessWidget{final String a,b;const Info(this.a,this.b,{super.key});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(b,style:const TextStyle(color:muted))]));}
List<TextInputFormatter> digits(int n)=>[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(n)];bool validEmail(String s)=>RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());bool validPass(String s)=>s.length>=8&&RegExp(r'[A-Z]').hasMatch(s)&&RegExp(r'[a-z]').hasMatch(s)&&RegExp(r'[0-9]').hasMatch(s)&&RegExp(r'[^A-Za-z0-9]').hasMatch(s);
