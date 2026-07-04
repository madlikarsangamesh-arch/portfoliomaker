import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portfolio_ai/config/constants.dart';

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? userId;
  final String? email;
  final String? fullName;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.userId,
    this.email,
    this.fullName,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    String? userId,
    String? email,
    String? fullName,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userId = prefs.getString(AppConstants.userIdKey);
    final email = prefs.getString(AppConstants.userEmailKey);
    final name = prefs.getString(AppConstants.userFullNameKey);

    if (token != null && userId != null) {
      state = AuthState(
        isAuthenticated: true,
        token: token,
        userId: userId,
        email: email,
        fullName: name,
      );
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseApiUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAuthData(data);
        return true;
      } else {
        final errorMsg = json.decode(response.body)['detail'] ?? 'Registration failed';
        state = state.copyWith(isLoading: false, error: errorMsg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network connection failed');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseApiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAuthData(data);
        return true;
      } else {
        final errorMsg = json.decode(response.body)['detail'] ?? 'Login failed';
        state = state.copyWith(isLoading: false, error: errorMsg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network connection failed');
      return false;
    }
  }

  Future<bool> loginWithGoogle(String email, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseApiUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAuthData(data);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Google sign in failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network connection failed');
      return false;
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, data['token']);
    await prefs.setString(AppConstants.userIdKey, data['id']);
    await prefs.setString(AppConstants.userEmailKey, data['email']);
    await prefs.setString(AppConstants.userFullNameKey, data['full_name']);

    state = AuthState(
      isAuthenticated: true,
      token: data['token'],
      userId: data['id'],
      email: data['email'],
      fullName: data['full_name'],
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userFullNameKey);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
