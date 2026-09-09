import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../../../shared/services/api_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage? _storage = kIsWeb ? null : const FlutterSecureStorage();
  SharedPreferences? _prefs;

  AuthNotifier() : super(const AuthState()) {
    _tryAutoLogin();
  }

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

  Future<void> _tryAutoLogin() async {
    try {
      final token = await _read('auth_token');
      final userData = await _read('user_data');
      if (token != null && userData != null) {
        final user = UserModel.fromJson(jsonDecode(userData));
        state = AuthState(user: user);
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      final data = await ApiService.instance.login(email, password);
      final user = UserModel.fromJson(data['user']);
      await _write('user_data', jsonEncode(user.toJson()));
      state = AuthState(user: user);
      return true;
    } catch (e) {
      String msg = 'Bağlantı hatası / Connection error';
      if (e.toString().contains('401')) msg = 'Hatalı e-posta veya şifre / Invalid credentials';
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        msg = 'Sunucuya bağlanılamadı / Cannot reach server';
      }
      state = AuthState(error: msg);
      return false;
    }
  }

  Future<void> updateName(String name) async {
    if (state.user == null) return;
    final updated = UserModel(
      id: state.user!.id,
      name: name,
      email: state.user!.email,
      role: state.user!.role,
    );
    await _write('user_data', jsonEncode(updated.toJson()));
    state = state.copyWith(user: updated);
  }

  Future<void> logout() async {
    await ApiService.instance.logout();
    await _delete('auth_token');
    await _delete('user_data');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
