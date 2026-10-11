import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'INKLU',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF5B3CC4)),
    home: const WelcomeView(),
  );
}

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.diversity_3, size: 92, color: Color(0xFF5B3CC4)),
      const SizedBox(height: 18),
      const Text('INKLU', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Talento, inclusión y oportunidades laborales', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
      const SizedBox(height: 32),
      FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleView())), child: const Text('Empezar')),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginView())), child: const Text('Iniciar sesión')),
    ]))),
  );
}

class RoleView extends StatelessWidget {
  const RoleView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('¿Cómo quieres participar?')), body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
    _role(context, 'Soy candidato', Icons.person_outline, const CandidateRegisterView()),
    const SizedBox(height: 16),
    _role(context, 'Soy empresa', Icons.business_outlined, const CompanyRegisterView()),
  ]));
  Widget _role(BuildContext c, String text, IconData icon, Widget page) => Card(child: ListTile(contentPadding: const EdgeInsets.all(18), leading: Icon(icon, size: 34), title: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page))));
}

class CandidateRegisterView extends StatefulWidget { const CandidateRegisterView({super.key}); @override State<CandidateRegisterView> createState() => _CandidateRegisterState(); }
class _CandidateRegisterState extends State<CandidateRegisterView> {
  final name=TextEditingController(), email=TextEditingController(), phone=TextEditingController(), password=TextEditingController(), conadis=TextEditingController();
  bool loading=false;
  Future<void> submit() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.length < 8 || !RegExp(r'^[A-Za-z0-9-]{5,30}$').hasMatch(conadis.text.trim())) { _msg('Completa todos los campos y verifica el número de CONADIS.'); return; }
    setState(() => loading=true);
    try { await ApiService.registerCandidate(name: name.text.trim(), email: email.text.trim(), phone: phone.text.trim(), password: password.text, conadis: conadis.text.trim()); if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView())); }
    catch(e) { _msg(e.toString().replaceFirst('Exception: ', '')); } finally { if(mounted) setState(()=>loading=false); }
  }
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override Widget build(BuildContext context)=>Scaffold(appBar: AppBar(title: const Text('Registro candidato')), body: ListView(padding: const EdgeInsets.all(24), children: [
    const Text('1 de 3', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 16),
    _field('Nombre completo *', name), _field('Correo electrónico *', email, type: TextInputType.emailAddress), _field('Teléfono', phone, type: TextInputType.phone), _field('Contraseña *', password, obscure:true),
    const SizedBox(height: 8), _field('Número de CONADIS *', conadis),
    const Text('El número de CONADIS es obligatorio y debe ser válido.', style: TextStyle(color: Colors.grey)), const SizedBox(height: 24),
    FilledButton(onPressed: loading ? null : submit, child: Text(loading ? 'Registrando...' : 'Crear cuenta')),
  ]));
}

class CompanyRegisterView extends StatefulWidget { const CompanyRegisterView({super.key}); @override State<CompanyRegisterView> createState()=>_CompanyRegisterState(); }
class _CompanyRegisterState extends State<CompanyRegisterView>{
  final name=TextEditingController(), email=TextEditingController(), phone=TextEditingController(), ruc=TextEditingController(), password=TextEditingController(); bool loading=false;
  Future<void> submit() async { if(name.text.trim().isEmpty||email.text.trim().isEmpty||password.text.length<8||ruc.text.trim().isEmpty){_msg('Completa los campos obligatorios.');return;} setState(()=>loading=true); try{await ApiService.registerCompany(name:name.text.trim(),email:email.text.trim(),phone:phone.text.trim(),password:password.text,ruc:ruc.text.trim());if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const LoginView()));}catch(e){_msg(e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>loading=false);}}
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Registro empresa')),body:ListView(padding:const EdgeInsets.all(24),children:[const Text('1 de 3',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:16),_field('Nombre de empresa *',name),_field('Correo electrónico *',email,type:TextInputType.emailAddress),_field('Teléfono',phone,type:TextInputType.phone),_field('RUC *',ruc,type:TextInputType.number),_field('Contraseña *',password,obscure:true),const SizedBox(height:24),FilledButton(onPressed:loading?null:submit,child:Text(loading?'Registrando...':'Crear cuenta'))]));
}

class LoginView extends StatefulWidget { const LoginView({super.key}); @override State<LoginView> createState()=>_LoginState(); }
class _LoginState extends State<LoginView>{final email=TextEditingController(),password=TextEditingController();bool loading=false;Future<void>login()async{setState(()=>loading=true);try{final r=await ApiService.login(email:email.text.trim(),password:password.text);if(!mounted)return;final role=r['user']['role'];Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>role=='company'?const CompanyHomeView():const CandidateHomeView()));}catch(e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Iniciar sesión')),body:ListView(padding:const EdgeInsets.all(24),children:[_field('Correo electrónico',email,type:TextInputType.emailAddress),_field('Contraseña',password,obscure:true),const SizedBox(height:20),FilledButton(onPressed:loading?null:login,child:Text(loading?'Ingresando...':'Ingresar'))]));}

class CandidateHomeView extends StatelessWidget{const CandidateHomeView({super.key});@override Widget build(BuildContext context)=>_Home(title:'Hola, candidato 👋',children:[const Text('Encuentra oportunidades que se ajusten a tu perfil.',style:TextStyle(fontSize:17)),const SizedBox(height:18),TextField(decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Buscar empleos',border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)))),const SizedBox(height:18),const Card(child:ListTile(title:Text('Completa tu perfil'),subtitle:Text('Mejora tus coincidencias con empresas.'),trailing:Icon(Icons.arrow_forward_ios))),const SizedBox(height:12),const Text('Empleos recomendados',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Card(child:ListTile(title:Text('Analista de datos'),subtitle:Text('Remoto · Tiempo completo'),trailing:Icon(Icons.chevron_right))),const Card(child:ListTile(title:Text('Desarrollador Flutter'),subtitle:Text('Híbrido · Lima'),trailing:Icon(Icons.chevron_right))) ]);}
class CompanyHomeView extends StatelessWidget{const CompanyHomeView({super.key});@override Widget build(BuildContext context)=>_Home(title:'Hola, empresa 👋',children:[const Text('Gestiona tus oportunidades y candidatos.',style:TextStyle(fontSize:17)),const SizedBox(height:18),const Row(children:[Expanded(child:Card(child:ListTile(title:Text('3'),subtitle:Text('Ofertas')))),SizedBox(width:10),Expanded(child:Card(child:ListTile(title:Text('12'),subtitle:Text('Postulaciones'))))]),const SizedBox(height:12),FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CreateJobView())),icon:const Icon(Icons.add),label:const Text('Crear oferta')),const SizedBox(height:18),const Text('Ofertas recientes',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const Card(child:ListTile(title:Text('Desarrollador Flutter'),subtitle:Text('8 postulaciones')))]);}
class CreateJobView extends StatelessWidget{const CreateJobView({super.key});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Crear oferta')),body:ListView(padding:const EdgeInsets.all(24),children:[_field('Título de puesto',TextEditingController()),_field('Descripción',TextEditingController(),maxLines:5),_field('Modalidad',TextEditingController()),_field('Ubicación',TextEditingController()),_field('Tipo de contrato',TextEditingController()),const SizedBox(height:20),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Publicar oferta'))]));}
class _Home extends StatelessWidget{final String title;final List<Widget>children;const _Home({required this.title,required this.children});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('INKLU')),body:ListView(padding:const EdgeInsets.all(20),children:[Text(title,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w800)),const SizedBox(height:18),...children]),bottomNavigationBar:const NavigationBar(selectedIndex:0,destinations:[NavigationDestination(icon:Icon(Icons.home_outlined),label:'Inicio'),NavigationDestination(icon:Icon(Icons.work_outline),label:'Empleos'),NavigationDestination(icon:Icon(Icons.notifications_none),label:'Avisos'),NavigationDestination(icon:Icon(Icons.person_outline),label:'Perfil')]));}

Widget _field(String label,TextEditingController c,{TextInputType? type,bool obscure=false,int maxLines=1})=>Padding(padding:const EdgeInsets.only(bottom:14),child:TextField(controller:c,keyboardType:type,obscureText:obscure,maxLines:maxLines,decoration:InputDecoration(labelText:label,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)))));
