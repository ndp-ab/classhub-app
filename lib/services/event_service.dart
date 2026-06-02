import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../models/event.dart';

/// Service cho phân hệ Sự kiện (Event).
///
/// Sau B1 backend xác thực bằng `Authorization: Bearer <token>` (JwtAuthenticationFilter).
class EventService {
  static const String baseUrl = AppConfig.baseUrl;

  Future<Map<String, String>> _headers(int userId, {bool json = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  String _errorMessage(http.Response r) {
    if (r.statusCode == 401 || r.statusCode == 403) {
      return 'Bạn không có quyền thực hiện thao tác này (${r.statusCode})';
    }
    try {
      final body = json.decode(r.body);
      if (body is Map && body['message'] != null) return body['message'].toString();
    } catch (_) {}
    return 'Lỗi máy chủ (${r.statusCode})';
  }

  Future<Map<String, dynamic>> getEvents(int classroomId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/events/$classroomId'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        final List data = json.decode(r.body);
        return {'success': true, 'data': data.map((e) => ClassEvent.fromJson(e)).toList()};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> createEvent({
    required int classroomId,
    required String title,
    String? description,
    String? location,
    required DateTime eventTime,
    required int userId,
  }) async {
    try {
      // Backend nhận LocalDateTime → ISO string không có "Z"
      final iso = eventTime.toIso8601String().split('.').first;
      final body = <String, dynamic>{
        'classroomId': classroomId,
        'title': title,
        'eventTime': iso,
        if (description != null && description.isNotEmpty) 'description': description,
        if (location != null && location.isNotEmpty) 'location': location,
      };
      final r = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: await _headers(userId, json: true),
        body: json.encode(body),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': ClassEvent.fromJson(json.decode(r.body))};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> volunteer(int eventId, int userId) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/events/$eventId/volunteer'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': EventParticipant.fromJson(json.decode(r.body))};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelVolunteer(int eventId, int userId) async {
    try {
      final r = await http.delete(
        Uri.parse('$baseUrl/events/$eventId/volunteer'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 204 || r.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getParticipants(int eventId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/events/$eventId/participants'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        final List data = json.decode(r.body);
        return {
          'success': true,
          'data': data.map((e) => EventParticipant.fromJson(e)).toList(),
        };
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> checkIn(int eventId, int targetUserId, int adminUserId) async {
    try {
      final r = await http.put(
        Uri.parse('$baseUrl/events/$eventId/checkin/$targetUserId'),
        headers: await _headers(adminUserId),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': EventParticipant.fromJson(json.decode(r.body))};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyEvents(int classroomId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/events/my/$classroomId'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        final List data = json.decode(r.body);
        return {
          'success': true,
          'data': data.map((e) => EventParticipant.fromJson(e)).toList(),
        };
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
