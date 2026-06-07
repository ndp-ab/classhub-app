import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../models/event.dart';

/// Service cho phân hệ Sự kiện (Event).
///
/// Sau B1 backend xác thực bằng `Authorization: Bearer <token>` (JwtAuthenticationFilter).
class EventService {
  static const String baseUrl = AppConfig.baseUrl;

  Future<Map<String, String>> _headers({bool json = false}) async {
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
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}
    return 'Lỗi máy chủ (${r.statusCode})';
  }

  dynamic _decodeJsonOrNull(String body) {
    if (body.trim().isEmpty) return null;
    return json.decode(body);
  }

  String resolveFileUrl(String? imageUrl) {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final apiBase = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (value.startsWith('/uploads')) return '$apiBase$value';
    if (value.startsWith('/')) return '$apiBase$value';
    return '$apiBase/$value';
  }

  Future<Map<String, dynamic>> getEvents(int classroomId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/events/$classroomId'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        final List data = json.decode(r.body);
        return {
          'success': true,
          'data': data.map((e) => ClassEvent.fromJson(e)).toList(),
        };
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
        if (description != null && description.isNotEmpty)
          'description': description,
        if (location != null && location.isNotEmpty) 'location': location,
      };
      final r = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: await _headers(json: true),
        body: json.encode(body),
      );
      if (r.statusCode == 200) {
        return {
          'success': true,
          'data': ClassEvent.fromJson(json.decode(r.body)),
        };
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
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        return {
          'success': true,
          'data': EventParticipant.fromJson(json.decode(r.body)),
        };
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
        headers: await _headers(),
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
        headers: await _headers(),
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

  Future<Map<String, dynamic>> checkIn(
    int eventId,
    int targetUserId,
    int adminUserId,
  ) async {
    try {
      final r = await http.put(
        Uri.parse('$baseUrl/events/$eventId/checkin/$targetUserId'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        return {
          'success': true,
          'data': EventParticipant.fromJson(json.decode(r.body)),
        };
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> submitCheckinImage({
    required int eventId,
    required String imagePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/events/$eventId/checkin-submissions'),
      );
      request.headers.addAll(await _headers());

      final extension = p.extension(imagePath).toLowerCase();
      final mediaType = switch (extension) {
        '.png' => MediaType('image', 'png'),
        '.jpg' || '.jpeg' => MediaType('image', 'jpeg'),
        _ => MediaType('image', 'jpeg'),
      };

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imagePath,
          contentType: mediaType,
        ),
      );

      final streamed = await request.send();
      final r = await http.Response.fromStream(streamed);
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return {'success': true, 'data': _decodeJsonOrNull(r.body)};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> approveCheckinSubmission(
    int submissionId,
  ) async {
    try {
      final r = await http.put(
        Uri.parse('$baseUrl/events/checkin-submissions/$submissionId/approve'),
        headers: await _headers(),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return {'success': true, 'data': _decodeJsonOrNull(r.body)};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> rejectCheckinSubmission(
    int submissionId,
    String reason,
  ) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      return {'success': false, 'message': 'Lý do không được để trống'};
    }
    try {
      final r = await http.put(
        Uri.parse('$baseUrl/events/checkin-submissions/$submissionId/reject'),
        headers: await _headers(json: true),
        body: json.encode({'reason': trimmedReason}),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return {'success': true, 'data': _decodeJsonOrNull(r.body)};
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
        headers: await _headers(),
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
