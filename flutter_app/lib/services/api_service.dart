import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://inklu-api.onrender.com/api';
  Map<String, String> _headers(String token) => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

  Future<Map<String, dynamic>> registerCandidate({required String name, required String email, required String phone, required String password, required String conadisNumber, String? cvPath}) async {
    final data = await _post('/auth/register', {'name': name, 'email': email, 'phone': phone, 'password': password, 'role': 'candidate', 'country': 'PE', 'accreditationType': 'Carné CONADIS', 'accreditationNumber': conadisNumber});
    if (cvPath != null && cvPath.isNotEmpty && data['token'] != null) await uploadCv(data['token'].toString(), cvPath);
    return data;
  }
  Future<Map<String, dynamic>> registerCompany({required String name, required String email, required String phone, required String password, required String ruc}) => _post('/auth/register', {'name': name, 'email': email, 'phone': phone, 'password': password, 'role': 'company', 'country': 'PE', 'ruc': ruc});
  Future<Map<String, dynamic>> login(String email, String password) => _post('/auth/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> uploadCv(String token, String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) throw Exception('El CV supera el tamaño máximo de 5 MB.');
    final fileName = path.split(RegExp(r'[/\\]')).last;
    final ext = fileName.toLowerCase().split('.').last;
    final mime = ext == 'pdf' ? 'application/pdf' : 'application/msword';
    final body = {'fileName': fileName, 'mimeType': mime, 'data': base64Encode(bytes)};
    final r = await http.post(Uri.parse('$baseUrl/profile/cv'), headers: _headers(token), body: jsonEncode(body)).timeout(const Duration(seconds: 45));
    return _decodeMap(r);
  }
  Future<List<dynamic>> jobs(String token) async => _getList('/company/jobs', token);
  Future<List<dynamic>> myJobs(String token) async => _getList('/company/my-jobs', token);
  Future<List<dynamic>> applications(String token) async => _getList('/applications', token);
  Future<Map<String, dynamic>> profile(String token) async => _getMap('/profile/me', token);
  Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> data) async => _patch('/profile/me', token, data);
  Future<Map<String, dynamic>> createJob(String token, Map<String, dynamic> data) async => _postAuth('/company/jobs', token, data);
  Future<Map<String, dynamic>> apply(String token, String jobId) async => _postAuth('/applications', token, {'jobId': jobId});
  Future<Map<String, dynamic>> updateApplicationStatus(String token, String id, String status) async => _patch('/applications/$id/status', token, {'status': status});
  Future<Map<String, dynamic>> analyzeCv(String token) async =>
      _postAuth('/profile/cv/analyze', token, {});
  Future<List<dynamic>> recommendations(String token) async {
    final result = await _getMap('/recommendations', token);
    final items = result['recommendations'];
    return items is List ? items : const [];
  }
  Future<List<dynamic>> chatMessages(String token, String applicationId) async =>
      _getList('/applications/$applicationId/messages', token);
  Future<Map<String, dynamic>> sendChatMessage(
    String token,
    String applicationId,
    String content,
  ) async =>
      _postAuth('/applications/$applicationId/messages', token, {'content': content});


  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try { final r=await http.post(Uri.parse('$baseUrl$path'),headers:{'Content-Type':'application/json'},body:jsonEncode(body)).timeout(const Duration(seconds:25)); return _decodeMap(r); }
    on SocketException { throw Exception('No se pudo conectar con INKLU. Verifica tu conexión a Internet e inténtalo de nuevo.'); }
    on TimeoutException { throw Exception('El servidor de INKLU está tardando en responder. Inténtalo nuevamente.'); }
    on FormatException { throw Exception('El servidor de INKLU devolvió una respuesta inválida.'); }
  }
  Future<Map<String,dynamic>> _postAuth(String path,String token,Map<String,dynamic> body)async{final r=await http.post(Uri.parse('$baseUrl$path'),headers:_headers(token),body:jsonEncode(body)).timeout(const Duration(seconds:25));return _decodeMap(r);}
  Future<Map<String,dynamic>> _patch(String path,String token,Map<String,dynamic> body)async{final r=await http.patch(Uri.parse('$baseUrl$path'),headers:_headers(token),body:jsonEncode(body)).timeout(const Duration(seconds:25));return _decodeMap(r);}
  Future<Map<String,dynamic>> _getMap(String path,String token)async{final r=await http.get(Uri.parse('$baseUrl$path'),headers:_headers(token)).timeout(const Duration(seconds:25));return _decodeMap(r);}
  Future<List<dynamic>> _getList(String path,String token)async{final r=await http.get(Uri.parse('$baseUrl$path'),headers:_headers(token)).timeout(const Duration(seconds:25));return _decodeList(r);}
  Map<String,dynamic> _decodeMap(http.Response r){final data=jsonDecode(r.body);if(r.statusCode<200||r.statusCode>=300)throw Exception(data['message']??'No se pudo completar la solicitud.');return Map<String,dynamic>.from(data);}
  List<dynamic> _decodeList(http.Response r){final data=jsonDecode(r.body);if(r.statusCode<200||r.statusCode>=300)throw Exception(data['message']??'No se pudieron cargar los datos.');if(data is List)return data;if(data is Map&&data['jobs'] is List)return data['jobs'];if(data is Map&&data['applications'] is List)return data['applications'];return const[];}
}
