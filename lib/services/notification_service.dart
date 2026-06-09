import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../models/app_notification.dart';

class NotificationService {
  static const String baseUrl = AppConfig.baseUrl;

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<AppNotification>> getNotifications({
    int page = 0,
    int size = 20,
    int? classroomId,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (classroomId != null) 'classroomId': classroomId.toString(),
    };
    final uri = Uri.parse(
      '$baseUrl/notifications',
    ).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> items = switch (decoded) {
          {'content': final List<dynamic> content} => content,
          final List<dynamic> list => list,
          _ => throw Exception('Dữ liệu thông báo không hợp lệ'),
        };

        return items
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
      }
      throw Exception(_errorMessage(response));
    } catch (e) {
      throw Exception('Không thể tải thông báo: ${_cleanException(e)}');
    }
  }

  Future<int> getUnreadCount({int? classroomId}) async {
    final uri = Uri.parse('$baseUrl/notifications/unread-count').replace(
      queryParameters: classroomId == null
          ? null
          : <String, String>{'classroomId': classroomId.toString()},
    );

    try {
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final count = _parseCount(decoded);
        if (count != null) return count;
        throw Exception('Dữ liệu số thông báo chưa đọc không hợp lệ');
      }
      throw Exception(_errorMessage(response));
    } catch (e) {
      throw Exception(
        'Không thể tải số thông báo chưa đọc: ${_cleanException(e)}',
      );
    }
  }

  Future<void> markAsRead(int recipientId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$recipientId/read'),
        headers: await _headers(),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_errorMessage(response));
      }
    } catch (e) {
      throw Exception(
        'Không thể đánh dấu thông báo đã đọc: ${_cleanException(e)}',
      );
    }
  }

  Future<void> markAllAsRead({int? classroomId}) async {
    final uri = Uri.parse('$baseUrl/notifications/read-all').replace(
      queryParameters: classroomId == null
          ? null
          : <String, String>{'classroomId': classroomId.toString()},
    );

    try {
      final response = await http.put(uri, headers: await _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_errorMessage(response));
      }
    } catch (e) {
      throw Exception(
        'Không thể đánh dấu tất cả đã đọc: ${_cleanException(e)}',
      );
    }
  }

  int? _parseCount(dynamic decoded) {
    if (decoded is num) return decoded.toInt();
    if (decoded is String) return int.tryParse(decoded);
    if (decoded is Map<String, dynamic>) {
      return _parseCount(decoded['unreadCount'] ?? decoded['count']);
    }
    return null;
  }

  String _errorMessage(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'Bạn không có quyền thực hiện thao tác này (${response.statusCode})';
    }
    try {
      final body = json.decode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}
    return 'Lỗi máy chủ (${response.statusCode})';
  }

  String _cleanException(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }
}
