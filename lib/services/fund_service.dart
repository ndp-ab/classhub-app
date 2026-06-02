import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../models/expense.dart';
import '../models/fund_collection.dart';
import '../models/payment.dart';

/// Service cho phân hệ Quỹ lớp (Fund).
///
/// Sau B1 backend xác thực qua `Authorization: Bearer <token>` (JwtAuthenticationFilter).
/// Tham số `userId` giữ trong signature để tương thích UI cũ — BE lấy userId
/// từ token, không dùng `X-User-Id` nữa.
class FundService {
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

  // ----- Collections -----

  Future<Map<String, dynamic>> getCollections(int classroomId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/fund/collections/$classroomId'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        final List data = json.decode(r.body);
        return {
          'success': true,
          'data': data.map((e) => FundCollection.fromJson(e)).toList(),
        };
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> createCollection({
    required int classroomId,
    required String title,
    required double amount,
    DateTime? deadline,
    required int userId,
  }) async {
    try {
      final body = <String, dynamic>{
        'classroomId': classroomId,
        'title': title,
        'amount': amount,
      };
      if (deadline != null) {
        body['deadline'] =
            '${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
      }
      final r = await http.post(
        Uri.parse('$baseUrl/fund/collections'),
        headers: await _headers(userId, json: true),
        body: json.encode(body),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': FundCollection.fromJson(json.decode(r.body))};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ----- Payments -----

  Future<Map<String, dynamic>> getCollectionPayments(int collectionId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/fund/collections/$collectionId/payments'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        final List data = json.decode(r.body);
        return {'success': true, 'data': data.map((e) => Payment.fromJson(e)).toList()};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> confirmPayment(int paymentId, int userId) async {
    try {
      final r = await http.put(
        Uri.parse('$baseUrl/fund/payments/$paymentId/confirm'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': Payment.fromJson(json.decode(r.body))};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // GP1: Member tự báo đã chuyển khoản → status PENDING_VERIFICATION
  Future<Map<String, dynamic>> markPaymentAsPaid(int paymentId, int userId) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/fund/payments/$paymentId/mark-paid'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': Payment.fromJson(json.decode(r.body))};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyPayments(int classroomId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/fund/payments/my/$classroomId'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        final List data = json.decode(r.body);
        return {'success': true, 'data': data.map((e) => Payment.fromJson(e)).toList()};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getPaymentQr(int paymentId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/fund/payments/$paymentId/qr'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': json.decode(r.body) as Map<String, dynamic>};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(int paymentId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/fund/payments/$paymentId/status'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': json.decode(r.body) as Map<String, dynamic>};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ----- Expenses -----

  Future<Map<String, dynamic>> getExpenses(int classroomId, int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/fund/expenses/$classroomId'),
        headers: await _headers(userId),
      );
      if (r.statusCode == 200) {
        final List data = json.decode(r.body);
        return {'success': true, 'data': data.map((e) => Expense.fromJson(e)).toList()};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> createExpense({
    required int classroomId,
    required String title,
    required double amount,
    String? reason,
    required int userId,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/fund/expenses'),
        headers: await _headers(userId, json: true),
        body: json.encode({
          'classroomId': classroomId,
          'title': title,
          'amount': amount,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );
      if (r.statusCode == 200) {
        return {'success': true, 'data': Expense.fromJson(json.decode(r.body))};
      }
      return {'success': false, 'message': _errorMessage(r)};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
