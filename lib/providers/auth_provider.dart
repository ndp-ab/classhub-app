import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _token;
  int? _userId;
  String? _fullName;
  String? _email;
  bool _isLoading = false;

  String? get token => _token;
  int? get userId => _userId;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get fullName => _fullName;
  String? get email => _email;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _userId = prefs.getInt('user_id');
    _fullName = prefs.getString('full_name');
    _email = prefs.getString('email');
    notifyListeners();
  }

  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.register(fullName, email, password);

    if (result['success']) {
      await _saveAuth(result['data']);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success']) {
      await _saveAuth(result['data']);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> _saveAuth(Map<String, dynamic> data) async {
    _token = data['token'];
    _userId = data['userId'];
    _fullName = data['fullName'];
    _email = data['email'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', _token!);
    await prefs.setInt('user_id', _userId!);
    await prefs.setString('full_name', _fullName!);
    await prefs.setString('email', _email!);
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _fullName = null;
    _email = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}