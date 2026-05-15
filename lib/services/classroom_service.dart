import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassroomService {
  //static const String baseUrl = 'http://192.168.1.5:8080/api';
  static const String baseUrl = 'http://localhost:8080/api';
  Future<Map<String, dynamic>> createClassroom(String className, String faculty, String academicYear, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classrooms/create'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
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
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
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
        headers: {
          'X-User-Id': userId.toString(),
        },
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
}