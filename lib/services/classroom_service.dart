import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../models/class_member.dart';

/// Service cho phân hệ Lớp học.
/// Sau B1 (JWT filter), backend đã yêu cầu `Authorization: Bearer <token>`
/// thay vì `X-User-Id`. Tham số userId vẫn giữ trong signature để tránh đổi UI,
/// nhưng KHÔNG còn được gửi qua header.
class ClassroomService {
  static const String baseUrl = AppConfig.baseUrl;

  Future<Map<String, String>> _headers({bool json = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  String _errorMessage(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'Bạn không có quyền xem danh sách thành viên (${response.statusCode})';
    }
    try {
      final body = json.decode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}
    return 'Lỗi máy chủ (${response.statusCode})';
  }

  Future<Map<String, dynamic>> createClassroom(String className, String faculty,
      String academicYear, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classrooms/create'),
        headers: await _headers(json: true),
        body: json.encode({
          'className': className,
          'faculty': faculty,
          'academicYear': academicYear,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {'success': false, 'message': 'Tạo lớp thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> joinClassroom(String inviteCode, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classrooms/join'),
        headers: await _headers(json: true),
        body: json.encode({
          'inviteCode': inviteCode,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {'success': false, 'message': 'Mã tham gia không hợp lệ'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyClassrooms(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/classrooms/my'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Không tải được danh sách lớp'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getClassMembers(int classroomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/classrooms/$classroomId/members'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data.map((e) => ClassMember.fromJson(e)).toList(),
        };
      }
      return {'success': false, 'message': _errorMessage(response)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
