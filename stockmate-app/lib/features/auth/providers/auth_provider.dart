import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    final userData = await _storage.read(key: 'user_data');
    if (token != null && userData != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userData));
        state = AuthState(user: user);
      } catch (_) {}
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      final data = await ApiService.instance.login(email, password);
      final user = UserModel.fromJson(data['user']);
      await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
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

  Future<void> logout() async {
    await ApiService.instance.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
