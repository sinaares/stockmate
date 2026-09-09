import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  // Never instantiate FlutterSecureStorage on web — it crashes the app
  final FlutterSecureStorage? _storage = kIsWeb ? null : const FlutterSecureStorage();
  SharedPreferences? _prefs;
  late Dio _dio;
  String _baseUrl = 'http://localhost:3000';

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(key, value);
    } else {
      await _storage!.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs!.getString(key);
    } else {
      return _storage!.read(key: key);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove(key);
    } else {
      await _storage!.delete(key: key);
    }
  }

  Future<void> init() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
    final savedUrl = await _read('server_url');
    if (savedUrl != null) _baseUrl = savedUrl;
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _read('auth_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    await _write('server_url', url);
    _initDio();
  }

  String get baseUrl => _baseUrl;

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    await _write('auth_token', res.data['token']);
    return res.data;
  }

  Future<void> logout() async {
    await _delete('auth_token');
    await _delete('user_data');
  }

  Future<String?> getToken() => _read('auth_token');

  // Products
  Future<List<dynamic>> getProducts({String? search, int? categoryId, bool lowStock = false}) async {
    final res = await _dio.get('/products', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
      if (lowStock) 'low_stock': '1',
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getProductByCode(String code) async {
    final res = await _dio.get('/products/lookup/$code');
    return res.data;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/products/$id', data: data);
    return res.data;
  }

  Future<void> deleteProduct(int id) async {
    await _dio.delete('/products/$id');
  }

  // Requests / Approvals
  Future<List<dynamic>> getRequests({String? status}) async {
    final res = await _dio.get('/requests', queryParameters: {if (status != null) 'status': status});
    return res.data;
  }

  Future<int> getPendingCount() async {
    final res = await _dio.get('/requests/count/pending');
    return res.data['count'];
  }

  Future<Map<String, dynamic>> submitRequest(Map<String, dynamic> data) async {
    final res = await _dio.post('/requests', data: data);
    return res.data;
  }

  Future<void> approveRequest(int id) async {
    await _dio.put('/requests/$id/approve');
  }

  Future<void> rejectRequest(int id, String reason) async {
    await _dio.put('/requests/$id/reject', data: {'reason': reason});
  }

  // Transactions
  Future<List<dynamic>> getTransactions({int? productId, String? actionType}) async {
    final res = await _dio.get('/transactions', queryParameters: {
      if (productId != null) 'product_id': productId,
      if (actionType != null) 'action_type': actionType,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/transactions/stats');
    return res.data;
  }

  // Employees
  Future<List<dynamic>> getEmployees() async {
    final res = await _dio.get('/employees');
    return res.data;
  }

  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    final res = await _dio.post('/employees', data: data);
    return res.data;
  }

  Future<void> toggleEmployee(int id) async {
    await _dio.put('/employees/$id/toggle');
  }

  // Categories
  Future<List<dynamic>> getCategories() async {
    final res = await _dio.get('/categories');
    return res.data;
  }

  // Profile & Password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.put('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> updateProfile(String name) async {
    final res = await _dio.put('/auth/profile', data: {'name': name});
    return res.data;
  }
}
