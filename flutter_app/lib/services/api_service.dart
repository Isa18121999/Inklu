import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://inklu-api.onrender.com/api';

  Future<Map<String, dynamic>> registerCandidate({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String conadisNumber,
  }) async {
    return _post('/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': 'candidate',
      'country': 'PE',
      'accreditationType': 'Carné CONADIS',
      'accreditationNumber': conadisNumber,
    });
  }

  Future<Map<String, dynamic>> registerCompany({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String ruc,
  }) async {
    return _post('/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': 'company',
      'country': 'PE',
      'ruc': ruc,
    });
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _post('/auth/login', {'email': email, 'password': password});
  }

  Future<List<dynamic>> jobs(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/company/jobs'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> profile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decodeMap(response);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'No se pudo completar la solicitud.');
    }
    return Map<String, dynamic>.from(data);
  }

  List<dynamic> _decodeList(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'No se pudieron cargar los datos.');
    }
    if (data is List) return data;
    if (data is Map && data['jobs'] is List) return data['jobs'];
    return const [];
  }
}
