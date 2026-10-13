import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
            !RegExp(r'^\d{11}).hasMatch(ruc.text) ||
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
class _CandidateHomeState extends State<CandidateHome>{int tab=0;List<dynamic> jobs=[];List<dynamic> apps=[];@override void initState(){super.initState();load();}Future<void> load()async{try{final t=sessionToken!;jobs=await api.jobs(t);apps=await api.applications(t);if(mounted)setState((){});}catch(x){if(mounted)toast(x.toString().replaceFirst('Exception: ',''));}}Future<void> apply(String id)async{try{await api.apply(sessionToken!,id);toast('Postulación enviada correctamente.');load();}catch(x){toast(x.toString().replaceFirst('Exception: ',''));}}@override Widget build(BuildContext c)=>Dash(title:'Hola, ${sessionUser?['name']??'candidato'}',tab:tab,onTab:(x)=>setState(()=>tab=x),children:tab==0?[const Text('Encuentra oportunidades laborales inclusivas.',style:TextStyle(color:muted)),const SizedBox(height:16),const ProfileCard(),const SizedBox(height:20),const Section('Ofertas para ti'),...jobs.take(5).map((j)=>JobCard(j,onTap:()=>showOffer(c,j,apply)))] :tab==1?[const Section('Ofertas disponibles'),...jobs.map((j)=>JobCard(j,onTap:()=>showOffer(c,j,apply)))] :tab==2?[const Section('Mis postulaciones'),...apps.map((x)=>ListTile(title:Text(x['jobId']?['title']?.toString()??'Oferta'),subtitle:Text(x['status']?.toString()??'Postulada')))] :[const Info('Tu perfil','Tu cuenta está conectada al backend de INKLU.')]);}
class CompanyHome extends StatefulWidget{const CompanyHome({super.key});@override State<CompanyHome> createState()=>_CompanyHomeState();}
class _CompanyHomeState extends State<CompanyHome>{int tab=0;List<dynamic> mine=[];List<dynamic> apps=[];@override void initState(){super.initState();load();}Future<void> load()async{try{mine=await api.myJobs(sessionToken!);apps=await api.applications(sessionToken!);if(mounted)setState((){});}catch(x){if(mounted)toast(x.toString().replaceFirst('Exception: ',''));}}Future<void> create()async{final t=TextEditingController(),d=TextEditingController(),l=TextEditingController(text:'Lima, Perú');final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Nueva oferta laboral'),content:SingleChildScrollView(child:Column(children:[F(t,'Título del puesto'),F(d,'Descripción',max:5),F(l,'Ubicación')])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Publicar'))]));if(ok==true&&t.text.trim().isNotEmpty&&d.text.trim().isNotEmpty){try{await api.createJob(sessionToken!,{'title':t.text.trim(),'description':d.text.trim(),'location':l.text.trim(),'modality':'Remoto','contractType':'Tiempo completo'});toast('Oferta publicada correctamente.');load();}catch(x){toast(x.toString().replaceFirst('Exception: ',''));}}}@override Widget build(BuildContext c)=>Dash(title:'Hola, ${sessionUser?['name']??'empresa'}',tab:tab,onTab:(x)=>setState(()=>tab=x),labels:const['Inicio','Ofertas','Candidatos','Perfil'],children:tab==0?[const Text('Gestiona tus ofertas y conecta con talento diverso.',style:TextStyle(color:muted)),const SizedBox(height:16),Btn('+ Crear nueva oferta',create),const SizedBox(height:20),const Section('Mis ofertas'),...mine.map((j)=>JobCard(j))] :tab==1?[Btn('+ Crear oferta',create),...mine.map((j)=>JobCard(j))]:tab==2?[const Section('Postulaciones'),...apps.map((x)=>ListTile(title:Text(x['candidateId']?['name']?.toString()??'Candidato'),subtitle:Text(x['jobId']?['title']?.toString()??'Oferta')))] :[const Info('Perfil de empresa','Información conectada a INKLU API.')]);}
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

  const Dash({
    super.key,
    required this.title,
    required this.tab,
    required this.onTab,
    required this.children,
    this.labels = const ['Inicio', 'Ofertas', 'Postulaciones', 'Perfil'],
  });

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Logo(size: 34),
              const SizedBox(width: 6),
              const Text('INKLU',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            ...children,
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: onTab,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined), label: labels[0]),
            NavigationDestination(
                icon: const Icon(Icons.business_center_outlined),
                label: labels[1]),
            NavigationDestination(
                icon: const Icon(Icons.people_outline), label: labels[2]),
            NavigationDestination(
                icon: const Icon(Icons.person_outline), label: labels[3]),
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
).hasMatch(ruc.text) ||
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
class _CandidateHomeState extends State<CandidateHome>{int tab=0;List<dynamic> jobs=[];List<dynamic> apps=[];@override void initState(){super.initState();load();}Future<void> load()async{try{final t=sessionToken!;jobs=await api.jobs(t);apps=await api.applications(t);if(mounted)setState((){});}catch(x){if(mounted)toast(x.toString().replaceFirst('Exception: ',''));}}Future<void> apply(String id)async{try{await api.apply(sessionToken!,id);toast('Postulación enviada correctamente.');load();}catch(x){toast(x.toString().replaceFirst('Exception: ',''));}}@override Widget build(BuildContext c)=>Dash(title:'Hola, ${sessionUser?['name']??'candidato'}',tab:tab,onTab:(x)=>setState(()=>tab=x),children:tab==0?[const Text('Encuentra oportunidades laborales inclusivas.',style:TextStyle(color:muted)),const SizedBox(height:16),const ProfileCard(),const SizedBox(height:20),const Section('Ofertas para ti'),...jobs.take(5).map((j)=>JobCard(j,onTap:()=>showOffer(c,j,apply)))] :tab==1?[const Section('Ofertas disponibles'),...jobs.map((j)=>JobCard(j,onTap:()=>showOffer(c,j,apply)))] :tab==2?[const Section('Mis postulaciones'),...apps.map((x)=>ListTile(title:Text(x['jobId']?['title']?.toString()??'Oferta'),subtitle:Text(x['status']?.toString()??'Postulada')))] :[const Info('Tu perfil','Tu cuenta está conectada al backend de INKLU.')]);}
class CompanyHome extends StatefulWidget{const CompanyHome({super.key});@override State<CompanyHome> createState()=>_CompanyHomeState();}
class _CompanyHomeState extends State<CompanyHome>{int tab=0;List<dynamic> mine=[];List<dynamic> apps=[];@override void initState(){super.initState();load();}Future<void> load()async{try{mine=await api.myJobs(sessionToken!);apps=await api.applications(sessionToken!);if(mounted)setState((){});}catch(x){if(mounted)toast(x.toString().replaceFirst('Exception: ',''));}}Future<void> create()async{final t=TextEditingController(),d=TextEditingController(),l=TextEditingController(text:'Lima, Perú');final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Nueva oferta laboral'),content:SingleChildScrollView(child:Column(children:[F(t,'Título del puesto'),F(d,'Descripción',max:5),F(l,'Ubicación')])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Publicar'))]));if(ok==true&&t.text.trim().isNotEmpty&&d.text.trim().isNotEmpty){try{await api.createJob(sessionToken!,{'title':t.text.trim(),'description':d.text.trim(),'location':l.text.trim(),'modality':'Remoto','contractType':'Tiempo completo'});toast('Oferta publicada correctamente.');load();}catch(x){toast(x.toString().replaceFirst('Exception: ',''));}}}@override Widget build(BuildContext c)=>Dash(title:'Hola, ${sessionUser?['name']??'empresa'}',tab:tab,onTab:(x)=>setState(()=>tab=x),labels:const['Inicio','Ofertas','Candidatos','Perfil'],children:tab==0?[const Text('Gestiona tus ofertas y conecta con talento diverso.',style:TextStyle(color:muted)),const SizedBox(height:16),Btn('+ Crear nueva oferta',create),const SizedBox(height:20),const Section('Mis ofertas'),...mine.map((j)=>JobCard(j))] :tab==1?[Btn('+ Crear oferta',create),...mine.map((j)=>JobCard(j))]:tab==2?[const Section('Postulaciones'),...apps.map((x)=>ListTile(title:Text(x['candidateId']?['name']?.toString()??'Candidato'),subtitle:Text(x['jobId']?['title']?.toString()??'Oferta')))] :[const Info('Perfil de empresa','Información conectada a INKLU API.')]);}
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

  const Dash({
    super.key,
    required this.title,
    required this.tab,
    required this.onTab,
    required this.children,
    this.labels = const ['Inicio', 'Ofertas', 'Postulaciones', 'Perfil'],
  });

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Logo(size: 34),
              const SizedBox(width: 6),
              const Text('INKLU',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            ...children,
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: onTab,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined), label: labels[0]),
            NavigationDestination(
                icon: const Icon(Icons.business_center_outlined),
                label: labels[1]),
            NavigationDestination(
                icon: const Icon(Icons.people_outline), label: labels[2]),
            NavigationDestination(
                icon: const Icon(Icons.person_outline), label: labels[3]),
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
