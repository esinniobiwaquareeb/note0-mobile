import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import './auth_service.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService(ref.read(authServiceProvider)));

class SubscriptionService {
  final AuthService _authService;
  SubscriptionService(this._authService);

  String get _baseUrl => dotenv.get('API_BASE_URL');

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final headers = await _authService.getAuthHeaders(json: true);
    if (!headers.containsKey('Authorization')) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/history'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('SubscriptionService: fetchHistory failed: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchCurrentStatus() async {
    final headers = await _authService.getAuthHeaders(json: true);
    if (!headers.containsKey('Authorization')) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/status'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('SubscriptionService: fetchCurrentStatus failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> verifyPayment(String reference) async {
    final headers = await _authService.getAuthHeaders(json: true);
    if (!headers.containsKey('Authorization')) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions/verify'),
        headers: headers,
        body: jsonEncode({
          'reference': reference,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('SubscriptionService: verifyPayment failed: $e');
    }
    return null;
  }

  Future<bool> cancelSubscription() async {
    final headers = await _authService.getAuthHeaders(json: true);
    if (!headers.containsKey('Authorization')) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions/cancel'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('SubscriptionService: cancelSubscription failed: $e');
    }
    return false;
  }
}
