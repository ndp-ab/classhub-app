import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

class AuthService {
  static const String baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {'success': false, 'message': 'Đăng ký thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {'success': false, 'message': 'Email hoặc mật khẩu sai'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
