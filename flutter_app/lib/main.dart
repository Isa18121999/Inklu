import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/accessibility_page.dart';
import 'create_offer_page.dart';
import 'notifications_page.dart';
import 'delete_account_page.dart';

const primary=Color(0xFF4F46E5), ink=Color(0xFF111827), muted=Color(0xFF64748B), line=Color(0xFFE2E8F0);

// Legacy labels: show a readable name instead of exposing numeric catalog IDs.
const List<String> _legacySkillLabels = [
  'Excel', 'Microsoft Office', 'Atención al cliente', 'Ventas',
  'Marketing digital', 'Comunicación', 'Administración', 'Contabilidad',
  'Finanzas', 'Programación', 'Python', 'JavaScript', 'SQL y bases de datos',
  'Desarrollo web', 'Flutter', 'Diseño UX/UI', 'Diseño gráfico',
  'Análisis de datos', 'Soporte técnico', 'Redes y sistemas', 'Recursos humanos',
  'Gestión de proyectos', 'Logística', 'Educación', 'Salud', 'Inglés',
];
const List<String> _legacyJobCategories = [
  'Tecnología', 'Administración', 'Diseño', 'Atención al cliente',
  'Educación', 'Salud', 'Finanzas', 'Logística', 'Marketing', 'Otro',
];
const List<String> _legacyModalities = ['Remoto', 'Híbrido', 'Presencial'];
const List<String> _legacyContracts = [
  'Tiempo completo', 'Medio tiempo', 'Temporal', 'Prácticas', 'Freelance', 'Por horas',
];

String _readableLabel(dynamic raw, List<String> legacyOptions, {String fallback = ''}) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) return fallback;
  if (!RegExp(r'^\d+$').hasMatch(value)) return value;
  final index = int.tryParse(value);
  if (index == null || index < 0 || index >= legacyOptions.length) return fallback;
  return legacyOptions[index];
}

dynamic _firstNonEmptyLabelValue(List<dynamic> values) {
  for (final value in values) {
    if (value != null && value.toString().trim().isNotEmpty) return value;
  }
  return null;
}

String _skillLabel(dynamic raw) => _readableLabel(raw, _legacySkillLabels);
final api=ApiService(); String? sessionToken; Map<String,dynamic>? sessionUser;
void main() async{WidgetsFlutterBinding.ensureInitialized();await SystemChrome.setPreferredOrientations(const[DeviceOrientation.portraitUp,DeviceOrientation.portraitDown]);runApp(const InkluApp());}
void toast(String s) {
  // SemanticsService.announce was removed/deprecated in the Flutter SDK used
  // for the release build. The SnackBar remains the visible/user-facing
  // feedback and avoids a compile-time dependency on the removed API.
  final context = _nav.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
    );
  }
}
final GlobalKey<NavigatorState> _nav=GlobalKey<NavigatorState>();
class InkluApp extends StatelessWidget{const InkluApp({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,navigatorKey:_nav,title:'INKLU',theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:Colors.white,colorScheme:ColorScheme.fromSeed(seedColor:primary)),home:const AppStart());}
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