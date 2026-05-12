import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

/// Auth state management — OTP-based authentication
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String get userName => _user?['name'] ?? 'User';
  String get userEmail => _user?['email'] ?? '';
  String get userRole => _user?['role'] ?? 'ENTREPRENEUR';

  /// Check if user is already logged in on app start
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _api.hasValidToken();
      if (hasToken) {
        // Load cached user data
        final userData = await _storage.read(key: 'user_data');
        if (userData != null) {
          _user = jsonDecode(userData);
          _isLoggedIn = true;
        }

        // Verify token is still valid
        try {
          final profile = await _api.getProfile();
          _user = profile;
          _isLoggedIn = true;
          await _storage.write(key: 'user_data', value: jsonEncode(profile));
        } catch (_) {
          _isLoggedIn = false;
          _user = null;
          await _api.clearTokens();
        }
      }
    } catch (_) {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Step 1: Send OTP to email
  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.sendOtp(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Step 2: Verify OTP
  /// Returns 'SUCCESS' | 'NEW_USER' | 'ERROR'
  Future<String> verifyOtp({
    required String email,
    required String code,
    String? name,
    String? role,
    String? phone,
    String? linkedIn,
    String? education,
    String? networth,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.verifyOtp(
        email: email,
        code: code,
        name: name,
        role: role,
        phone: phone,
        linkedIn: linkedIn,
        education: education,
        networth: networth,
      );

      final isNewUser = result['isNewUser'] == true;

      // If new user and no name provided, ask for name
      if (isNewUser && (name == null || name.isEmpty)) {
        _isLoading = false;
        notifyListeners();
        return 'NEW_USER';
      }

      // Save tokens
      await _api.saveTokens(result['accessToken'], result['refreshToken']);
      _user = result['user'];
      _isLoggedIn = true;
      await _storage.write(key: 'user_data', value: jsonEncode(_user));

      _isLoading = false;
      notifyListeners();
      return 'SUCCESS';
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return 'ERROR';
    }
  }

  /// Google Sign-In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _error = 'Google sign-in was cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _error = 'Failed to get Google ID token';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Send to backend
      final result = await _api.googleSignIn(idToken: idToken);

      await _api.saveTokens(result['accessToken'], result['refreshToken']);
      _user = result['user'];
      _isLoggedIn = true;
      await _storage.write(key: 'user_data', value: jsonEncode(_user));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }



  /// Logout
  Future<void> logout() async {
    await _api.clearTokens();
    _user = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Update user name locally and persist
  void updateName(String newName) {
    if (_user != null) {
      _user!['name'] = newName;
      _storage.write(key: 'user_data', value: jsonEncode(_user));
      notifyListeners();
    }
  }

  /// Update full user data (e.g. after role selection)
  void updateUserData(Map<String, dynamic> data) {
    _user = {...?_user, ...data};
    _storage.write(key: 'user_data', value: jsonEncode(_user));
    notifyListeners();
  }

  /// Check if user needs role selection
  bool get isNewUser => _user?['role'] == null || _user?['name'] == null || (_user?['name'] as String?)?.isEmpty == true;

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      if (e.response!.data is Map && e.response!.data['error'] != null) {
        return e.response!.data['error'].toString();
      }
    }
    if (e is Exception) {
      final msg = e.toString();
      // Fallback for string parsing
      if (msg.contains('error')) {
        final match = RegExp(r'"error":"([^"]+)"').firstMatch(msg);
        if (match != null) return match.group(1)!;
      }
      return msg.replaceAll('Exception: ', '');
    }
    return 'Something went wrong. Please try again.';
  }
}
